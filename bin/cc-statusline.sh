#!/usr/bin/env bash
# Claude Code statusline — spec: https://github.com/parisgroup-ai/infra/blob/main/docs/superpowers/specs/2026-04-17-claude-code-statusline-package-design.md
# NOTE: we intentionally do NOT 'set -u' because bash 3.2 exits 127 on
# unbound vars BEFORE the ERR trap runs (verified on macOS bash 3.2.57).
# Instead, every expansion of an optional var must use ${VAR:-} defensively.
trap 'exit 0' ERR INT TERM

# -------- debug timing (opt-in via CC_STATUSLINE_DEBUG=1) --------
if [ -n "${CC_STATUSLINE_DEBUG:-}" ]; then
  DBG_START=$(date +%s 2>/dev/null || echo 0)
  dbg() {
    local now
    now=$(date +%s 2>/dev/null || echo 0)
    local delta=$(( now - DBG_START ))
    printf '[%ss] %s\n' "$delta" "$1" >> /tmp/cc-statusline.err
  }
else
  dbg() { :; }
fi
dbg "start"

# -------- color helpers (respect NO_COLOR + TERM=dumb) --------
if [ "${NO_COLOR+x}" = "x" ] || [ "${TERM:-}" = "dumb" ]; then
  C_RESET=""; C_DIM=""; C_CYAN=""; C_MAGENTA=""; C_YELLOW=""; C_GREEN=""; C_GREY=""; C_REDBOLD=""
else
  C_RESET=$'\x1b[0m'
  C_DIM=$'\x1b[2m'
  C_CYAN=$'\x1b[36m'
  C_MAGENTA=$'\x1b[35m'
  C_YELLOW=$'\x1b[33m'
  C_GREEN=$'\x1b[32m'
  C_GREY=$'\x1b[90m'
  C_REDBOLD=$'\x1b[1;31m'
fi

# -------- icons (Nerd Font by default; ASCII fallback via CC_STATUSLINE_NO_ICONS=1) --------
if [ -n "${CC_STATUSLINE_NO_ICONS:-}" ]; then
  ICON_MODEL="M"
  ICON_PROJECT="P"
  ICON_GIT="git"
  ARROW_UP="^"
  ARROW_DOWN="v"
else
  # U+F544 nf-fa-robot        UTF-8: EF 95 84
  ICON_MODEL=$(printf '\xef\x95\x84')
  # U+F07C nf-fa-folder_open  UTF-8: EF 81 BC
  ICON_PROJECT=$(printf '\xef\x81\xbc')
  # U+E0A0 nf-dev-git_branch  UTF-8: EE 82 A0
  ICON_GIT=$(printf '\xee\x82\xa0')
  # U+2191 up arrow           UTF-8: E2 86 91
  ARROW_UP=$(printf '\xe2\x86\x91')
  # U+2193 down arrow         UTF-8: E2 86 93
  ARROW_DOWN=$(printf '\xe2\x86\x93')
fi

# -------- dep check --------
if ! command -v jq >/dev/null 2>&1; then
  printf '[install jq]\n'
  exit 0
fi

# -------- stdin parsing --------
stdin_json="$(cat 2>/dev/null || true)"

model_display=""
cwd=""
project_dir=""
session_id=""
transcript_path=""
cost_usd="0"

if [ -n "${stdin_json:-}" ]; then
  model_display="$(printf '%s' "$stdin_json" | jq -r '.model.display_name // ""' 2>/dev/null || true)"
  cwd="$(printf '%s' "$stdin_json" | jq -r '.workspace.current_dir // ""' 2>/dev/null || true)"
  project_dir="$(printf '%s' "$stdin_json" | jq -r '.workspace.project_dir // ""' 2>/dev/null || true)"
  session_id="$(printf '%s' "$stdin_json" | jq -r '.session_id // ""' 2>/dev/null || true)"
  transcript_path="$(printf '%s' "$stdin_json" | jq -r '.transcript_path // ""' 2>/dev/null || true)"
  cost_usd="$(printf '%s' "$stdin_json" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null || echo 0)"
fi
dbg "parsed stdin"

# -------- model label --------
if [ -z "${model_display:-}" ]; then
  model_label="Claude Code"
else
  case "$model_display" in
    *"1M context"*|*"1M)"*) model_label="$(printf '%s' "$model_display" | sed -E 's/ *\(1M[^)]*\) */ 1M/')" ;;
    *)                      model_label="$model_display" ;;
  esac
fi

seg_model="${C_CYAN}${ICON_MODEL}${C_RESET} ${model_label}"

# -------- project segment --------
project_base=""
if [ -n "${project_dir:-}" ]; then
  project_base="$(basename "$project_dir")"
elif [ -n "${cwd:-}" ]; then
  project_base="$(basename "$cwd")"
fi

if [ -n "${project_base:-}" ]; then
  seg_project="${C_MAGENTA}${ICON_PROJECT}${C_RESET} ${project_base}"
else
  seg_project=""
fi

# -------- git segment (with 3s TTL cache B) --------
seg_git=""
if [ -n "${cwd:-}" ] && { [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; }; then
  cwd_hash="$(printf '%s' "$cwd" | { md5sum 2>/dev/null || md5 2>/dev/null; } | cut -c1-8)"
  git_cache="/tmp/cc-git-${cwd_hash}.cache"
  g_branch=""
  g_dirty=""

  # Cache hit: file younger than 3s
  if [ -f "$git_cache" ]; then
    cache_mtime=$(stat -c %Y "$git_cache" 2>/dev/null || stat -f %m "$git_cache" 2>/dev/null || echo 0)
    now=$(date +%s)
    if [ $((now - cache_mtime)) -lt 3 ]; then
      # Use `cut -f` instead of `IFS=$'\t' read` because bash 3.2 collapses
      # consecutive non-whitespace IFS delimiters, so a clean tree (empty
      # g_dirty) line 'main\t\t<ts>\n' reads as branch=main, dirty=<ts>,
      # rendering 'main<ts>' instead of just 'main' (CHORE-008).
      g_branch="$(cut -f1 < "$git_cache" 2>/dev/null || true)"
      g_dirty="$(cut -f2 < "$git_cache" 2>/dev/null || true)"
    fi
  fi

  # Cache miss: recompute
  if [ -z "${g_branch:-}" ]; then
    g_branch="$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || echo '(detached)')"
    if [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null | head -1)" ]; then
      g_dirty="*"
    else
      g_dirty=""
    fi
    # shellcheck disable=SC2015  # Best-effort cache write; any failure is intentionally swallowed.
    printf '%s\t%s\t%s\n' "$g_branch" "$g_dirty" "$(date +%s)" > "${git_cache}.tmp" 2>/dev/null && mv "${git_cache}.tmp" "$git_cache" 2>/dev/null || true
  fi

  dirty_render=""
  [ -n "${g_dirty:-}" ] && dirty_render="${C_REDBOLD}${g_dirty}${C_RESET}"
  seg_git="${C_YELLOW}${ICON_GIT}${C_RESET} ${g_branch}${dirty_render}"
fi
dbg "git segment done"

# -------- transcript usage + cost (cache A) --------
# Single jq pass over transcript JSONL produces THREE distinct datasets,
# each scoped to what its consumer needs:
#   1. Cumulative cost across ALL assistant turns × per-model price table →
#      drives the $cost segment. Replaces buggy stdin .cost.total_cost_usd
#      which is account-scope (carries over /clear).
#   2. Cumulative "new content sent / generated" across ALL turns →
#      drives the ↑/↓ display. Sums (input_tokens + cache_creation) up,
#      output_tokens down; deliberately EXCLUDES cache_read because cache
#      reads are conceptually re-loads of the same prefix and would inflate
#      the displayed number ~10× without representing new work or new spend.
#   3. Last-turn snapshot of (input + cache_read + cache_creation) →
#      drives the ctx% segment. THAT metric IS supposed to reflect total
#      tokens currently loaded into context, so the inflation is actually
#      what the display needs there.
# Cache file shape (mtime-keyed):
#   {mtime, sum_up, sum_down, last_total_input, cost}
# Older caches (pre-sum_up, pre-cost) silently force a recompute via the
# field-presence gate at cache_hit assignment.
disp_up=""; disp_down=""; tok_total_input=0; tok_cost=""
if [ -n "${session_id:-}" ] && [ -n "${transcript_path:-}" ] && [ -f "$transcript_path" ]; then
  trans_cache="/tmp/cc-statusline-${session_id}.json"
  trans_mtime=$(stat -c %Y "$transcript_path" 2>/dev/null || stat -f %m "$transcript_path" 2>/dev/null || echo 0)

  cache_hit=0
  if [ -f "$trans_cache" ] && jq -e . "$trans_cache" >/dev/null 2>&1; then
    cached_mtime=$(jq -r '.mtime // 0' "$trans_cache" 2>/dev/null || echo 0)
    if [ "$cached_mtime" = "$trans_mtime" ]; then
      disp_up=$(jq -r '.sum_up // ""' "$trans_cache" 2>/dev/null || echo "")
      disp_down=$(jq -r '.sum_down // ""' "$trans_cache" 2>/dev/null || echo "")
      tok_total_input=$(jq -r '.last_total_input // 0' "$trans_cache" 2>/dev/null || echo 0)
      tok_cost=$(jq -r '.cost // ""' "$trans_cache" 2>/dev/null || echo "")
      # All three required fields present → cache hit. Old caches (before
      # this commit) have `input/output/cache_read/cache_creation` instead of
      # `sum_up/sum_down/last_total_input` → disp_up empty → recompute.
      [ -n "${disp_up:-}" ] && [ -n "${disp_down:-}" ] && [ -n "${tok_cost:-}" ] && cache_hit=1
    fi
  fi

  if [ $cache_hit -eq 0 ]; then
    # Single streaming pass via `inputs` (no slurp → bounded memory on long
    # transcripts). Returns TSV: cost \t sum_up \t sum_down \t last_total_input.
    # Per-turn cost picks model from `.message.model` (transcripts can mix
    # models within one session). Default pricing = Opus when unknown —
    # fail-safe so a brand-new model id doesn't render $0.00 silently.
    computed=$(jq -nr '
      def pi($m): if $m|test("opus";"i") then 15 elif $m|test("sonnet";"i") then 3 elif $m|test("haiku";"i") then 1 else 15 end;
      def po($m): if $m|test("opus";"i") then 75 elif $m|test("sonnet";"i") then 15 elif $m|test("haiku";"i") then 5 else 75 end;
      def pcr($m): if $m|test("opus";"i") then 1.5 elif $m|test("sonnet";"i") then 0.3 elif $m|test("haiku";"i") then 0.1 else 1.5 end;
      def pcw5($m): if $m|test("opus";"i") then 18.75 elif $m|test("sonnet";"i") then 3.75 elif $m|test("haiku";"i") then 1.25 else 18.75 end;
      def pcw1($m): if $m|test("opus";"i") then 30 elif $m|test("sonnet";"i") then 6 elif $m|test("haiku";"i") then 2 else 30 end;
      reduce (inputs | select(.type=="assistant") | .message) as $a (
        {c:0, su:0, sd:0, lti:0};
        ($a.model // "unknown") as $m
        | ($a.usage // {}) as $u
        | ($u.cache_creation // null) as $cc
        | (if ($cc|type) == "object" then
             (($cc.ephemeral_5m_input_tokens // 0) * pcw5($m))
             + (($cc.ephemeral_1h_input_tokens // 0) * pcw1($m))
           else
             ($u.cache_creation_input_tokens // 0) * pcw5($m)
           end) as $cw_cost
        | (if ($cc|type) == "object" then
             (($cc.ephemeral_5m_input_tokens // 0)
              + ($cc.ephemeral_1h_input_tokens // 0))
           else ($u.cache_creation_input_tokens // 0) end) as $cw_tokens
        | .c = .c + (
            (($u.input_tokens // 0) * pi($m))
            + (($u.output_tokens // 0) * po($m))
            + (($u.cache_read_input_tokens // 0) * pcr($m))
            + $cw_cost
          ) / 1000000
        | .su = .su + (($u.input_tokens // 0) + $cw_tokens)
        | .sd = .sd + ($u.output_tokens // 0)
        | .lti = (($u.input_tokens // 0)
                  + ($u.cache_read_input_tokens // 0)
                  + $cw_tokens)
      )
      | "\(.c)\t\(.su)\t\(.sd)\t\(.lti)"
    ' "$transcript_path" 2>/dev/null || true)
    if [ -n "${computed:-}" ]; then
      # bash-3.2 IFS-safe field split: cut per field (matches the pattern
      # used in the git cache block above for the same reason).
      tok_cost=$(printf '%s' "$computed" | cut -f1 2>/dev/null || echo "")
      disp_up=$(printf '%s' "$computed" | cut -f2 2>/dev/null || echo 0)
      disp_down=$(printf '%s' "$computed" | cut -f3 2>/dev/null || echo 0)
      tok_total_input=$(printf '%s' "$computed" | cut -f4 2>/dev/null || echo 0)
      # Zero turns (transcript has user messages only) → suppress display.
      [ "${disp_up:-0}" = "0" ] && [ "${disp_down:-0}" = "0" ] && disp_up=""
      # shellcheck disable=SC2015  # Best-effort cache write; any failure is intentionally swallowed.
      printf '{"mtime":%s,"sum_up":%s,"sum_down":%s,"last_total_input":%s,"cost":%s}\n' \
        "$trans_mtime" "${disp_up:-0}" "${disp_down:-0}" "${tok_total_input:-0}" "${tok_cost:-0}" \
        > "${trans_cache}.tmp" 2>/dev/null && mv "${trans_cache}.tmp" "$trans_cache" 2>/dev/null || true
    fi
  fi
fi
# Override stdin's account-scope cost with transcript-scope computed cost
# whenever the walk produced a value (cache hit OR fresh compute).
# Falls back to stdin's $.cost.total_cost_usd when no transcript is reachable
# (fresh session before first turn, test fixtures without transcript path).
if [ -n "${tok_cost:-}" ]; then
  cost_usd="$tok_cost"
fi
dbg "transcript done"

# -------- context window % --------
ctx_limit=200000
case "${model_display:-}" in
  *"1M context"*|*"1M)"*) ctx_limit=1000000 ;;
esac

ctx_pct=""
# tok_total_input is the LAST turn's (input + cache_read + cache_creation),
# pre-summed by the jq reduce above. Reflects how much of the window is
# currently loaded — the right scope for ctx %, distinct from the
# cumulative ↑/↓ display (sum across turns, excludes cache_read).
if [ "${tok_total_input:-0}" -gt 0 ]; then
  ctx_pct=$(( tok_total_input * 100 / ctx_limit ))
  [ "$ctx_pct" -gt 99 ] && ctx_pct=99
fi

if [ -n "${ctx_pct:-}" ]; then
  if   [ "$ctx_pct" -gt 80 ]; then ctx_color="$C_REDBOLD"
  elif [ "$ctx_pct" -ge 50 ]; then ctx_color="$C_YELLOW"
  else                             ctx_color="$C_DIM"
  fi
  ctx_render="${ctx_color}${ctx_pct}% ctx${C_RESET}"
else
  ctx_render=""
fi

# -------- token formatting helper --------
fmt_k() {
  local n=${1:-0}
  if [ "$n" -ge 1000 ]; then
    printf '%dk' "$((n / 1000))"
  else
    printf '%d' "$n"
  fi
}

# -------- cost / tokens / ctx (three independent segments) --------
cost_fmt=$(printf '%.2f' "${cost_usd:-0}" 2>/dev/null || echo "0.00")
seg_cost="${C_GREEN}\$${cost_fmt}${C_RESET}"

seg_tokens=""
# disp_up = Σ(input_tokens + cache_creation) across turns; disp_down = Σ(output).
# Cache reads excluded on purpose — they re-load existing prefix every turn,
# would inflate this number ~10× without representing new work or new spend.
if [ -n "${disp_up:-}" ]; then
  seg_tokens="$(fmt_k "$disp_up")${C_YELLOW}${ARROW_UP}${C_RESET}/$(fmt_k "${disp_down:-0}")${C_CYAN}${ARROW_DOWN}${C_RESET}"
fi

seg_ctx="${ctx_render:-}"

# -------- final compose (driven by CC_STATUSLINE_SEGMENTS) --------
# Comma-separated whitelist+order. Valid tokens: model, project, git,
# cost, tokens, ctx. Unknown tokens are silently ignored. Default is the
# full set in the historical order so pre-existing behavior is preserved.
# Bash 3.2 compatible: no here-strings, no arrays.
line=""
sep="${C_GREY}│${C_RESET}"
segments_csv="${CC_STATUSLINE_SEGMENTS:-model,project,git,cost,tokens,ctx}"
IFS=','
for s in $segments_csv; do
  case "$s" in
    model)   piece="${seg_model:-}" ;;
    project) piece="${seg_project:-}" ;;
    git)     piece="${seg_git:-}" ;;
    cost)    piece="${seg_cost:-}" ;;
    tokens)  piece="${seg_tokens:-}" ;;
    ctx)     piece="${seg_ctx:-}" ;;
    *)       piece="" ;;
  esac
  [ -z "$piece" ] && continue
  if [ -z "$line" ]; then
    line="$piece"
  else
    line="${line} ${sep} ${piece}"
  fi
done
unset IFS
dbg "render"
printf '%s\n' "$line"

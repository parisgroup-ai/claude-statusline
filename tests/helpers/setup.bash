# shellcheck shell=bash

SCRIPT_PATH="${BATS_TEST_DIRNAME}/../bin/cc-statusline.sh"
FIXTURES_DIR="${BATS_TEST_DIRNAME}/fixtures"

# Wipe /tmp caches BEFORE every test — both transcript-cost cache (keyed by
# session_id from fixtures, so leftovers from prior runs poison cost asserts
# when transcript mtimes happen to collide) and git-branch cache (so
# fixture-bound session_ids start cold). Idempotent + safe: only matches
# files this script could have written.
setup() {
  rm -f /tmp/cc-statusline-test-session-*.json 2>/dev/null || true
  rm -f /tmp/cc-git-*.cache 2>/dev/null || true
}

# Create a temp dir, optionally git-init it, and return the path.
make_workspace() {
  local with_git="${1:-no}"
  local dir
  dir="$(mktemp -d "${BATS_TEST_TMPDIR}/ws-XXXXXX")"
  if [ "$with_git" = "git" ]; then
    git -C "$dir" init -q -b main
    git -C "$dir" -c user.email=t@t -c user.name=t commit --allow-empty -q -m "init"
  fi
  printf '%s' "$dir"
}

# Write a fake transcript file the script can stream via jq inputs.
# Default produces exactly $0.42 at Opus pricing:
#   20000*15 + 400*75 + 60000*1.5 = 300000 + 30000 + 90000 = 420000 / 1M = 0.42
# Model field omitted on purpose — exercises the default-Opus fail-safe path.
make_transcript() {
  local path="${BATS_TEST_TMPDIR}/transcript.jsonl"
  cat > "$path" <<'JSONL'
{"type":"user","message":{"role":"user","content":"hi"}}
{"type":"assistant","message":{"role":"assistant","usage":{"input_tokens":20000,"output_tokens":400,"cache_read_input_tokens":60000,"cache_creation_input_tokens":0}}}
JSONL
  printf '%s' "$path"
}

# Write a multi-turn transcript: 2 assistant turns, both Opus, that sum to $0.42.
# Per-turn: 10000*15 + 200*75 + 30000*1.5 = 150000 + 15000 + 45000 = 210000.
# Two turns → 420000 / 1M = 0.42.
make_transcript_multi_turn() {
  local path="${BATS_TEST_TMPDIR}/transcript-multi.jsonl"
  cat > "$path" <<'JSONL'
{"type":"user","message":{"role":"user","content":"hi"}}
{"type":"assistant","message":{"role":"assistant","model":"claude-opus-4-7","usage":{"input_tokens":10000,"output_tokens":200,"cache_read_input_tokens":30000,"cache_creation_input_tokens":0}}}
{"type":"user","message":{"role":"user","content":"more"}}
{"type":"assistant","message":{"role":"assistant","model":"claude-opus-4-7","usage":{"input_tokens":10000,"output_tokens":200,"cache_read_input_tokens":30000,"cache_creation_input_tokens":0}}}
JSONL
  printf '%s' "$path"
}

# Write a transcript with HIGH cache_read but LOW input — verifies that
# the display ↑ value EXCLUDES cache_read (issue #2). With cache_read
# included (the bug), display would show ~4M↑. Excluded (correct), display
# should show 200↑ (10 + 90 cache_creation across two turns + 100 input).
make_transcript_high_cache_read() {
  local path="${BATS_TEST_TMPDIR}/transcript-cache-heavy.jsonl"
  cat > "$path" <<'JSONL'
{"type":"user","message":{"role":"user","content":"hi"}}
{"type":"assistant","message":{"role":"assistant","model":"claude-opus-4-7","usage":{"input_tokens":50,"output_tokens":1000,"cache_read_input_tokens":2000000,"cache_creation_input_tokens":40}}}
{"type":"user","message":{"role":"user","content":"more"}}
{"type":"assistant","message":{"role":"assistant","model":"claude-opus-4-7","usage":{"input_tokens":50,"output_tokens":1000,"cache_read_input_tokens":2000000,"cache_creation_input_tokens":60}}}
JSONL
  printf '%s' "$path"
}

# Write a transcript with mixed models (Opus + Sonnet) — verifies per-turn price.
# Opus turn: 10000*15 + 200*75 + 0 + 0 = 150000 + 15000 = 165000
# Sonnet turn: 10000*3 + 200*15 + 0 + 0 = 30000 + 3000 = 33000
# Total = 198000 / 1M = 0.198 → $0.20
make_transcript_mixed_model() {
  local path="${BATS_TEST_TMPDIR}/transcript-mixed.jsonl"
  cat > "$path" <<'JSONL'
{"type":"user","message":{"role":"user","content":"hi"}}
{"type":"assistant","message":{"role":"assistant","model":"claude-opus-4-7","usage":{"input_tokens":10000,"output_tokens":200,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}
{"type":"user","message":{"role":"user","content":"switch"}}
{"type":"assistant","message":{"role":"assistant","model":"claude-sonnet-4-6","usage":{"input_tokens":10000,"output_tokens":200,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}
JSONL
  printf '%s' "$path"
}

# Render a fixture with __CWD__ and __TRANSCRIPT__ substituted, pipe to the script.
render() {
  local fixture="$1" cwd="$2" transcript="${3:-}"
  local json
  json="$(cat "${FIXTURES_DIR}/${fixture}")"
  json="${json//__CWD__/$cwd}"
  json="${json//__TRANSCRIPT__/$transcript}"
  printf '%s' "$json" | bash "$SCRIPT_PATH"
}

# Strip ANSI escapes from output for easier assertions.
strip_ansi() {
  # shellcheck disable=SC2001
  sed -E $'s/\x1b\\[[0-9;]*m//g'
}

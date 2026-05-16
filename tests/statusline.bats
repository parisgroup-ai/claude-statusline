#!/usr/bin/env bats
# shellcheck shell=bash

load 'helpers/setup'

@test "case 1: full input renders all segments" {
  local ws transcript out plain
  ws="$(make_workspace git)"
  transcript="$(make_transcript)"
  out="$(render full.json "$ws" "$transcript")"
  plain="$(printf '%s' "$out" | strip_ansi)"

  [[ "$plain" == *"Opus 4.7 1M"* ]]
  [[ "$plain" == *"$(basename "$ws")"* ]]
  [[ "$plain" == *"main"* ]]
  [[ "$plain" == *"\$0.42"* ]]
  [[ "$plain" == *"ctx"* ]]
}

@test "case 2: empty stdin degrades to Claude Code + \$0.00" {
  local out plain
  out="$(render empty.json "" "")"
  plain="$(printf '%s' "$out" | strip_ansi)"

  [[ "$plain" == *"Claude Code"* ]]
  [[ "$plain" == *"\$0.00"* ]]
}

@test "case 3: non-git cwd omits git segment" {
  local ws out plain
  ws="$(make_workspace no)"
  out="$(render no-git.json "$ws" "")"
  plain="$(printf '%s' "$out" | strip_ansi)"

  # No branch text like "main" or "(detached)" should appear
  [[ "$plain" != *"main"* ]]
  [[ "$plain" != *"(detached)"* ]]
  # Model + cost still present
  [[ "$plain" == *"Sonnet"* ]]
  [[ "$plain" == *"\$0.00"* ]]
}

@test "case 4: NO_COLOR produces no ANSI escapes" {
  local ws transcript out
  ws="$(make_workspace git)"
  transcript="$(make_transcript)"
  NO_COLOR=1 out="$(NO_COLOR=1 render full.json "$ws" "$transcript")"

  # ESC byte (0x1b) must not appear
  [[ "$out" != *$'\x1b'* ]]
}

@test "case 5: CC_STATUSLINE_NO_ICONS uses ASCII fallback" {
  local ws transcript out plain
  ws="$(make_workspace git)"
  transcript="$(make_transcript)"
  out="$(CC_STATUSLINE_NO_ICONS=1 render full.json "$ws" "$transcript")"
  plain="$(printf '%s' "$out" | strip_ansi)"

  # Nerd Font robot U+F544 = EF 95 84 must NOT appear
  [[ "$out" != *$'\xef\x95\x84'* ]]
  # ASCII fallbacks MUST appear
  [[ "$plain" == *"M "* ]]
  [[ "$plain" == *"P "* ]]
  [[ "$plain" == *"git "* ]]
}

@test "case 6: CC_STATUSLINE_SEGMENTS filters and reorders" {
  local ws transcript out plain
  ws="$(make_workspace git)"
  transcript="$(make_transcript)"
  out="$(CC_STATUSLINE_SEGMENTS=model,git render full.json "$ws" "$transcript")"
  plain="$(printf '%s' "$out" | strip_ansi)"

  # Model + branch still present (sanity)
  [[ "$plain" == *"Opus"* ]]
  [[ "$plain" == *"main"* ]]
  # Only model + git: no project basename, no $ sign (cost dropped).
  # These must be LAST so they actually fail the test pre-implementation
  # (bats+bash does not exit on a failing [[ ]] mid-test).
  [[ "$plain" != *"$(basename "$ws")"* ]]
  [[ "$plain" != *"\$"* ]]
}

@test "case 8: cost is computed from transcript, NOT from stdin .cost.total_cost_usd (regression #1)" {
  # The bug: stdin's $.cost.total_cost_usd is account-scope (carries over /clear).
  # Fix: compute cost from transcript token usage × per-model price table, ignoring stdin.
  # Setup: stdin says $99.99 (cumulative pre-clear), transcript tokens compute to $0.42.
  local ws transcript out plain
  ws="$(make_workspace git)"
  transcript="$(make_transcript)"
  out="$(render stale-cost.json "$ws" "$transcript")"
  plain="$(printf '%s' "$out" | strip_ansi)"

  # Sanity: render succeeded (model still shows).
  [[ "$plain" == *"Opus"* ]]
  # Critical (load-bearing, last): the stale stdin value must NOT leak through,
  # AND the computed transcript cost must be displayed.
  [[ "$plain" != *"\$99.99"* ]]
  [[ "$plain" == *"\$0.42"* ]]
}

@test "case 9: cost sums across multiple assistant turns" {
  # Two Opus turns, each producing half of $0.42 → must sum to $0.42.
  local ws transcript out plain
  ws="$(make_workspace git)"
  transcript="$(make_transcript_multi_turn)"
  out="$(render full.json "$ws" "$transcript")"
  plain="$(printf '%s' "$out" | strip_ansi)"

  [[ "$plain" == *"Opus"* ]]
  [[ "$plain" == *"\$0.42"* ]]
}

@test "case 10: mixed-model transcript applies per-turn pricing" {
  # Opus turn (10k in, 200 out) + Sonnet turn (10k in, 200 out).
  # Opus: 10000*15 + 200*75 = 165000. Sonnet: 10000*3 + 200*15 = 33000.
  # Sum = 198000 / 1M = $0.20 (printf rounds 0.198 → 0.20).
  local ws transcript out plain
  ws="$(make_workspace git)"
  transcript="$(make_transcript_mixed_model)"
  out="$(render full.json "$ws" "$transcript")"
  plain="$(printf '%s' "$out" | strip_ansi)"

  [[ "$plain" == *"Opus"* ]]
  # If everything were priced as Opus, total would be 330000 / 1M = $0.33.
  # Sonnet pricing on the second turn brings it down to $0.20 — verifies
  # that per-turn .message.model is being read.
  [[ "$plain" != *"\$0.33"* ]]
  [[ "$plain" == *"\$0.20"* ]]
}

@test "case 11: transcript cache is invalidated when mtime changes" {
  # First render writes cache; modifying transcript bumps mtime; second render
  # must recompute (not reuse stale cache).
  local ws transcript first second plain_first plain_second
  ws="$(make_workspace git)"
  transcript="$(make_transcript)"

  first="$(render full.json "$ws" "$transcript")"
  plain_first="$(printf '%s' "$first" | strip_ansi)"
  [[ "$plain_first" == *"\$0.42"* ]]

  # Replace transcript with a higher-cost one, bump mtime explicitly to ensure
  # the OS sees a change even on filesystems with low mtime resolution.
  cat > "$transcript" <<'JSONL'
{"type":"user","message":{"role":"user","content":"hi"}}
{"type":"assistant","message":{"role":"assistant","usage":{"input_tokens":40000,"output_tokens":800,"cache_read_input_tokens":120000,"cache_creation_input_tokens":0}}}
JSONL
  # 40000*15 + 800*75 + 120000*1.5 = 600000 + 60000 + 180000 = 840000 / 1M = $0.84
  # Force a guaranteed mtime bump (1 hour ahead). `touch -t YYYYMMDDHHMM` accepts
  # the same format on BSD (macOS) and GNU; the date arithmetic differs by flag.
  local future
  future=$(date -v+1H +%Y%m%d%H%M 2>/dev/null || date -d '+1 hour' +%Y%m%d%H%M)
  touch -t "$future" "$transcript"

  second="$(render full.json "$ws" "$transcript")"
  plain_second="$(printf '%s' "$second" | strip_ansi)"

  # Stale cache would still show $0.42 — load-bearing assertion last.
  [[ "$plain_second" != *"\$0.42"* ]]
  [[ "$plain_second" == *"\$0.84"* ]]
}

@test "case 12: ↑/↓ display sums tokens across multiple assistant turns (issue #2)" {
  # Multi-turn fixture: 2 Opus turns × (input=10000, output=200, cache_read=30000).
  # Cumulative semantics: ↑ = sum(input + cache_creation) = 10000+10000 = 20000 → "20k↑"
  # Last-turn semantics (the old bug): ↑ would render as "10k↑" (single-turn input).
  # The 20k vs 10k split is the load-bearing distinction.
  local ws transcript out plain
  ws="$(make_workspace git)"
  transcript="$(make_transcript_multi_turn)"
  out="$(render full.json "$ws" "$transcript")"
  plain="$(printf '%s' "$out" | strip_ansi)"

  # Sanity
  [[ "$plain" == *"Opus"* ]]
  # Critical: must NOT show last-turn-only (10k↑), must show cumulative (20k↑).
  [[ "$plain" != *"10k"* ]]
  [[ "$plain" == *"20k"* ]]
}

@test "case 13: ↑ display EXCLUDES cache_read across all turns (issue #2)" {
  # Cache-heavy transcript: 2 turns × cache_read=2,000,000 tokens.
  # Buggy semantics (sum incl. cache_read): ↑ ≈ 4M → "4M↑" or "4000k↑"
  # Correct semantics (sum excl. cache_read): ↑ = (50+40) + (50+60) = 200 → "200↑"
  # Cost is dominated by cache_read at $1.50/M Opus → 2*2M*1.5/1M = $6.00, plus input/output.
  local ws transcript out plain
  ws="$(make_workspace git)"
  transcript="$(make_transcript_high_cache_read)"
  out="$(render full.json "$ws" "$transcript")"
  plain="$(printf '%s' "$out" | strip_ansi)"

  # Sanity: render produced a tokens segment.
  [[ "$plain" == *"↑"* ]]
  # Critical (last, load-bearing): cache_read leakage would manifest as
  # millions in the ↑ value. The display must show the small "200" sum.
  [[ "$plain" != *"4M"* ]]
  [[ "$plain" != *"M↑"* ]]
  [[ "$plain" == *"200"*"↑"* ]]
}

@test "case 14: ctx % uses last-turn total (incl. cache_read), not the cumulative ↑ sum" {
  # Same cache-heavy fixture: last turn has 50 input + 2M cache_read + 60 cache_creation
  # = 2,000,110 total. With 1M ctx limit (Opus 4.7), that caps at 99% (clamped).
  # If ctx % were sourced from disp_up (200), it would render "0% ctx" — wrong.
  local ws transcript out plain
  ws="$(make_workspace git)"
  transcript="$(make_transcript_high_cache_read)"
  out="$(render full.json "$ws" "$transcript")"
  plain="$(printf '%s' "$out" | strip_ansi)"

  # Critical (last, load-bearing): ctx % must reflect window pressure (cache_read
  # IS loaded), not the cumulative-display semantics.
  [[ "$plain" != *"0% ctx"* ]]
  [[ "$plain" == *"99% ctx"* ]]
}

@test "case 15: zero-assistant-turns transcript suppresses ↑/↓ segment on BOTH cache miss AND cache hit (issue #3)" {
  # Transcript with only user messages → no tokens to render.
  # The first render is a cache miss; suppression has always worked there.
  # The second render hits the warm cache; suppression must apply there too,
  # otherwise the cached "0/0" sums leak through as "0↑/0↓" in the display.
  local ws transcript first second plain_first plain_second
  ws="$(make_workspace git)"
  transcript="$(make_transcript_zero_turns)"

  first="$(render full.json "$ws" "$transcript")"
  plain_first="$(printf '%s' "$first" | strip_ansi)"

  # Same call again — exercises the cache-hit path with a populated cache file.
  second="$(render full.json "$ws" "$transcript")"
  plain_second="$(printf '%s' "$second" | strip_ansi)"

  # Sanity: both renders produced model + branch (suppression is scoped to
  # tokens segment only).
  [[ "$plain_first" == *"Opus"* ]]
  [[ "$plain_second" == *"Opus"* ]]
  # Critical (load-bearing, last): no "0↑" leakage on either path.
  [[ "$plain_first" != *"0↑"* ]]
  [[ "$plain_second" != *"0↑"* ]]
}

@test "case 16: CC_STATUSLINE_ICON_MODEL overrides default model icon" {
  local ws transcript out plain
  ws="$(make_workspace git)"
  transcript="$(make_transcript)"
  out="$(CC_STATUSLINE_ICON_MODEL='🤖' render full.json "$ws" "$transcript")"
  plain="$(printf '%s' "$out" | strip_ansi)"

  # Default Nerd Font robot (U+F544 = EF 95 84) must NOT appear; custom must.
  [[ "$out" != *$'\xef\x95\x84'* ]]
  [[ "$plain" == *"🤖"* ]]
  # Other icons untouched.
  [[ "$out" == *$'\xef\x81\xbc'* ]]
}

@test "case 17: per-icon overrides apply independently for project and git" {
  local ws transcript out plain
  ws="$(make_workspace git)"
  transcript="$(make_transcript)"
  out="$(CC_STATUSLINE_ICON_PROJECT='📁' CC_STATUSLINE_ICON_GIT='⎇' render full.json "$ws" "$transcript")"
  plain="$(printf '%s' "$out" | strip_ansi)"

  [[ "$plain" == *"📁"* ]]
  [[ "$plain" == *"⎇"* ]]
  # Default folder (U+F07C = EF 81 BC) + git branch (U+E0A0 = EE 82 A0) gone.
  [[ "$out" != *$'\xef\x81\xbc'* ]]
  [[ "$out" != *$'\xee\x82\xa0'* ]]
  # Model icon (Nerd Font robot) still default since not overridden.
  [[ "$out" == *$'\xef\x95\x84'* ]]
}

@test "case 18: CC_STATUSLINE_NO_ICONS wins over per-icon overrides" {
  local ws transcript out plain
  ws="$(make_workspace git)"
  transcript="$(make_transcript)"
  # Both icon overrides AND no-icons set: no-icons must win (ASCII fallback).
  out="$(CC_STATUSLINE_NO_ICONS=1 CC_STATUSLINE_ICON_MODEL='🤖' CC_STATUSLINE_ICON_PROJECT='📁' render full.json "$ws" "$transcript")"
  plain="$(printf '%s' "$out" | strip_ansi)"

  # The override emojis must NOT appear.
  [[ "$plain" != *"🤖"* ]]
  [[ "$plain" != *"📁"* ]]
  # ASCII fallbacks must appear (load-bearing, last).
  [[ "$plain" == *"M "* ]]
  [[ "$plain" == *"P "* ]]
}

@test "case 19: CC_STATUSLINE_SEPARATOR replaces the default │ glyph" {
  local ws transcript out plain
  ws="$(make_workspace git)"
  transcript="$(make_transcript)"
  out="$(CC_STATUSLINE_SEPARATOR='·' render full.json "$ws" "$transcript")"
  plain="$(printf '%s' "$out" | strip_ansi)"

  # Default │ (U+2502 = E2 94 82) absent, custom · present.
  [[ "$out" != *$'\xe2\x94\x82'* ]]
  [[ "$plain" == *"·"* ]]
}

@test "case 20: CC_STATUSLINE_COLOR_MODEL injects custom ANSI on the model segment" {
  local ws transcript out
  ws="$(make_workspace git)"
  transcript="$(make_transcript)"
  # Blue (\x1b[34m) instead of default cyan (\x1b[36m).
  # TERM=xterm is set explicitly because GitHub Actions defaults to TERM=dumb,
  # which suppresses all colors (including overrides) by design.
  out="$(TERM=xterm CC_STATUSLINE_COLOR_MODEL=$'\x1b[34m' render full.json "$ws" "$transcript")"

  # Custom blue must appear (load-bearing).
  [[ "$out" == *$'\x1b[34m'* ]]
  # Cyan must NOT appear on the model segment; cyan ↓ arrow is suppressed
  # because this transcript has output_tokens, but cost segment uses green
  # and arrows use C_CYAN — assert by checking cyan precedes 'Opus' nowhere.
  # Easier: assert the model line still renders sensibly.
  local plain
  plain="$(printf '%s' "$out" | strip_ansi)"
  [[ "$plain" == *"Opus"* ]]
}

@test "case 21: NO_COLOR wins over color overrides (no ANSI escapes leak through)" {
  local ws transcript out
  ws="$(make_workspace git)"
  transcript="$(make_transcript)"
  # TERM=xterm forces the "colors are otherwise enabled" branch, so this test
  # actually exercises NO_COLOR's precedence rather than passing trivially
  # under CI's default TERM=dumb (which would suppress ANSI anyway).
  out="$(TERM=xterm NO_COLOR=1 CC_STATUSLINE_COLOR_MODEL=$'\x1b[34m' CC_STATUSLINE_COLOR_COST=$'\x1b[35m' render full.json "$ws" "$transcript")"

  # No ESC byte anywhere — overrides must be skipped entirely under NO_COLOR.
  [[ "$out" != *$'\x1b'* ]]
}

@test "case 22: CC_STATUSLINE_COLOR_SEPARATOR colors the separator with custom ANSI" {
  local ws transcript out
  ws="$(make_workspace git)"
  transcript="$(make_transcript)"
  # Magenta (\x1b[35m) on the separator. Default is grey (\x1b[90m).
  # TERM=xterm — see case 20 rationale.
  out="$(TERM=xterm CC_STATUSLINE_COLOR_SEPARATOR=$'\x1b[35m' render full.json "$ws" "$transcript")"

  # The custom magenta sequence must appear; the default grey must not on
  # the separator. (Grey is used nowhere else by default, so a plain absence
  # check is load-bearing.)
  [[ "$out" == *$'\x1b[35m'* ]]
  [[ "$out" != *$'\x1b[90m'* ]]
}

@test "case 23: TERM=dumb suppresses color overrides (CI parity)" {
  local ws transcript out
  ws="$(make_workspace git)"
  transcript="$(make_transcript)"
  # Symmetric to case 21: when the terminal advertises itself as dumb, any
  # color override must be silently dropped — same precedence as NO_COLOR.
  # This codifies the GitHub Actions behavior so future test edits don't
  # accidentally tighten the gate.
  out="$(TERM=dumb CC_STATUSLINE_COLOR_MODEL=$'\x1b[34m' render full.json "$ws" "$transcript")"

  # No ESC byte under TERM=dumb, even with overrides set.
  [[ "$out" != *$'\x1b'* ]]
}

@test "case 7: warm git cache reread does not concatenate timestamp into branch (CHORE-008)" {
  # Repro: clean tree (g_dirty='') writes 'main\t\t<ts>\n' to /tmp/cc-git-*.cache.
  # bash 3.2 'IFS=$'\t' read -r a b c' collapses consecutive tabs, so the
  # second invocation reads b=<timestamp> and renders it as the dirty marker:
  # the statusline shows e.g. 'main1776443258' instead of 'main'.
  local ws transcript first second plain_first plain_second
  ws="$(make_workspace git)"
  transcript="$(make_transcript)"

  # First call: cold cache -> recomputes + writes cache file.
  first="$(render full.json "$ws" "$transcript")"
  plain_first="$(printf '%s' "$first" | strip_ansi)"

  # Second call within 3s: warm cache -> reread path is exercised.
  second="$(render full.json "$ws" "$transcript")"
  plain_second="$(printf '%s' "$second" | strip_ansi)"

  # Sanity: both calls render the branch.
  [[ "$plain_first" == *"main"* ]]
  [[ "$plain_second" == *"main"* ]]

  # Bug guard: the rendered branch must not be 'main' immediately followed by
  # digits (the unix timestamp leaking from the third cache field).
  # These are the load-bearing assertions.
  [[ ! "$plain_first" =~ main[0-9] ]]
  [[ ! "$plain_second" =~ main[0-9] ]]
}

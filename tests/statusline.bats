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

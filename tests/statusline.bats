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

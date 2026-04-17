# shellcheck shell=bash

SCRIPT_PATH="${BATS_TEST_DIRNAME}/../bin/cc-statusline.sh"
FIXTURES_DIR="${BATS_TEST_DIRNAME}/fixtures"

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

# Write a fake transcript file the script can tail -r.
make_transcript() {
  local path="${BATS_TEST_TMPDIR}/transcript.jsonl"
  cat > "$path" <<'JSONL'
{"type":"user","message":{"role":"user","content":"hi"}}
{"type":"assistant","message":{"role":"assistant","usage":{"input_tokens":1200,"output_tokens":300,"cache_read_input_tokens":5000,"cache_creation_input_tokens":100}}}
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

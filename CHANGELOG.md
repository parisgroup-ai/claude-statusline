# Changelog

All notable changes to this project will be documented in this file.

## 1.0.0 (2026-04-17)

Initial release. Published from [parisgroup-ai/claude-statusline](https://github.com/parisgroup-ai/claude-statusline) (split out of [parisgroup-ai/infra](https://github.com/parisgroup-ai/infra)).

### Features

- Port statusline script from `~/.claude/statusline.sh` with pre-existing-behavior bats tests (FEAT-003)
- `CC_STATUSLINE_NO_ICONS` env var to swap Nerd Font icons for ASCII fallbacks (FEAT-004)
- `CC_STATUSLINE_SEGMENTS` env var to filter and reorder rendered segments (FEAT-005)

### Bug Fixes

- Portable `md5`/`stat`/`tail -r` fallbacks so the script runs on both macOS (BSD) and Linux (GNU)
- SC2015 suppression on best-effort cache writes
- Warm git-cache reread no longer concatenates timestamp into branch (CHORE-008)

### Ops

- CI workflow: shellcheck + bats on every push/PR
- Release workflow: semantic-release to GitHub Packages on push to `main`
- `.shellcheckrc` policy: inline disables only, no global rule muting

---

Prior entries from the monorepo-era CHANGELOG are intentionally omitted — they listed infra-wide commits unrelated to this package.

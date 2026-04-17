# 1.0.0 (2026-04-17)


### Bug Fixes

* **claude-statusline:** portable md5/stat/tac fallbacks for Linux CI ([82855c3](https://github.com/parisgroup-ai/claude-statusline/commit/82855c3b8dce5396495dd8a7aa505f15dbceb83d))
* **claude-statusline:** suppress SC2015 on best-effort cache writes ([4a8d1f5](https://github.com/parisgroup-ai/claude-statusline/commit/4a8d1f58d11921fb3c5575d6e1fb09beba774386))
* **claude-statusline:** warm git-cache reread no longer concatenates timestamp into branch (CHORE-008) ([4e4d703](https://github.com/parisgroup-ai/claude-statusline/commit/4e4d703e8ed2ea7b3538540d8dd047e0daa28df8))


### Features

* **claude-statusline:** add CC_STATUSLINE_NO_ICONS env var (FEAT-004) ([05213b4](https://github.com/parisgroup-ai/claude-statusline/commit/05213b47c2b6daab9338804cb56de87d78c14a57))
* **claude-statusline:** add CC_STATUSLINE_SEGMENTS env var (FEAT-005) ([d73e12b](https://github.com/parisgroup-ai/claude-statusline/commit/d73e12b3c38db07572f6b9e3633eead4f6f539c4))
* **claude-statusline:** port statusline script from ~/.claude (FEAT-003) ([abd7c58](https://github.com/parisgroup-ai/claude-statusline/commit/abd7c585cc9b8d4f5f03a323850decdd6f127fa5))
* **repo:** first release from dedicated parisgroup-ai/claude-statusline ([09935b5](https://github.com/parisgroup-ai/claude-statusline/commit/09935b5b796f40f60242be56872253f7bf2fbd52))

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

# @parisgroup-ai/claude-statusline

Bash-powered statusline for [Claude Code](https://docs.claude.com/en/docs/claude-code/overview). Renders model, project, git branch + dirty flag, cost, token IO, and context-window percentage.

```
 Opus 4.7 1M │  infra │  main* │ $0.42  12k↑/3k↓  6% ctx
```

## Install

Recommended — global install (lowest latency):

```bash
npm install -g @parisgroup-ai/claude-statusline
```

Then in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "claude-statusline"
  }
}
```

Alternative — no install via `npx`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "npx -y @parisgroup-ai/claude-statusline"
  }
}
```

`npx` adds 20–40 ms per render on a warm cache and downloads on first use.

### GitHub Packages authentication

This package lives on the GitHub Packages registry. Create a `.npmrc` in your home directory with:

```
@parisgroup-ai:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}
```

`GITHUB_TOKEN` must be a personal access token with at least `read:packages` scope.

## Requirements

| Tool | Required | Notes |
|---|---|---|
| `bash` ≥ 3.2 | yes | Script is macOS-default-bash compatible. |
| `jq` | yes | Prints `[install jq]` and exits 0 if missing. |
| `git` | no | Git segment is skipped if git is missing or cwd is outside a repo. |
| Nerd Font | recommended | See `CC_STATUSLINE_NO_ICONS` to opt out. |

## Configuration

All configuration is via environment variables. Prefix the command in `settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "CC_STATUSLINE_SEGMENTS=model,git claude-statusline"
  }
}
```

| Variable | Values | Default | Effect |
|---|---|---|---|
| `NO_COLOR` | any value (presence) | unset | Disable ANSI colors. Wins over all `CC_STATUSLINE_COLOR_*`. |
| `TERM` | `dumb` | — | Same as `NO_COLOR`. |
| `CC_STATUSLINE_DEBUG` | `1` | unset | Append timing markers to `/tmp/cc-statusline.err`. |
| `CC_STATUSLINE_NO_ICONS` | `1` | unset | Replace Nerd Font icons with ASCII (`M`/`P`/`git`/`^`/`v`). Wins over `CC_STATUSLINE_ICON_*`. |
| `CC_STATUSLINE_SEGMENTS` | CSV of `model,project,git,cost,tokens,ctx` | all | Reorder/omit segments. Unknown tokens ignored. |

### Theming

Per-segment glyphs, colors, and the separator are overridable. Defaults are unchanged, so omitting these variables keeps the historical look.

| Variable | Default | Notes |
|---|---|---|
| `CC_STATUSLINE_ICON_MODEL` | `` (nf-fa-robot) | Any string. Ignored under `CC_STATUSLINE_NO_ICONS=1`. |
| `CC_STATUSLINE_ICON_PROJECT` | `` (nf-fa-folder_open) | Any string. |
| `CC_STATUSLINE_ICON_GIT` | `` (nf-dev-git_branch) | Any string. |
| `CC_STATUSLINE_SEPARATOR` | `│` | Glyph between segments. Honored even under `NO_COLOR`. |
| `CC_STATUSLINE_COLOR_MODEL` | `\x1b[36m` (cyan) | Raw ANSI escape. |
| `CC_STATUSLINE_COLOR_PROJECT` | `\x1b[35m` (magenta) | Raw ANSI escape. |
| `CC_STATUSLINE_COLOR_GIT` | `\x1b[33m` (yellow) | Raw ANSI escape. Applies to git icon + branch label. |
| `CC_STATUSLINE_COLOR_COST` | `\x1b[32m` (green) | Raw ANSI escape. |
| `CC_STATUSLINE_COLOR_DIRTY` | `\x1b[1;31m` (red bold) | Raw ANSI escape. Marker shown next to dirty branches. |
| `CC_STATUSLINE_COLOR_SEPARATOR` | `\x1b[90m` (bright black) | Raw ANSI escape. |

Color values are passed as **raw ANSI** — the script never interprets `\x1b` / `\033` from strings. Decode in your shell:

```bash
# bash / zsh — ANSI-C quoting
export CC_STATUSLINE_COLOR_MODEL=$'\x1b[34m'

# POSIX-safe
export CC_STATUSLINE_COLOR_MODEL="$(printf '\x1b[34m')"
```

Token arrows (`↑` / `↓`) and the dynamic context-window thresholds (>80% red, ≥50% yellow, otherwise dim) are not themable in this release.

### Examples

Minimal (model + git only):
```json
{ "command": "CC_STATUSLINE_SEGMENTS=model,git claude-statusline" }
```

No Nerd Font:
```json
{ "command": "CC_STATUSLINE_NO_ICONS=1 claude-statusline" }
```

Emoji icons + bullet separator:
```bash
export CC_STATUSLINE_ICON_MODEL='🤖'
export CC_STATUSLINE_ICON_PROJECT='📁'
export CC_STATUSLINE_ICON_GIT='⎇'
export CC_STATUSLINE_SEPARATOR='·'
```

Cool palette (blue model, teal git, dim separator):
```bash
export CC_STATUSLINE_COLOR_MODEL=$'\x1b[38;5;75m'
export CC_STATUSLINE_COLOR_GIT=$'\x1b[38;5;79m'
export CC_STATUSLINE_COLOR_SEPARATOR=$'\x1b[2m'
```

## Development

```bash
brew install bats-core shellcheck jq   # macOS
npm run lint                            # shellcheck
npm test                                # bats
```

## License

MIT © Paris Group

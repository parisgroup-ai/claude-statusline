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
| `NO_COLOR` | any value (presence) | unset | Disable ANSI colors. |
| `TERM` | `dumb` | — | Same as `NO_COLOR`. |
| `CC_STATUSLINE_DEBUG` | `1` | unset | Append timing markers to `/tmp/cc-statusline.err`. |
| `CC_STATUSLINE_NO_ICONS` | `1` | unset | Replace Nerd Font icons with ASCII (`M`/`P`/`git`/`^`/`v`). |
| `CC_STATUSLINE_SEGMENTS` | CSV of `model,project,git,cost,tokens,ctx` | all | Reorder/omit segments. Unknown tokens ignored. |

### Examples

Minimal (model + git only):
```json
{ "command": "CC_STATUSLINE_SEGMENTS=model,git claude-statusline" }
```

No Nerd Font:
```json
{ "command": "CC_STATUSLINE_NO_ICONS=1 claude-statusline" }
```

## Development

```bash
brew install bats-core shellcheck jq   # macOS
npm run lint                            # shellcheck
npm test                                # bats
```

## License

MIT © Paris Group

# Session Brief — 2026-05-15

## Last Session Summary
Migrated `@parisgroup-ai/claude-statusline` to claude-devkit managed mode (`baseline-filtered` view, profile `library-cli`, 10 skills + 6 commands). Uninstalled upstream `pg-baseline@parisgroup-ai` plugin. Discovered and reported a bug in claude-devkit's `tooling-autoupdate` hook that caused a stale context-sync counter.

## Current State
- **Branch**: `main` (in sync with `origin/main`)
- **Last commit**: `d3f11ad chore(devkit): adopt managed mode (baseline-filtered view)`
- **Pending changes**: none
- **Devkit state**: managed view `baseline-filtered@devkit-managed-parisgroup-ai-claude-statusline v1.0.0-ce4a1822` registered with Claude Code; baseline 0.13.1; doctor green

## Open Items
- **Upstream**: https://github.com/parisgroup-ai/claude-devkit/issues/62 — `is_processed` schema mismatch in `packages/baseline/hooks/lib/cache.sh`. Once fixed upstream, the local `processed.json` migration I applied (string → object) becomes unnecessary but harmless.

## Decisions Made (don't re-debate)
- **Managed mode over upstream plugin** — view is filtered to the 10 skills + 6 commands actually used by a library-cli project, reducing skill-listing budget pressure (was 79 skills from pg-baseline, now 10). Upstream `pg-baseline` was uninstalled to complete the migration.
- **Gitignored devkit-generated artifacts**: `.claude/devkit/staging/` (contains absolute-path symlinks to `~/.claude/devkit/source/…` — won't work on other machines) and `.claude/devkit/marketplace.json` (auto-generated, header explicitly says "do not edit"). Source of truth committed: `devkit.config.yaml` + `.claude/devkit.lock.json`. Reproducible via `claude-devkit init`.
- **`.nvmrc` pinned to `20`** to align with `engines.node: ">=20"` (caught by `devkit doctor`).

## Suggested Next Steps
1. If a new collaborator clones the repo, they run `claude-devkit init` to regenerate the staging view locally.
2. Watch issue #62 — if upstream ships option 2 (one-shot migration on startup), no local action needed; if option 1 (tolerant reader only), the migrated `processed.json` keeps working either way.
3. Whenever `engines.node` is bumped, update `.nvmrc` in lockstep (doctor will catch drift).

# Spec: pg-devkit reference hygiene (claude-devkit rename)

Roadmap: rm-002
Date: 2026-06-04
Status: approved (GATE 1, 2026-06-04)
Links: gh:parisgroup-ai/claude-statusline#5

## Objective

Remove stale `claude-devkit` references left over from the GitHub repo rename
to `pg-devkit` (CHORE-041 upstream, GH #5 here).

## Survey results (full tracked-file sweep, `git grep claude-devkit`)

| Location | Verdict |
|---|---|
| `.gitignore:5-7` — legacy manual block ("claude-devkit auto-generated view" + `.claude/devkit/staging/` + `.claude/devkit/marketplace.json`) | **Remove** — only real stale ref; both entries are subsumed by `.claude/devkit/` in the pg-devkit managed block |
| `.pgdk/session-brief.md` (2 refs) | Keep — self-referential prose about this task; file is rewritten every `/session-close` |
| `.opencode/skills/*` (~40 refs) | Out of scope — pg-devkit managed view generated from upstream pg-baseline, untracked + gitignored |
| `.github/workflows/`, `devkit.config.yaml`, `README.md`, `package.json` | Already clean — zero refs |

## Design

Single change: delete `.gitignore` lines 5-7 (the legacy block). No ignore
coverage is lost — overlap with the managed block is total. Then comment on
GH #5 with the sweep evidence and close it.

## Non-goals

- Rewriting historical prose (session brief, memory-bank).
- Touching the `.opencode/` managed view (upstream-owned).

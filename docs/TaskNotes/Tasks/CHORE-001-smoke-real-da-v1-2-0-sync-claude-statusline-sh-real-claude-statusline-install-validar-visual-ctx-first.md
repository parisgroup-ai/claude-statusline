---
uid: chore-001
status: done
priority: normal
scheduled: 2026-06-04
completed: 2026-06-04
pomodoros: 0
firstStartedAt: 2026-06-04T15:13:29.007807Z
tags:
- task
- chore
ai:
  parallelParts: 0
  needsReview: false
  uncertainty: low
  hintsInferred: true
---

# Smoke real da v1.2.0 + sync ~/.claude/statusline.sh.real (claude-statusline install + validar visual ctx-first)

v1.2.0 shipped the rich layout as factory default (ctx-first segment order +
Apple emoji model icon, commit `d5b38d0`, GH #6). The operator's live
statusline (`~/.claude/statusline.sh.real`) has been out of sync since the
2026-05-15 session — no `claude-statusline install` run yet — and now the
default visual changed, so the drift is visible.

## Subtasks

- [x] Install/sync: published v1.2.0 tarball (`npm pack`) → `~/.claude/statusline.sh.real`
      (tarball verified byte-identical to working tree; backup at
      `~/.claude/statusline.sh.real.bak-2026-06-04`)
- [x] Smoke with the real live transcript (452K session jsonl): ctx-first order ✓,
      🍎 model icon ✓, `CC_STATUSLINE_NO_ICONS=1` ASCII fallback (`M`/`P`/`git`/`^`/`v`) ✓,
      legacy-order env recipe ✓, wrapper chain `statusline.sh → .real` ✓

## Finding (2026-06-04 smoke)

The task premise went stale on 2026-06-02: the operator's LIVE statusline is no
longer `~/.claude/statusline.sh.real`. `settings.json` points at
`~/.claude/devkit/statusline.sh` (pg-devkit resolver shim, written by
`pg-devkit statusline install --rich`), which execs pg-baseline's
`lib/statusline-rich.sh` — a self-contained 7-fragment script that never touches
`.real`. The `.real` sync keeps the legacy `~/.claude/statusline.sh → .real`
chain fresh, but real sessions render the devkit variant.

## Notes

- Same smoke ritual used for 1.0.2 (see session brief 2026-05-15/16).
- Legacy layout recipe lives in README if the operator prefers the old order.

## Related

- GH #6 (closed) — rich layout default
- `bin/cc-statusline.sh` — canonical script
- v1.2.0 release: github.com/parisgroup-ai/claude-statusline/releases

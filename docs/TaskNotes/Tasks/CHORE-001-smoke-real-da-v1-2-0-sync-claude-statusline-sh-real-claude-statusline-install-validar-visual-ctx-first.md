---
uid: chore-001
status: open
priority: normal
scheduled: 2026-06-04
pomodoros: 0
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

- [ ] Install/sync: `claude-statusline install` (updates `~/.claude/statusline.sh.real`)
- [ ] Smoke in a real session: ctx-first order renders, 🍎 model icon shows,
      `CC_STATUSLINE_NO_ICONS=1` ASCII fallback (`M`) still works

## Notes

- Same smoke ritual used for 1.0.2 (see session brief 2026-05-15/16).
- Legacy layout recipe lives in README if the operator prefers the old order.

## Related

- GH #6 (closed) — rich layout default
- `bin/cc-statusline.sh` — canonical script
- v1.2.0 release: github.com/parisgroup-ai/claude-statusline/releases

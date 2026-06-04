---
uid: feat-001
status: in-progress
priority: high
scheduled: 2026-06-04
pomodoros: 0
firstStartedAt: 2026-06-04T14:20:53.159580Z
tags:
- task
- feat
ai:
  parallelParts: 0
  needsReview: true
  uncertainty: med
  hintsInferred: true
---

# Ship rich layout as default (ctx-first + Apple model icon)

Flip the package defaults to the advertised rich layout (roadmap rm-001):
`CC_STATUSLINE_SEGMENTS` defaults to `ctx,model,project,git,cost,tokens`
(ctx-first) and `ICON_MODEL` defaults to 🍎 (U+1F34E) instead of the Nerd
Font robot (U+F544). Aligns the package with pg-devkit's managed install,
which already defaults to `--rich` since cli-v0.78.0. Legacy look stays
reachable via env (`CC_STATUSLINE_SEGMENTS` + `CC_STATUSLINE_ICON_MODEL`).

Closes GH #6

## Subtasks

- [x] Red: case 24 (ctx-first default order) + case 25 (Apple icon default)
- [x] Update cases 5/16/17 that pinned the robot glyph as default
- [x] Green: flip `segments_csv` + `ICON_MODEL` defaults in `bin/cc-statusline.sh`
- [x] README: hero example, SEGMENTS row, ICON_MODEL row, legacy-layout recipe
- [x] Verify: 25/25 bats × 3 runs, shellcheck clean, visual smoke ctx-first
- [ ] Commit + push (direct-to-main) → semantic-release publishes minor

## Notes

- Apple glyph = emoji U+1F34E (F0 9F 8D 8E), matching pg-baseline's
  `statusline-rich.sh` model fragment — NOT a Nerd Font PUA codepoint.
- `CC_STATUSLINE_NO_ICONS=1` ASCII fallback (`M`) unchanged.

## Related

- GH #6 — Ship the rich layout as default (spun out of pg-devkit#126)
- `.pgdk/roadmap.yaml` rm-001
- `bin/cc-statusline.sh` — icons block + final compose
- `tests/statusline.bats` — cases 24/25

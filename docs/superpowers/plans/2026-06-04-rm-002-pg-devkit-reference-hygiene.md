# Plan: pg-devkit reference hygiene

Roadmap: rm-002
Spec: docs/superpowers/specs/2026-06-04-rm-002-pg-devkit-reference-hygiene.md

## Tasks

- [ ] 1. Remove legacy claude-devkit block from `.gitignore` (lines 5-7) and
  verify `git grep claude-devkit` reports only the session-brief prose refs.
  Commit `chore(hygiene): drop legacy claude-devkit block from .gitignore`.
- [ ] 2. Post sweep evidence as a comment on GH #5 and close the issue
  (after GATE 2 push).

---
type: playbook
title: Domain overview — claude-statusline
description: Bash-powered statusline for [Claude Code](https://docs.claude.com/en/docs/claude-code/overview). Renders context-window percentage, model, project, git branch + dirty flag, cost, and token IO — the **rich layout** (ctx-first + Apple model i
tags: [domain, overview, fleet-adoption]
source: README.md
---

# Domain overview — claude-statusline

Bash-powered statusline for [Claude Code](https://docs.claude.com/en/docs/claude-code/overview). Renders context-window percentage, model, project, git branch + dirty flag, cost, and token IO — the **rich layout** (ctx-first + Apple model i

## Why this catalog exists

This repo adopted the fleet `docs/domain/` OKF catalog so durable domain
knowledge (metrics, schemas, playbooks) has a single, versioned home —
separate from session memory and ADRs.

## Next entries

Add real `metric`, `schema`, or `playbook` files under `docs/domain/` with:

- mandatory frontmatter `type:`
- `source:` pointing at the code or doc that owns the truth
- a one-line definition (do not duplicate long specs — link them)

## Sources

- Product surface: [`README.md`](/README.md) (when present)
- Package identity: `@parisgroup-ai/claude-statusline`

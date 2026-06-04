# Session Brief — 2026-06-04 (tarde — CHORE-001 fechado, repo em modo manutenção)

## Last Session Summary
Sessão curta de fechamento da última pendência: CHORE-001 (smoke da v1.2.0 + sync
`~/.claude/statusline.sh.real`). Gate de producer real cumprido — `npm pack` do tarball
publicado v1.2.0, verificado byte-idêntico ao working tree, sync do `.real` feito **a partir do
tarball** (backup em `~/.claude/statusline.sh.real.bak-2026-06-04`). Smoke com o transcript real
da sessão (452K jsonl): ctx-first ✓, 🍎 ✓, fallback ASCII (`CC_STATUSLINE_NO_ICONS=1` → `M`) ✓,
recipe legacy-order ✓, wrapper chain ✓ — e o cost veio do transcript ($22.40) ignorando o stdin
fake, confirmando o fix per-transcript em produção. Commit `1f81162` pushed, CI + Release verdes.
Removido também o `.bak` de settings pendente do brief anterior.

## Current State
- **Branch**: `main` — sincronizado com origin (0 ahead / 0 behind)
- **Last commit**: `1f81162 chore(tn): close CHORE-001 - v1.2.0 smoke passed, .real synced`
- **Published**: **v1.2.0** (verificar sempre via `gh release list --limit 1` — package.json fica em 1.0.0 por design)
- **Pending changes**: nenhum — working tree limpo
- **Workflow policy**: `direct-to-main`
- **Backlog**: **TUDO zerado** — 0 tn tasks, 0 issues, 0 PRs, roadmap vazio (rm-001/rm-002 done)

## Achado importante (premissa stale corrigida)
A live statusline do operador **não é mais** `~/.claude/statusline.sh.real` desde 2026-06-02:
`settings.json` → `~/.claude/devkit/statusline.sh` (shim do `pg-devkit statusline install
--rich`) → `statusline-rich.sh` do pg-baseline (7 fragmentos, self-contained, nunca toca o
`.real`). Operador decidiu **manter o devkit rich como live** (superset: + 🌿 workflow +
dispatch). Consequência: validação visual de releases deste repo = pipe de stdin JSON direto no
`bin/cc-statusline.sh`/`.real`, nunca "olhar a statusline da sessão". Registrado no body do
CHORE-001 e na auto-memory (`statusline-architecture.md`).

## Decisions Made (don't re-debate)
- **Devkit rich fica como live statusline** — não repontar settings.json pro claude-statusline puro.
- **Ritual de sync do `.real`**: sempre via tarball publicado (`npm pack` + verificar
  tarball==repo), nunca cp direto do working tree.
- **Decisões anteriores seguem valendo** — per-transcript scope invariant, sem
  `@semantic-release/git`, package.json em 1.0.0 é intencional.

## Suggested Next Steps
1. **Nada obrigatório** — repo está oficialmente em modo manutenção pós-v1.2.0.
2. **Brainstorm de novo ciclo** (opcional) — `roadmap suggest` segue com candidatos fracos
   ("claude-statusline" 13 commits residuais, "devkit" 5); se nada surgir, deixar quieto.
3. Se surgir bug visual na statusline live do operador → suspeitar primeiro do
   `statusline-rich.sh` do pg-baseline, não deste repo.

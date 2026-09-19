# Evals — @parisgroup-ai/claude-statusline

Suíte de avaliação automatizada baseada na especificação `harness-evals` (ADR-0008).

## Casos Golden Grounded

1. `statusline-rich-render-contract.json`: Valida renderização completa da statusline com modelo, context-window %, custo e separadores.
2. `statusline-degraded-fallback-contract.json`: Valida degradação graciosa com payload vazio/parcial para `Claude Code` e `$0.00`.

## Execução

```bash
pg-devkit eval run
# ou diretamente
bash evals/run.sh
```

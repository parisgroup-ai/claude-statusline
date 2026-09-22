<!-- global-adrs-digest: auto-generated. Do not edit directly. -->

# Global Architecture Decisions (Digest)

- **ADR-0001**: Evidence before assertions; run gate suite and check actual output before asserting completion. (`pg-devkit adr view ADR-0001`)
- **ADR-0002**: A single canonical test runner is mandatory; legacy runners (jest/mocha) are disallowed across TypeScript projects. (`pg-devkit adr view ADR-0002`)
- **ADR-0006**: Agent context files must stay strictly under fixed byte budgets (CLAUDE.md <=500B, AGENTS.md <=24K). (`pg-devkit adr view ADR-0006`)
- **ADR-0008**: Production AI prompt pipelines must define automated regression test harnesses with golden eval cases. (`pg-devkit adr view ADR-0008`)
- **ADR-0010**: System architectures and workflows must be documented as interactive self-contained HTML diagrams. (`pg-devkit adr view ADR-0010`)
- **ADR-0011**: Non-trivial multi-step tasks must be tracked with explicit statuses and verification evidence. (`pg-devkit adr view ADR-0011`)
- **ADR-0014**: Daily engineering sessions must open and close with verifiable work evidence synced to goals. (`pg-devkit adr view ADR-0014`)
- **ADR-0015**: Repositories must run continuous health loops to detect dependency obsolescence and config drift. (`pg-devkit adr view ADR-0015`)
- **ADR-0018**: Agent instructions and capabilities must be declared once in devkit config and materialized across target runtimes. (`pg-devkit adr view ADR-0018`)
- **ADR-0019**: Performance and prompt tuning must follow autonomous closed loops with objective scoring and auto-revert on regression. (`pg-devkit adr view ADR-0019`)
- **ADR-0021**: Structural codebase queries and refactors must verify dependency graphs and enforce drift gates against regression. (`pg-devkit adr view ADR-0021`)
- **ADR-0023**: Fleet apps call gateway models only via pg-* aliases (incl. pg-stt/tts/image); swaps are infra-side env changes, never consumer code. (`pg-devkit adr view ADR-0023`)

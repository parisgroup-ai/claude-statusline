<!-- pg-frota:inicio v2 -->
## Regras da Paris Group (frota v2)

Bloco do `pg-devkit regras` (fonte: `packages/baseline/regras-frota.md` no pg-devkit); não edite aqui. Toda IA segue este bloco: Claude, Codex, Gemini, Grok, Cursor, Copilot e as outras. O resto deste arquivo traz as regras do produto; elas valem quando forem mais específicas.

### Ao começar a sessão
1. Rode `pg-devkit --version`. Se não existir, instale você mesmo. O token fica só no ambiente, nunca em argumento, arquivo ou chat:
   ```sh
   rc="$(mktemp)"; printf '%s\n' '@parisgroup-ai:registry=https://npm.pkg.github.com' '//npm.pkg.github.com/:_authToken=${NODE_AUTH_TOKEN}' > "$rc"
   NODE_AUTH_TOKEN="$(gh auth token)" NPM_CONFIG_USERCONFIG="$rc" npm i -g @parisgroup-ai/pg-devkit; rm -f "$rc"
   ```
   Nunca use `npx pg-devkit` nem um pacote `pg-devkit` sem escopo: esse nome não é nosso.
2. Depois rode `pg-devkit doctor`. Nunca peça comandos ao humano. A única exceção: erro E401 ou E403 de pacote. Aí peça uma vez: "Rode `gh auth refresh -h github.com -s read:packages` e me avise."
3. Leia a caixa de entrada: `pg-devkit caixa`.
4. Se algo falhar (sem rede, sem `gh`, sem cota), não pare a tarefa. Siga este arquivo e avise numa linha no fim.
5. Padrão Paris v1 (11 itens, com a nota no Mission Control): `pg-devkit padrao` mostra o que falta neste repo.

### Dono e rota (regras 1 e 2)
- Dono é medido: quem fez 1/3 ou mais dos commits da branch padrão em 90 dias, sem robô nem pin (a `rota` calcula). `donos:` no `devkit.config.yaml` é opcional e vence. CODEOWNERS e times do GitHub não valem. Sem dono: vale o time `leads`.
- Robô e agente nunca entram em `donos:`.
- Antes de subir, rode `pg-devkit rota`. Ela responde DIRETO, PR, ISSUE ou PULAR_E_AVISAR, e para quem. Sem o dono na sessão, some `--agente-sozinho`; algo que não se desfaz, `--irreversivel`; pedido sem código, `--tipo pedido`.
- O dono, ou a IA dele, vai direto na branch padrão depois dos gates. Quem não é dono abre PR, e só o dono ou a IA dele faz o merge. Pedido sem código vira issue.
- A proteção do servidor vence: se ela exige PR, abra o PR.
- Antes do push: `git pull --rebase`. Nunca `--force`. Nunca pule os hooks, de nenhum jeito (`--no-verify`, `-n`, `HUSKY=0`, `SKIP=`, `core.hooksPath`). Hook lento ou falhando: conserte, ou `pg-devkit caixa abrir`. Nunca `gh run cancel`: o CI de outra sessão não se cancela.
- Revert puro sempre vai direto, pelos gates normais, nunca com checagem mais forte (`--tipo revert`).

### Gates (regra 3)
- Nada chega à produção sem um portão automático antes. Mudança arriscada (migration, RLS, auth, dinheiro, contrato público, gates, `donos:`) ganha checagem automática mais forte, nunca uma pessoa a mais.
- Migration só pelo script do repo que faz lint, ensaio e registro. Segredo nunca entra no código. Feature nova declara `Rollout:` no commit.
- Teste instável vira issue e nunca é apagado.
- Commit só de docs não faz deploy.

### Agente sozinho (regra 4)
- Sem o dono na sessão (daemon, `claude -p`, nuvem), siga a política de decisão escrita do produto.
- Nunca faça sozinho o que não se desfaz: re-parear ou deslogar WhatsApp, envio em massa, verba, apagar dados, trocar chave, env ou DNS, afrouxar um gate ou mudar `donos:`. Avise o dono por uma issue na caixa, sem esperar resposta: `pg-devkit caixa abrir "<o que foi>"` mostra o comando pronto, sem duplicar e com os donos marcados. Pule a tarefa e siga. Nunca acorde ninguém.

### Atualização e máquina (regras 5 e 7)
- Atualizar pacote é trabalho do zelador no GitHub, nunca da sua sessão: não rode `npm install` por causa de update.
- A sessão nunca altera arquivo gerenciado que está no git (worktree, VPS, repo de outro dono). Só lê e avisa numa linha.
- `estado: congelado` e `congelados:` travam atualizações. Segurança sempre passa.

### Regras na raiz (regra 6)
- Este `AGENTS.md` é a fonte única. `CLAUDE.md`, `GEMINI.md`, `.cursor/rules/pg.mdc` e `.github/copilot-instructions.md` só apontam para cá.
- Limite de 24 KB por `AGENTS.md`, na raiz e nas subpastas. O excesso vai para `docs/`, com link.
- Regra que protege o produto mora aqui, não na memória de uma IA. O repo vence a regra pessoal.
- Decisão diferente do padrão vai em `excecoes:` no `devkit.config.yaml`, com o link da ADR.

### Pedir para cima (regra 8)
Problema na plataforma vira issue (ou PR) no repo dono do assunto:

| Assunto | Repo |
|---|---|
| pacote `@parisgroup-ai/x` | pg-platform, se lá existir `packages/x`; senão, o repo de mesmo nome |
| skill e CLI | pg-devkit |
| hospedagem, segredos, LiteLLM, Keycloak | infra |
| tela ou dado do Mission Control | platform |
| na dúvida | pg-devkit |

Mande só uma reprodução mínima e o link do repo de origem. Nunca código, dado, print ou nome de cliente.

### Caixa de entrada e avisos (regra 9)
- O que a Paris precisa deste projeto vira issue aqui, com a etiqueta `paris:caixa` (precisa do dono). `pg-devkit caixa` mostra essas issues e os PRs da org que esperam a sua revisão.
- Para abrir um pedido aqui ou em outro repo: `pg-devkit caixa abrir "<o que foi>" [--para <repo>]`.
- Chame o dono na hora só por produção parada, dinheiro saindo, decisão pendente ou segurança, uma vez por dia por assunto. Parceiro e cliente recebem pela caixa.

### Agentes, Mission Control e Vordin (regras 10 a 12)
- Todo repo da parisgroup-ai aparece no Mission Control. Se o `pg-devkit doctor` disser que não, avise numa linha: os leads já têm a tarefa.
- Todo agente e serviço, em qualquer conta (Railway, VPS, conta pessoal), fica no `.pgdk/agents.yaml` e manda batimento, com o slug do produto dono, e resultado ao Mission Control pelo contrato HTTP. Sem token, nada é enviado. Teste local nunca grava no MC. MC fora do ar nunca trava o agente.
- Entrega só conta como verificada se quem confere não é o próprio agente.
- O Vordin é o CRM único. Vai para lá só lead ou cliente em negociação real; prospecção fria e o cliente do cliente ficam no produto. Antes de mandar mensagem, consulte "não contatar". Número oficial de WhatsApp nunca é pareado em Baileys.
- Site e anúncio entram pelo `/api/leads/intake` do Vordin.
- Adoção é medida por projeto, nunca por pessoa.
<!-- pg-frota:fim -->

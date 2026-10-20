# Changelog — schematize-rust

Todas as mudanças relevantes deste pacote, no formato [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
com versionamento [SemVer](https://semver.org/lang/pt-BR/).
## [1.14.1] — 2026-10-20
### Alterado
- Bloco herdado `engineering/iam-desenho:invariantes` sincronizado: passkey padrão na fase 0 e matriz de acesso por rota.


## [1.14.0] — 2026-10-14
Gates de script com vermelho plantado, bugs reais achados por eles corrigidos e IAM/Postgres/API apontando para as skills donas.

### Corrigido
- `test-skeleton.test.sh`/`smoke-selfcheck.test.sh`: o `trap` de limpeza vira função com `p` local (fim do SC2154); scripts no piso de shell.
- `scripts/archive-secret-scan.sh`: a regra de `password=` usava `[^ \n"']` — em ERE `\n` dentro de colchete é a letra `n`, então qualquer senha com `n` (quase todas) passava em branco. Agora `[^ "']`.
- `scripts/check-diff.sh`: a regra de CORS `*` não pegava a forma canônica `Set("Access-Control-Allow-Origin", "*")` (faltava a vírgula na classe); base inexistente (`origin/main` ausente) virava "OK" por diff vazio — agora BLOQUEIA com mensagem.

### Adicionado
- Testes com vermelho e verde plantados (segredos falsos montados em tempo de execução, repos e servidores em `mktemp`): `archive-secret-scan.test.sh`, `check-diff.test.sh` (cada regra do piso + isenções + base inválida), `smoke-selfcheck.test.sh` (inclui o runner cego: `--self-check` tem que sair 1), `test-skeleton.test.sh`. O gate `check-skill` da skill-dev exigia (`script-sem-teste`); `lib.sh` fica isento.

### Alterado
- Description reduzida a ≤190 caracteres (orçamento do catálogo com 45 skills), mesmo território.
- `references/iam.md`: topologia, fluxos, sessão, migração de legado e risco adaptativo viram piso curto + ponteiro `schematize-iam → references/*.md` (a skill dona); fica o recorte de linguagem (providers, guard de efeito externo, PEP, libs).
- `references/dados-eventos.md`: ponteiro para `schematize-postgres` (migrations, pool, EXPLAIN) e `schematize-api` (contrato); fica só o específico do `sqlx`.

## [1.13.1] — 2026-10-14
Ressincronização dos blocos herdados com a engineering v0.27.0; sem mudança de piso próprio.

### Alterado
- Description reduzida (≤235 chars) para caber no orçamento de listagem de skills (soma ≤8300); mesmo território, fronteiras com as irmãs preservadas.
- Blocos herdados ressincronizados com a `schematize-engineering` v0.27.0 (`tools/sync-herdados.mjs`): orquestração com a regra de imagem (nunca pelo Claude; detecta Codex/Gemini e pergunta ao usuário qual usar, Codex como sugestão) e `schematize overdev delegar` (comando do app) no lugar do falso nome de skill `schematize-overdev`.

## [1.13.0] — 2026-10-14
Saneamento da skill: Rust deixa de ser "principal, com Go auxiliar" — é uma linguagem do rol sancionado, por fit + ADR — e o lint/CI passam a ser de Rust.

### Adicionado
- `assets/lint/clippy.toml` (thresholds: complexidade 15, aninhamento 4, `unwrap` só em teste), `assets/lint/Cargo.lints.toml` (bloco `[lints]` com `unsafe_code = "forbid"` e os lints `unwrap_used`/`expect_used`/`panic`/… que `stack-rust.md` exige) e `assets/lint/deny.toml` (cargo-deny: advisories, licenças, bans, fontes) — validados com clippy e `cargo-deny` reais.
- CI: `cargo fmt --check`, `clippy -D warnings`, `cargo nextest` + doctests, `cargo deny`, job `sqlx prepare --check`; `INDEX_SRC` default `./src`; Trivy/Gitleaks/checkout pinados por SHA (sem `@master`).

### Alterado
- Description reescrita (≤350 chars) ancorada em Rust (`Cargo.toml`, cargo, clippy, tokio/axum, sqlx); `skill.toml`: tag e descrições pt/en/es só de Rust.
- `SKILL.md` e `references/stack-rust.md`: fim do "Rust principal, Go auxiliar" — Rust entra por fit (auth, cripto, parsing hostil), sem ADR obrigatório "para escolher Go"; Go aponta para `schematize-go`. `references/iam.md` e READMEs idem.
- Piso "Backend novo só em Go ou Rust" (`assets/CLAUDE.md`) e `references/arquitetura.md` (§3.1/§3.2) alinhados ao rol sancionado; PHP migra por funcionalidade quando tocado.
- Hash de senha: argon2id-only para senha nova, com ponteiro para `schematize-engineering` → `references/iam.md`; `assets/CLAUDE.md` com equivalentes Rust no lugar de `Math.random`/`catch {}`/`@ts-ignore`.
- Tabela de comandos completa (`/rust-load`, `/rust-claude`); mapa de references inclui `stack-versoes.md`; segurança de deps via `cargo deny` com `deny.toml` (`cargo audit` redundante).
- Herdados parametrizados da base (`schematize-engineering` → `assets/herdados/`): os blocos "Precedência e herança", "Fluxo de ambientes e ops", "Deploy destrutivo", "Efeito externo" e "IAM por desenho" passam a ser gerados por `tools/sync-herdados.mjs` (lead específico de cada linguagem fica fora do bloco); `references/contexto-claude-code.md` e `scripts/check-external-effects{,.test}.sh` viram arquivos herdados (convenção do archive corrigida para `<projeto>/<projeto>_archive`; só a engineering é dona do handoff). A frase do step-up (senha + Email OTP = 2FA baseline, AAL alto só por rota sensível) vira regra comum do IAM.

### Removido
- `assets/lint/.golangci.yml` (config Go v1 dentro da skill Rust) e `assets/lint/eslint.layers.cjs`.
- **Description** reduzida (~270 chars) para caber no orçamento de listagem (soma das 31 skills ≤ 8500; o Claude Code corta a listagem acima disso).
- **CI:** actions de terceiros pinadas por SHA completo com comentário `# vX.Y.Z` (mesma major em uso; supply chain), mesmo SHA em todas as skills.

## [1.12.2] — 2026-09-30
O piso de orquestração passa a ser **herdado** da base em vez de copiado à mão: uma mudança na engineering não exige mais editar 38 arquivos.

### Alterado
- Piso "Orquestrador não desenvolve; subagent barato executa" em `assets/CLAUDE.md` e `SKILL.md` agora é um bloco `<!-- herdado:engineering/orquestracao:… -->`, sincronizado de `schematize-engineering/assets/herdados/orquestracao.md` por `tools/sync-herdados.mjs` (checado no CI). Redação normalizada; conteúdo inalterado.

### Mantido (piso inalterado)
- Sonnet por default, escada até opus, sem frota ociosa (engineering `references/orquestracao.md` §9/§9.6).

## [1.12.1] — 2026-09-30
Pedido do dono: agents idle poluem a tela e seguram recurso.

### Adicionado
- Piso de orquestração ganha a regra de frota ociosa (idle com pendência volta ao trabalho; dependente de outro agent → mata e enfileira com gatilho; terminou → mata); detalhe na `schematize-engineering` §9.6.

## [1.12.0] — 2026-09-30
Orquestração por papéis e escada de modelo (custo). Pedido do dono: o orquestrador em modelo padrão não desenvolve; ações onerosas viram micro-tasks baratas; `sonnet` é o default nos subagents e `opus` só após falha.

### Adicionado
- **Piso 18 no `assets/CLAUDE.md` e bullet nos pisos do `SKILL.md`: "Orquestrador não desenvolve; subagent barato executa"** — o agent principal só planeja, decompõe, despacha, supervisiona e revisa; subagents em `sonnet` por padrão; falhou → o mesmo subagent corrige (até 2 rodadas) → re-decompõe → só então `opus`, com o motivo no checkpoint. Normativa na `schematize-engineering` → `references/orquestracao.md` §9 (não duplicada aqui).
- **Recorte overdev:** no laço, cada item do checklist é executado por subagent `sonnet` e revisado pelo principal (diff + gate) antes do `- [x]`; escalar para Opus não é pergunta, esgotou Opus → `park`.

### Mantido (piso inalterado)
- Todos os pisos anteriores (segurança, IAM, efeito externo, archive, ops) seguem como estavam; a §9 escolhe **quem executa**, não relaxa **o que** se exige. Paralelizar para o relógio continua o padrão.

## [1.11.0] — 2026-08-21
Saneamento do catálogo conforme a vistoria de 2026-08-21.

### Adicionado
- **`edition = "2024"`** e **MSRV declarado e testado no CI** (`references/stack-rust.md`) — *sem um job que compile no MSRV, ele é intenção*.
- **A condição que o `sqlx` impõe ao CI**, que faltava: as macros exigem `DATABASE_URL` no build **ou** `.sqlx/` commitado; sem uma das duas, o primeiro build num runner sem banco **falha na compilação, não no teste**. A casa escolhe `.sqlx/` commitado, com `cargo sqlx prepare --check` no CI para ele não envelhecer.
- **`block_in_place` vs `spawn_blocking`** (`references/async-concorrencia.md`), com as duas restrições que doem em produção: `block_in_place` **entra em pânico no runtime current-thread** (e `#[tokio::test]` é current-thread por default) e tira aquele worker do jogo.

### Corrigido
- **`#![forbid(unsafe_code)]`**, não `deny` — `deny` é reabrível por um `#[allow]` local, e piso que qualquer arquivo reabre não é piso. Verificado compilando: `deny` + `allow` local **compila**; com `forbid`, `error[E0453]`.
- **Os lints que a skill exige agora estão LIGADOS:** `-D clippy::unwrap_used` e companhia (preferindo `[lints.clippy]` no `Cargo.toml`, que viaja com o repo). `-D warnings` sozinho **não** liga nenhum deles — são `restriction`/`pedantic`, desligados por default. Verificado com um `.unwrap()` plantado: sem a flag, exit 0.
- **`MutexGuard` através de `.await`**: o texto dizia "deadlock esperando"; o que acontece é que `std::sync::MutexGuard` **não é `Send`** e a future nem compila quando vai para `tokio::spawn` — com o reflexo errado nomeado (trocar por `tokio::sync::Mutex` só para calar o compilador faz compilar e devolve o deadlock, agora silencioso).

### Mudado
- `anti-padroes.md`, `arquitetura.md` e `entrega.md` viraram **ponteiro** (poda mecânica dos blocos idênticos à base).

## [1.10.0] — 2026-08-20
Piso "efeito externo NUNCA sai de não-produção" no recorte **Rust** — o guard idiomático, com código pronto pra copiar.

### Adicionado
- **`references/iam.md` §3.1 — "Efeito externo fora de prd — o guard mora DENTRO do provider (recorte Rust)":** módulo `src/platform/mail` completo — `Message`, `trait EmailProvider` (async, `dyn`-compatible via `async_trait`), `MailError` com **`thiserror`** (`ExternalRecipientBlocked` / `RunCapExceeded` / `Transport`), `Env` + `Env::from_raw` **fail-closed** (variável ausente/desconhecida ⇒ não-prd), `SinkProvider` (Mailpit/`tracing`, default fora de prd) e `ResendProvider` (só em prd, erro do SDK mapeado pra não acoplar o core).
- **Guard como wrapper genérico** `Guarded<P: EmailProvider>`: deny-by-default no destinatário (domínio de teste ou subdomínio dele; endereço malformado também recusa), devolve **`Result<(), MailError>`** (nunca `warn!` + `Ok(())`), **cap por execução em `AtomicUsize`** (`MAIL_MAX_PER_RUN`, default 50 quando `max_per_run == 0`), mensagem de erro que **ensina o caminho certo**, e `redact()` pra não vazar PII em log/erro. **Sem `unwrap()`/`expect()`.**
- **Seleção do provider por `env` na composição**: `build_email_provider(cfg) -> Arc<dyn EmailProvider>` — o caso de uso recebe a trait por injeção, não conhece ambiente e **não existe `force`/`skip_guard`**.
- **Testes que veem o vermelho:** `#[tokio::test] guard_recusa_dominio_externo` (em `Env::Hml`, `@gmail.com` ⇒ `Err(MailError::ExternalRecipientBlocked)` e `SpyProvider` com 0 chamadas) e `guard_aborta_ao_estourar_o_cap` (3º envio com cap 2 ⇒ `RunCapExceeded`).
- **Piso inegociável na `SKILL.md`** + linha no mapa de references apontando pro §3.1, com a normativa na `schematize-engineering` → `references/efeitos-externos.md`.
- **`assets/CLAUDE.md`: piso 17** (efeito externo nunca sai de não-prd) e menção na Definition of Done.
- **Checklist do `references/iam.md`**: item de DoD do sink/guard/cap/domínio de teste/chave sandbox provado por teste.

## [1.9.2] — 2026-08-18
Correção da contradição do muro pré-login de IAM (alinha ao `iam.md` da schematize-engineering).
### Mudado
- **/rust-iam**: removido o "2º fator forte obrigatório antes do acesso pleno" e o "força 2º fator no 1º login" — o muro pré-login / deadlock de bootstrap VETADO pela norma. Agora senha+Email OTP = 2FA baseline; fator forte é nudge + step-up just-in-time.
aqui **Rust é a linguagem principal de backend e Go a auxiliar**. Frontend delega
ao `schematize-web`.

## [1.9.1] — 2026-08-18
Q.A. repointado para a skill dedicada **schematize-qa**.

### Mudado
- **`/rust-qa` virou wrapper fino** da **schematize-qa** (`/qa-plan` → `/qa-run`) no recorte Rust (`cargo test`/`cargo nextest`). Referências ao antigo **§22.9** removidas de `SKILL.md`, `references/testes*.md`, `assets/CLAUDE.md` e `/rust-help`.

## [1.9.0] — 2026-08-15
Correção de desenho no IAM backend — **senha + Email OTP já é 2FA baseline** (o middleware/PEP não barra mais o login) + **risk engine adaptativo robusto**.

### Mudado (correção de piso)
- **`references/iam.md` §3/§4/§7 + roadmap + checklist:** senha + Email OTP conta como **2FA baseline** desde o cadastro; o **middleware/PEP libera o acesso baseline** e exige AAL alto **só por rota sensível** (step-up just-in-time, `403 step_up_required`), **nunca barra o login** por falta de fator forte — fim do **círculo infinito**. Fator forte é **nudge + just-in-time**. Migração ativa o Email OTP always-on como 2º fator baseline (sem muro).

### Adicionado
- **Autenticação adaptativa por risco (robusta)** (`references/iam.md` §9): log de sessões/tentativas + **score** (IP/ASN, device novo, geovelocidade, velocity, honeypot); **escalonamento 2FA→3FA** sob risco (senha → email → app/chave); **negação deceptiva/tarpit** (falso negativo sob suspeita — resposta idêntica ao erro real em **tempo constante**, estado "próxima passa" curto/escopado a conta+IP+device, soma-se ao 3FA, nunca trava o legítimo); **honeypot**; notifica login suspeito + "não fui eu".

## [1.8.0] — 2026-07-11
IAM por desenho (angle Rust) — identidade + autorização robustas, auth como microserviço Rust separado.

### Adicionado
- **`references/iam.md`** — piso de IAM da casa especializado para **backend Rust**: **auth é app SEPARADA** — microserviço Rust `<projeto>_auth_rs` (axum/actix sobre Tokio) + front próprio em `auth.<domain>`, isolado (user/systemd próprios; nunca monolith; apps delegam por OIDC/OAuth2.1 + PKCE; chave de assinatura só no auth, JWKS público via `jsonwebtoken`/`josekit`). **ID interno imutável (ULID/UUIDv7) — email/telefone nunca é ID** (schema `users` + `identifiers` 1..N; N emails por usuário incentivado; SSO com recuperação local forçada; nudge de email secundário com detecção de provedor + tooltip). **≥2 fatores sempre** (AAL/NIST 800-63B): **passkey/WebAuthn no núcleo** (`webauthn-rs`), TOTP/push (`totp-rs`), **email OTP Resend always-on inclusive HML**, **Twilio** p/ telefone (providers plugáveis por trait); senha por padrão (**argon2id** via crate `argon2` em `spawn_blocking` + HIBP) mas opcional no seletor; invariante de troca "fator Y≠X no maior AAL"; **recuperação ≥ força do login**. **Multi-tenant RBAC/ABAC granular via ReBAC** (OpenFGA/SpiceDB): deny-default, **PEP como `tower` layer/extractor**, enforcement server-side, token fino, decisão auditada. **Multi-dispositivo** + view de remover; **sessão 7d/90d** (fim do "15 min e é chutado"); **logout irreversível** (revoga refresh+família, `jti` na denylist Redis/DB, apaga sessão server-side, não só cookie). **Migração de auth legado = prioridade 0** (strangler-fig, re-hash preguiçoso → argon2id). Rotina agressiva de testes cross-tenant/priv-esc (schematize-pentest).
- **Comando `/rust-iam`** (plan-first): força/audita/scaffolda o IAM num projeto (bootstrap como microserviço Rust) ou porta um auth legado (migrate).
- **Piso 16** no `CLAUDE.md`; bullet nos pisos + linha na tabela de references + `/rust-iam` na tabela de comandos do `SKILL.md` (incl. `description:` do frontmatter); anti-padrões **43–46** (auth monolith; email como ID / 1 fator; authz hand-rolled/no cliente; logout que só apaga cookie); `/rust-load` carrega `iam.md`; `/rust-help` lista `/rust-iam`.

## [1.7.0] — 2026-07-11
Limite de arquivo em camadas — teto de 750 (≤500 úteis + ~250 comentário) + flag em >300 úteis.

### Alterado
- **`references/padroes-codigo.md` §1/§2:** o limite rígido de **300 linhas/arquivo** vira regra **em camadas**. **Teto DURO: 750 linhas** (das quais **~250 reservadas a comentário/doc** e **até ~500 de código útil**) — acima bloqueia. **FLAG (não bloqueia, mas SEMPRE sinaliza) em > 300 linhas de código útil:** indício de que a função está **muito extensa** / **precisa de mais abstração** — registra como dívida e **revê quando as prioridades forem resolvidas**. **Observabilidade tem folga natural (~400 úteis).** Função com >300 úteis dispara o mesmo flag; "uma função por arquivo" mantida.
- **`scripts/check-diff.sh`:** o gate de tamanho passa a contar **código útil** (exclui comentário/branco): `total > 750` **bloqueia**, `útil > 500` **bloqueia**, `útil > 300` (ou `> 400` em arquivo de observabilidade) **flagueia** (`warn`, não trava).
- Propagado no piso do `CLAUDE.md`, `SKILL.md` (incl. `description:`), `references/entrega.md` (DoD), `references/arquitetura.md` (§6), `references/stack-rust.md` e comandos `/rust-load` `/rust-help` `/rust-review`.

## [1.6.0] — 2026-07-06
Deploy destrutivo por seed + isolamento por usuário (ops).

### Adicionado
- references/ops.md §2: layout /<app>/ + repos dentro; /<app>/.env seeder global; redeploy destrutivo na app (preserva dados; ops reset gated dev/hml).
- references/ops.md §3: isolamento por usuário (user Linux + systemd hardened por serviço).
- Piso de seed/isolamento no CLAUDE.md; anti-padrões; /rust-ops audita layout/seed/isolamento.

## [1.5.0] — 2026-07-05
Control plane <projeto>_ops: fluxo de ambientes, ops interface única, instalação paralela, independência invariante.

### Adicionado
- references/ops.md: fluxo dev→local→github→hml→prd (nada direto no servidor), ops interface única (100%, autônomo), instalação paralela=nproc, independência invariante (falha no paralelo = serviços não independentes → prioridade máxima).
- Comando /rust-ops; pisos de ambientes/ops no CLAUDE.md; anti-padrões (editar no servidor, pular pra hml/prd, operar fora do ops, instalar serial, serializar pra mascarar); operacao.md §21 estendido; /rust-load carrega ops.md.

## [1.4.0] — 2026-07-05
Todo MD gerado no archive, root limpo.

### Corrigido
- MAPA/índice saíam no root → agora `<projeto>_archive/index/` (padroes-codigo §4, MAPA.md, /rust-index, build-index.mjs, CLAUDE.md, SKILL.md).

### Adicionado
- §28.0 (operacao.md): layout canônico do archive — todo MD gerado em `<projeto>_archive/<área>/`, NUNCA no root.

## [1.0.0] — 2026-06-20
Primeira release do **schematize-rust** — padrões normativos de engenharia da casa
com Rust como escolha padrão de backend e Go como auxiliar.

### Adicionado
- Conhecimento normativo fatiado em `references/` (stack Rust/Go, async/concorrência
  com Tokio, padrões de código, arquitetura, dados/eventos, segurança, cadeia de
  suprimentos, testes/pentest, observabilidade, operação/entrega, anti-padrões,
  contexto Claude Code).
- Comandos: `/rust-help`, `/rust-cc`, `/rust-handoff`, `/rust-qa`, `/rust-review`,
  `/rust-index` — prefixados por `rust-`, **sem conflito** com `schematize-go`
  (`go-*`) e `schematize-web` (`web-*`) na mesma máquina.
- Scripts: `lib.sh`, `test-skeleton.sh`, `smoke-selfcheck.sh`, `simulated/run.py`,
  `build-index.mjs`, `check-diff.sh`, `archive-secret-scan.sh`, hooks de contexto.
- Assets: `CLAUDE.md`, templates (ADR/TASK/CHAT/PR/RUNBOOK/MAPA/INDEX_*),
  `settings.claude.example.json`, CI (`ci/`), lint (`lint/`), pre-commit (`hooks/`).

### Pisos inegociáveis cobertos
- Backend novo prioriza **Rust** (Tokio/axum, sqlx); **Go é auxiliar** (decisão em ADR);
  Node backend e PHP proibidos; frontend Node permitido (ver `schematize-web`).
- Segredo nunca no cliente; SQL parametrizado (`sqlx`/binds, nunca `format!` em SQL);
  auth/authz server-side; JWT validado por inteiro.
- Erro nunca engolido (`let _`/`.unwrap()`/`.expect()` em produção vetados); trate
  `Result`/`Option` de verdade.
- Async correto (Tokio): não bloquear o runtime, cancel-safety em `select!`, locks
  nunca cruzando `.await`, backpressure, graceful shutdown.
- Pisos de código: arquivos ≤300 linhas, uma função/arquivo, doc-comment (`///`)
  obrigatório, `MAPA.md` e índice de microfunções atualizados.
- Cadeia de suprimentos: lockfile, SBOM, scan que trava (cargo audit/deny), imagem
  mínima/pinada por digest/não-root/assinada (cosign), SLSA.
- Archive obrigatório (§28); migration reversível; Q.A. plan-first (§22.9);
  handoff de contexto (§34.1).

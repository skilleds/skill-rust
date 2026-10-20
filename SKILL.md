---
name: schematize-rust
metadata:
  version: 1.14.1
description: >-
  Backend em Rust: arquitetura, IAM, testes, dados, deploy. Use ao projetar ou revisar Cargo.toml, clippy, tokio/axum, sqlx: serviço, API, worker, CLI. Entra por fit + ADR.
---

# Padrões de Engenharia da Casa — recorte Rust

Conjunto normativo que rege como software de backend é projetado, construído, testado e operado aqui, no recorte **Rust**. Mesma base normativa das demais skills da casa; o que muda é o ferramental (cargo, clippy, cargo-deny, Tokio/axum, sqlx) e as armadilhas do dialeto.

**Versão:** skill `schematize-rust` v1.14.1. Changelog em `CHANGELOG.md`.

## Linguagem: Rust é uma do rol, por fit + ADR

- **Rust entra por fit**: correção e segurança de memória críticas — auth/IdP, criptografia, **parsing de entrada hostil**, protocolos binários — e onde o time domina a stack. A escolha vira ADR de fit, como a de qualquer linguagem do rol (`schematize-engineering` → `references/linguagens.md`; o desempate pragmático mora lá, não aqui).
- **Node backend e PHP são legado/fora do rol** — não recebem serviço novo (frontend Node é `schematize-web`). Migração por funcionalidade do módulo, nunca big-bang.
- **Outra linguagem do rol** no mesmo sistema segue a skill irmã dela (Go → `schematize-go`). Detalhe e toolchain em `references/stack-rust.md` e `references/arquitetura.md` (§3).

> Esta skill é o **recorte Rust** do rol sancionado da casa (Go, Rust, Elixir, C#, Zig, Ruby).
> Não há hierarquia entre as irmãs: aqui a stack é Rust, e ponto. Todas podem coexistir na mesma
> máquina — os comandos são namespaced por skill (ver abaixo).

## Precedência e herança (leia antes de divergir)

<!-- herdado:engineering/precedencia:backend linguagem="Rust" -->Esta skill é o **recorte Rust** da base. Duas regras governam a relação, e elas resolvem sozinhas
quase toda dúvida de "onde está escrito o quê":

1. **Onde esta skill divergir da base, a BASE MANDA.** `schematize-engineering` é a normativa; aqui
   mora a **especialização** — o mecanismo, a lib, a sintaxe, o gate da linguagem. Divergência de
   *piso* entre este arquivo e a base é **defeito desta skill**, não uma variante local aceitável.
   Achou uma? É item de correção, não licença. *(Foi assim que o `argon2id-only` da casa virou
   "argon2id ou PBKDF2" em uma skill só, e o rol de 6 linguagens virou "só Go e Rust" em três.)*
2. **O que não está repetido aqui é HERDADO, não dispensado.** A ausência de um piso neste repo
   nunca significa que ele não vale — significa que ele não muda de forma nesta linguagem. Em
   especial, valem integralmente, sem cópia local:
   - **§28 Archive** — `<projeto>/<projeto>_archive/` é **repositório git próprio, PRIVADO e
     obrigatório**, criticidade 0 (`schematize-archive`; ADR-0005 para a planta canônica).
   - **§39 Índice/MAPA** — enumeração exaustiva (uma entrada por unidade chamável, `M == N`) e o
     **grafo com arestas em ASCII (`A -> B`), NUNCA a seta unicode** — o parser do app lê ASCII.
   - **§35 Definition of Done** e a lista de anti-padrões **§37** (citada por **título**, nunca por
     número: a numeração dos itens diverge entre skills).
   - **IAM** (`schematize-engineering` → `references/iam.md`): identidade ≠ email, ≥2 fatores, ReBAC multi-tenant,
     **alcançabilidade do 2º fator** (o fator de recuperação tem de ser alcançável quando o
     principal cai — senão o 2FA vira bug de bootstrap que tranca o dono para fora), os parâmetros
     mínimos de argon2id, sessão longa e logout irreversível.
   - **Rol sancionado** — Go, Rust, Elixir, C#, Zig, Ruby, por **fit + ADR**
     (`schematize-engineering` → `references/linguagens.md`). Esta skill é **uma** delas, não a
     régua das outras.
   - **Efeito externo** nunca sai de não-produção (`schematize-engineering` →
     `references/efeitos-externos.md`; gate em `scripts/check-external-effects.sh`, distribuído
     aqui — ADR-0008).<!-- /herdado -->

## Comandos (Claude Code)

Digite `/rust-help` pra ver todos. Em resumo:

| Comando | O que faz |
|---|---|
| `/rust-help` | lista todos os comandos do schematize-rust |
| `/rust-load` | carrega à força TODO o corpo normativo no contexto e passa a aplicá-lo no projeto atual |
| `/rust-claude` | cria ou atualiza (com backup) o `CLAUDE.md` da raiz; mescla/avisa se detectar `CLAUDE.md` de outra skill |
| `/rust-cc` | context compact: gera context.md + checklist.md no archive e roda `/compact` |
| `/rust-handoff` | gera o handoff (context.md + checklist.md) **sem** compactar — pra fim de sessão |
| `/rust-qa` | Q.A. no contexto Rust — wrapper fino da skill **schematize-qa** (`/qa-plan` → `/qa-run`) com `cargo test`/`cargo nextest` |
| `/rust-review` | roda o gate da DoD no diff (arquivo >750 bloqueia / >300 úteis flag, função sem doc, MAPA, índice, macaquices) |
| `/rust-iam` | força/audita/scaffolda o IAM da casa (auth como microserviço Rust separado, ID≠email, ≥2 fatores, ReBAC multi-tenant, sessão longa/logout irreversível) ou migra um auth legado |
| `/rust-index` | (re)gera o índice de microfunções a partir dos doc-comments |
| `/rust-ops` | audita/scaffolda o `<projeto>_ops` (interface única): fluxo de ambientes, instalação paralela (`nproc`), independência |

Todos os comandos são prefixados com o slug da skill (`rust-`), então **convivem sem conflito** com as skills irmãs do rol (`go-*`, `elixir-*`, `cs-*`, `zig-*`, `ruby-*`) e com `schematize-web` (`web-*`) na mesma máquina. Ficam em `assets/commands/` e são instalados em `.claude/commands/`.

## Como usar esta skill

1. Identifique o domínio da tarefa e **leia o(s) reference(s) relevante(s)** antes de produzir código ou decisão. Não trabalhe de memória.
2. **Sempre** aplique os pisos inegociáveis abaixo, independente do reference carregado.
3. Ao terminar, valide contra a Definition of Done (`references/entrega.md`, §35) e **gere o archive** (§28, `references/operacao.md`).

Mapa de references — leia o que casa com a tarefa:

| Tarefa | Reference |
|---|---|
| **Stack Rust: fit, toolchain, lints (`assets/lint/`: `Cargo.lints.toml`, `clippy.toml`, `deny.toml`), cargo-deny** | `references/stack-rust.md` |
| **Async/concorrência (Tokio): não bloquear o runtime, cancel-safety, locks, backpressure, shutdown** | `references/async-concorrencia.md` |
| **Limites de código (arquivo ≤750: ~500 úteis + ~250 comentário; flag >300 úteis), uma função/arquivo, comentários, MAPA** | `references/padroes-codigo.md` |
| Arquitetura, camadas, DDD, repositórios, anti-monólito, shared libs, CQRS | `references/arquitetura.md` |
| Eventos/mensageria, banco, cache, APIs, resiliência, jobs | `references/dados-eventos.md` |
| Segurança, auth, JWT, multi-tenancy, LGPD, segredos | `references/seguranca.md` |
| **IAM — auth como microserviço Rust separado (`auth.<domain>`), ID≠email, ≥2 fatores (passkey/Resend/Twilio), ReBAC multi-tenant deny-default, sessão 7d/90d, logout irreversível, migração legado prioridade 0** | `references/iam.md` |
| **Efeito externo fora de prd (e-mail/SMS/push/webhook): `trait EmailProvider` + sink default + `Guarded<P>` devolvendo `Result<_, MailError>` + cap por `AtomicUsize`, e o `#[tokio::test]` que espera o `Err`** | `references/iam.md` (§3.1) |
| **Cadeia de suprimentos: lockfile, SBOM, scan que trava, imagem mínima/pinada/assinada, SLSA, segredo no build** | `references/cadeia-suprimentos.md` |
| Testes — o recorte Rust (runner, sintaxe, armadilhas do dialeto). **A disciplina é da `schematize-qa`.** | `references/testes.md` |
| Observabilidade, healthchecks, performance, FinOps | `references/observabilidade.md` |
| Config, deploy/K8s, git/PR, ownership, runbooks/incidentes, ADR, **archive** (§20–28) | `references/operacao.md` |
| **Ops (control plane): fluxo dev→local→github→hml→prd (nada direto no servidor), ops como interface única (100%, autônomo), instalação paralela=`nproc`, independência=invariante** | `references/ops.md` |
| Templates, feature flags, IA assistida, DoD, evolução, índice de funcionalidades (§29+) | `references/entrega.md` |
| Filosofia, aplicação universal e a lista completa de anti-padrões vetados | `references/anti-padroes.md` |
| Gestão de contexto em sessões longas no Claude Code (handoff, hooks) | `references/contexto-claude-code.md` |
| Versões e limiares voláteis (Rust estável, edição, MSRV, ferramental) | `references/stack-versoes.md` |

## Pisos inegociáveis (VETADO — sem ADR de exceção)

Nunca violados, nem "pra funcionar", nem "pra ir mais rápido". Lista completa em `references/anti-padroes.md`. Os que mais aparecem:

- **Segredo nunca no cliente.** Nada de API key, secret de JWT, senha de banco ou token em bundle do browser nem em `NEXT_PUBLIC_*`/`VITE_*`. Segredo só server-side. Detalhe em `references/seguranca.md`.
- **SQL sempre parametrizado.** Concatenar string em query é injeção esperando acontecer (em Rust, use `sqlx`/binds; nunca `format!` em SQL).
- **Auth e autorização server-side.** `tenant_id`/role/`user_id` vêm do token verificado, nunca do body/header do cliente.
- **JWT validado por inteiro** (assinatura, exp, aud, iss, alg em allowlist). Senha nova em **argon2id** (crate `argon2`, em `spawn_blocking`; parâmetros mínimos e rehash de legado em `schematize-engineering` → `references/iam.md`); bcrypt/PBKDF2 só como legado a migrar no próximo login. Token de sessão por CSPRNG (`OsRng`/`getrandom`).
- **Erro nunca engolido.** Sem `let _ = ...` pra calar resultado, sem `.unwrap()`/`.expect()` em caminho de produção pra silenciar o compilador; trate `Result`/`Option` de verdade (`?`, match, erro tipado).
- **Teste nunca silenciado** pra passar CI (`#[ignore]`, comentar assert, baixar threshold). Conserta o código, não o teste.
- **Sem monólito que mistura bounded contexts**, sem monólito distribuído, sem shared lib `commons` de domínio.
- **Archive SEMPRE gerado.** Toda entrega que produz código/decisão/mudança de estado gera o `.md` de archive. Templates em `assets/`.
- **Migration reversível** (com `down`, testada com rollback). Container não-root, read-only. Dependência nova com nome/licença/versão verificados.
- **Pisos de código (`references/padroes-codigo.md`):** arquivos **≤ 750 linhas** (teto duro: ~250 de comentário + ~500 de código útil; acima → quebrar por coesão), **flag em > 300 linhas de código útil** (não bloqueia, mas sempre sinaliza — indício de função extensa/falta de abstração, revê depois; observabilidade ~400), **uma função/unidade lógica por arquivo**, **toda função com doc-comment** (`///`: motivo, comportamento esperado, entradas, saídas, efeitos), **`MAPA.md` da aplicação** atualizado no mesmo PR — em **`<projeto>_archive/index/`, nunca no root** — e **índice de microfunções** regenerado (`/rust-index`). **Todo MD gerado (MAPA/índice/plano/relatório/handoff) mora no archive**, root limpo (§28). Detalhe em `schematize-engineering` -> `references/padroes-codigo.md` (§4) e `references/operacao.md` (§28, §39).
- **Backend novo só no ROL sancionado (Go/Rust/Elixir/C#/Zig/Ruby), escolhido por fit + ADR** (`schematize-engineering` → `references/linguagens.md`). Node backend e PHP são legado/fora do rol. Critérios do fit de Rust em `references/stack-rust.md`.
- **Fluxo de ambientes e ops (`references/ops.md`).** <!-- herdado:engineering/fluxo-ambientes:corpo -->Toda mudança segue **dev local → teste local → GitHub → hml → prd**; **VETADO editar código direto no servidor** (hml/prd é imutável por edição manual, recebe só artefato do git). **100%** das operações no servidor (install/update/correção/config/migrate/rollback) passam pela **ferramenta do `<projeto>_ops`** — nunca à mão; o ops é **autônomo** (o usuário provisiona o servidor do zero sem a IA). **Instalação sempre paralela** = `nproc`; **falha no paralelo = serviços não independentes → corrigir a independência é prioridade máxima** (não serializar pra mascarar).<!-- /herdado -->
- **Deploy destrutivo por seed + isolamento por usuário (`schematize-engineering` -> `references/ops.md` §2–§3).** <!-- herdado:engineering/deploy-destrutivo:corpo -->O ops provisiona em **`/<app>/`** clonando os repos dentro; **`/<app>/.env` é o seeder global** (fonte única de config). **Todo redeploy é destrutivo na aplicação** — apaga a anterior e recria um clone zerado só com o seed (idempotente/sem drift), **preservando os dados** (migration reversível; `ops reset` de dados só em dev/hml). **Cada serviço roda como user Linux próprio em systemd unit hardened** (blast radius mínimo). Tudo automatizado pelo ops.<!-- /herdado -->
- **IAM por desenho (`references/iam.md`).** Todo projeto com auth começa com identidade e autorização robustas, e o auth é **app SEPARADA** — microserviço Rust `<projeto>_auth_rs` (axum/actix) + front próprio em **`auth.<domain>`**, isolado; **VETADO** monolith; apps delegam por **OIDC/OAuth2.1 + PKCE** (chave só no auth, JWKS público). Passkey/WebAuthn via `webauthn-rs`, email OTP Resend, argon2id em `spawn_blocking`; PEP como `tower` layer. <!-- herdado:engineering/iam-desenho:invariantes cmd="rust" -->**ID interno imutável (ULID/UUIDv7) — email/telefone nunca é ID** (N emails por usuário; SSO com recuperação local). **≥2 fatores sempre**: passkey/WebAuthn no núcleo, TOTP/push, email OTP always-on, Twilio para telefone; senha argon2id+HIBP por padrão, mas opcional; invariante de troca de fator (Y≠X no maior AAL); **recuperação ≥ login**. Senha + Email OTP já é **2FA baseline**: o PEP libera o baseline e exige AAL alto **só por rota sensível** (step-up just-in-time), nunca barra o login. **Multi-tenant RBAC/ABAC granular via ReBAC** (OpenFGA/SpiceDB; deny-default, PDP=Check API, PEP no servidor, token fino). **Multi-dispositivo, sessão 7d/90d, logout irreversível** (revoga refresh+família, `jti` na denylist, não só cookie). **Passkey/WebAuthn é o método PADRÃO e entra na FASE 0** (registro+asserção reais e2e antes de qualquer feature; passwordless-first, senha+Email OTP fica de fallback/2FA baseline; teste: registro, login, challenge reutilizado, origin/rpId errado e credencial revogada rejeitados) — a implementação mora no IAM da casa (`auth.<domínio>`), o app cliente só integra via OIDC/PKCE. **Toda rota exposta nasce com teste de matriz de acesso no CI** (anônimo/não privilegiado/privilegiado/burlas; status e corpo; deny-by-default; inventário derivado, M == N) — detalhe na `schematize-qa` (`scripts/check-route-authz.sh`). **Migrar auth legado = prioridade 0.** Scaffold/auditoria por **`/rust-iam`**; testes cross-tenant/priv-esc na `schematize-pentest`.<!-- /herdado -->
- **Efeito externo NUNCA sai de não-produção (`references/iam.md` §3.1; normativa na `schematize-engineering` → `references/efeitos-externos.md`).** E-mail, SMS/voz, push, webhook de terceiro e cobrança **não acontecem de verdade** fora de `prd` — por construção, não por lembrança. Em Rust: **`EmailProvider` já é trait (§3)**, então o **default fora de prd é o `SinkProvider`** (Mailpit/`tracing`) e o guard é um **wrapper genérico** `Guarded<P: EmailProvider>` selecionado por `env` **na composição** (`build_email_provider` → `Arc<dyn EmailProvider>`), **nunca no chamador** — destinatário fora do domínio de teste com `env != Prd` devolve **`Err(MailError::ExternalRecipientBlocked)`** (`thiserror`), nunca `tracing::warn!` + `Ok(())`; **sem `unwrap()`/`expect()`**, o chamador propaga com `?`. `Env::from_raw` sem valor declarado assume **não-prd**, `max_per_run == 0` cai no default 50 e o cap usa `AtomicUsize`. Provado por **`#[tokio::test] guard_recusa_dominio_externo`** (espera o `Err`; o spy conta 0 chamadas). <!-- herdado:engineering/efeito-externo:invariantes -->**Cap por execução** (`MAIL_MAX_PER_RUN`, default 50) com abort; **fail-closed** (ambiente ausente/desconhecido ⇒ não-prd; só o valor exato de produção entrega de verdade); **chave sandbox** fora de prd. Todo endereço sintético (fixture, seed, persona, demo, carga) é `<papel>+<run-id>-<n>@test.<domain>` — domínio em **rota nula** (null MX RFC 7505 + SPF `-all` + DMARC `p=reject`) ou TLD reservado (`.test`/`.invalid`/`.example`); **VETADO** `@gmail.com`, domínio de cliente/terceiro, e-mail de pessoa real (**inclusive o seu**) e o domínio de produção. A recusa é **erro**, nunca warning nem sucesso silencioso. Entregar de verdade fora de prd exige **as cinco** (ADR + allowlist ≤5 + cap + janela + subdomínio separado). Motivo: bounce/complaint em massa **queima IP e domínio** e derruba o transacional de prd — inclusive o **OTP de login** — com semanas de warm-up e utilidade zero (o incidente dos 5.000 e-mails só existiu porque nada contava).<!-- /herdado -->
- <!-- herdado:engineering/orquestracao:bullet -->**Orquestrador não desenvolve; subagent barato executa** (`schematize-engineering` → `references/orquestracao.md` §9). O principal só planeja/decompõe/despacha/supervisiona/revisa; ação onerosa vira micro-tasks; principal = Claude Opus; executor mais barato que resolve: `haiku` (mecânico) / `sonnet` (código, até 2 rodadas de correção pelo mesmo subagent) → Codex `gpt-5.6-terra` → Cursor → subagent `opus` (motivo no checkpoint) → `park`; **visual direto ao Codex; imagem nunca pelo Claude (pergunta ao usuário: Codex sugerido, ou Gemini), API de imagem paga PROIBIDA**; papéis configuráveis em `agentes.toml` (aba "Agentes" do overdev). No `overdev`, cada item do checklist é executado pelo papel adequado e revisado pelo principal (diff + gate) antes do `- [x]`. **Sem frota ociosa:** agent idle com pendência executável volta ao trabalho; pendência que depende de outro agent → mata e enfileira com gatilho de dependência; terminou → mata (§9.6).<!-- /herdado -->

> Regra de bolso: se a justificativa começa com "só pra funcionar", "depois eu arrumo" ou "é mais rápido assim" e o resultado mexe em segredo, auth, dado ou registro — é anti-padrão vetado. Pare e faça certo.

## Testes — o que conta como "verde de verdade"

Detalhe em `references/testes.md` (o recorte Rust) — a **disciplina** de teste é da `schematize-qa`, e a segurança ofensiva da `schematize-pentest`.

## Andaime pronto (scripts e templates)

Não escreva do zero o que já está bundlado: `scripts/lib.sh`, `scripts/test-skeleton.sh`, `scripts/smoke-selfcheck.sh`, `scripts/simulated/run.py`, os hooks de contexto (`scripts/hooks/*.mjs`), os templates em `assets/` (ADR, TASK, CHAT_ARCHIVE, PR_TEMPLATE, RUNBOOK, **MAPA**), o índice (`assets/INDEX_*` + `scripts/build-index.mjs`) e `assets/CLAUDE.md` pra pinar os padrões na raiz do repo.

## Aplicação sempre-on

Copie `assets/CLAUDE.md` para a raiz do projeto pra garantir os padrões em toda interação do repo, não só quando a skill dispara.

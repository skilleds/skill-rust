# Filosofia, Aplicação Universal e Anti-Padrões Vetados


> **PONTEIRO, não cópia.** A normativa deste tema é da base: **`schematize-engineering`** →
> `references/anti-padroes.md`. Leia lá primeiro; aqui fica **só o que muda em Rust**.
>
> **Onde este arquivo divergir da base, a BASE MANDA** (`SKILL.md` §"Precedência e herança").
> Em 2026-08-21 os blocos idênticos à base foram **podados mecanicamente** (`tools/podar-clone.mjs`),
> que é por que a numeração dos itens **salta**: o número é o da base, e o item que não aparece aqui
> é porque **não muda nesta linguagem** — procure-o lá. Manter a cópia era manter a próxima deriva
> (foi assim que o `argon2id-only` da casa virou "ou PBKDF2" numa skill e o rol de 6 linguagens
> virou "só Go e Rust" em três).

## 37. Anti-Padrões Vetados — "Macaquices" que Terminam Rápido e Quebram em Produção

### CORS, headers e superfície

12. **`Access-Control-Allow-Origin: *` em rota autenticada** (pior ainda com `allow-credentials`).
    → Allowlist explícita de origens (hardening; ver a `schematize-qa`, `references/categorias.md` §§5 e 10).

13. **Endpoint de debug/admin/management sem auth, ou bind em `0.0.0.0`** expondo porta interna.
    → Bind restrito, auth obrigatória, `/debug` e `/actuator` retornam 404 externamente (ver a `schematize-qa`, `references/categorias.md` §§5 e 10).

### Testes e cobertura

19. **Baixar o threshold de cobertura ou editar o gate** pra o número fechar.
    → Cobertura é contrato (ver a `schematize-qa`). Sobe escrevendo teste, não mexendo na régua.

### Operação e entrega

31. **Criar serviço backend novo FORA do rol sancionado, ou sem o ADR de fit que justifica a escolha.** Serviço backend novo em Node ou qualquer código novo em PHP entram aqui — são legado.
    → Backend novo **dentro do rol** (Go, Rust, Elixir, C#, Zig, Ruby), com **ADR (§27) de fit**; escolha **Rust** quando o fit manda (auth/cripto, hot path, garantia de memória) — em empate, o default pragmático é Go. Next.js/Astro seguem valendo pro frontend. PHP é proibido e migra; Node backend legado sai pela regra dos ~30%/~50% (§3, §3.1). Rol e critérios em `schematize-engineering` -> `references/linguagens.md`.

35. **Editar código direto no servidor** (hml/prd), ou **subir mudança direto pra hml/prd** pulando `dev local → teste local → GitHub`.
    → Servidor é **imutável por edição manual**; recebe só artefato promovido do git. Hotfix segue o mesmo fluxo, acelerado (`schematize-engineering` -> `references/ops.md` §1).

36. **Operar o servidor por fora do `<projeto>_ops`** — `ssh` + comando ad-hoc, editar arquivo no servidor, `docker`/`kubectl`/`systemctl` na mão, script solto.
    → **100%** de install/update/config/correção passa por comando do ops. Não tem comando? **cria no ops** (`schematize-engineering` -> `references/ops.md` §2).

37. **Instalar/subir o sistema em série** ("um serviço de cada vez", 20 min).
    → Instalação **paralela por padrão** = `nproc` (`schematize-engineering` -> `references/ops.md` §3).

38. **Serializar a instalação pra "funcionar"**, mascarando que um serviço depende de outro pra subir.
    → Erro que só ocorre em paralelo = **serviços não independentes** (fere piso 10/6). O ops **expõe** a colisão; corrigir a independência é **prioridade máxima**. Nunca esconder com serialização (`schematize-engineering` -> `references/ops.md` §6).

39. **Redeploy que faz patch in-place / não parte do seed** (estado acumulado, drift entre implantações).
    → Todo redeploy é **destrutivo na app**: apaga a anterior e recria um clone zerado a partir de `/<app>/.env` (`schematize-engineering` -> `references/ops.md` §2). Idempotente e reprodutível.

40. **Config/segredo de serviço fora do seed global**, ou repos do sistema espalhados fora de `/<app>/`.
    → `/<app>/.env` é a **fonte única** de config; o ops clona os repos dentro de `/<app>/` (`schematize-engineering` -> `references/ops.md` §2).

41. **Apagar dados persistentes num redeploy** ("destrutivo" incluindo banco/volumes), ou `ops reset` de dados em prd.
    → Destrutivo é a **aplicação, nunca os dados**: banco/volumes/uploads preservados (migration reversível); apagar dado é `ops reset` **gated a dev/hml** (`schematize-engineering` -> `references/ops.md` §2).

42. **Dois serviços no mesmo user Linux, serviço rodando como `root`, ou criar user/unit/permissão à mão.**
    → **Um user + systemd unit hardened por serviço**, provisionado **pelo ops** (`schematize-engineering` -> `references/ops.md` §3). Blast radius mínimo.

### Identidade e autorização (IAM)

43. **Auth apensado ao app principal (monolith), sem serviço/front próprios** — login "dentro" do core, chave de assinatura junto do domínio; comprometer o app compromete a identidade.
    → Auth é **microserviço Rust SEPARADO** (`<projeto>_auth_rs` em axum/actix + `<projeto>_authfront`) em **`auth.<domain>`**, isolado; apps delegam por **OIDC/OAuth2.1 + PKCE**; chave só no auth, consumidores validam por **JWKS público** (`references/iam.md` §1).

44. **Email/telefone como ID (PK), ou aceitar 1 fator** — email vira chave estrangeira do mundo todo, brick de provedor = conta perdida, e login com senha só é "1 fator e pronto".
    → **ID interno imutável** (ULID/UUIDv7) é o `sub`; email/telefone são identificadores verificáveis 1..N (múltiplos incentivados); **≥2 fatores sempre** (passkey no núcleo via `webauthn-rs`, email OTP Resend always-on, Twilio p/ telefone), senha argon2id (crate `argon2` em `spawn_blocking`) opcional no seletor (`references/iam.md` §2, §3).

45. **Authz hand-rolled em Rust** (`if user.role == "admin"`, checagem de tenant no handler, permissão embutida em token longo), ou decisão de acesso no cliente.
    → **Motor ReBAC** (OpenFGA/SpiceDB), tuplas + relation rewrite; **deny-default**; **PEP como `tower` layer/extractor** em cada serviço chamando a Check API; **token fino** (sem lista de permissões); `tenant_id`/role/`sub` **do token verificado**, nunca do cliente; toda decisão auditada (`references/iam.md` §5).

46. **Logout que só apaga o cookie** (refresh e sessão continuam válidos — "voltar o cookie" ou o refresh reativa a sessão), ou sessão de "15 min e é chutado".
    → Logout **irreversível**: revoga refresh + **família**, apaga o registro de sessão server-side, joga o `jti` na **denylist (Redis/DB)** até expirar, desassocia o push token — o PEP checa a denylist a cada request. **Sessão longa** (7d padrão / 90d se confiável) com access token curto + refresh rotativo com detecção de reuso (`references/iam.md` §6).

### Efeitos externos (e-mail, SMS, push, webhook, cobrança)

47. **Mandar de verdade fora de produção** — `lettre`/SDK do provedor ligado por default em dev/hml, `@gmail.com` (ou o seu e-mail) em fixture/seed/persona, laço de teste criando N contas com **Email OTP always-on** e nenhum contador no caminho.
    → **Provider por ambiente** (trait `Mailer` com impl `Sink` fora de `prd`), **guard dentro do provider** (`MailError::ExternalRecipientBlocked`, fail-closed quando a config falta), **cap por execução** com `AtomicUsize` (`MAIL_MAX_PER_RUN`) válido em TODOS os ambientes, e endereço sintético só em `test.<domain>` com **null MX** (`references/iam.md` §3.1; normativa em `schematize-engineering` → `references/efeitos-externos.md`). Bounce/complaint em massa **queima IP e domínio** e derruba o e-mail transacional de **produção** — inclusive o **OTP de login** —, com semanas de warm-up e utilidade zero. Não tem undo.
    *(Cite este anti-padrão **pelo título**, nunca por número: o mesmo `§37 item N` significa coisas diferentes em cada skill — ver a nota de numeração no topo.)*

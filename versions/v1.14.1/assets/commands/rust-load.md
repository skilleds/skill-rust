---
description: schematize-rust — carrega à força TODO o corpo normativo (Rust principal/Go auxiliar, async/Tokio, DDD/arquitetura, clean code, segurança, testes, operação) no contexto e passa a aplicá-lo no projeto atual como regra inegociável
---

Carregue **à força** e passe a aplicar **integralmente** os Padrões de Engenharia da Casa com **Rust principal e Go auxiliar** (skill `schematize-rust`) neste projeto. A partir de agora, nesta sessão, isto **não é opcional**.

1. **Leia agora, na íntegra, TODOS os arquivos** de references da skill — não trabalhe de memória, abra cada arquivo. O caminho é `.claude/skills/schematize-rust/references/*.md` (instalação no projeto) ou `~/.claude/skills/schematize-rust/references/*.md` (instalação global). Com destaque para:
   - `stack-rust.md` — Rust como escolha padrão de backend, Go auxiliar, quando trocar de linguagem.
   - `async-concorrencia.md` — Tokio: não bloquear o runtime, cancel-safety em `select!`, locks fora de `.await`, backpressure, graceful shutdown.
   - `padroes-codigo.md` — **clean code**: arquivo ≤750 linhas (~500 úteis + ~250 comentário; flag >300 úteis, ~400 obs), uma função/arquivo, doc-comment (`///`) obrigatório, `MAPA.md`.
   - `arquitetura.md` — **DDD**, camadas, repositórios, bounded contexts, anti-monólito, CQRS.
   - `seguranca.md` — auth/JWT, multi-tenancy, segredo nunca no cliente, SQL parametrizado (`sqlx`/binds, nunca `format!`).
   - `iam.md` — **IAM da casa (angle Rust)**: auth como microserviço Rust SEPARADO (`<projeto>_auth_rs`, axum/actix) em `auth.<domain>`, ID interno≠email, ≥2 fatores (passkey `webauthn-rs`/Resend/Twilio, argon2id em `spawn_blocking`), ReBAC multi-tenant deny-default (PEP `tower` layer), sessão 7d/90d, logout irreversível (`jti` na denylist), migração de legado prioridade 0.
   - `dados-eventos.md`, `cadeia-suprimentos.md` — dados/mensageria/resiliência; lockfile/SBOM/scan/imagem assinada/SLSA.
   - `testes.md` — test kit, "verde de verdade", pentest, Q.A. plan-first.
   - `observabilidade.md`, `operacao.md` + `entrega.md` — healthchecks/FinOps; config/deploy/git/ADR/**archive**/DoD/índice.
   - `ops.md` — **control plane `<projeto>_ops`**: fluxo dev→local→github→hml→prd (nada direto no servidor), ops como interface única (100%, autônomo), instalação paralela=`nproc`, independência=invariante (prioridade máxima).
   - `anti-padroes.md` — a lista completa de anti-padrões vetados.
   - `contexto-claude-code.md` — gestão de contexto/handoff em sessões longas.

2. **Confirme ao usuário** que leu, com **1 linha por arquivo** resumindo o piso central de cada um.

3. Deste ponto em diante, **aplique estes padrões como regra inegociável** em toda decisão, geração e revisão de código deste projeto — Rust-first, async correto, arquitetura/DDD, clean code, segurança, testes e archive. Em conflito entre "fazer rápido" e o padrão, **o padrão vence**.

4. **Atualize o `CLAUDE.md` da raiz** do repositório com a versão atual de `assets/CLAUDE.md` da skill — **sobrescreva mesmo se já existir** (rodar não pode deixar a versão antiga). Se o `CLAUDE.md` atual tiver customização local (seções fora do template da skill), salve backup `./CLAUDE.md.bak` e reaplique as customizações por cima do template novo. Se não existir, crie. É o mesmo que o comando `/rust-claude`. Confirme a versão aplicada.

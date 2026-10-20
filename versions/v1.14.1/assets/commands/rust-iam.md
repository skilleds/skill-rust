---
description: schematize-rust — força/audita/scaffolda o IAM da casa (identidade≠email, ≥2 fatores, ReBAC multi-tenant, sessão longa/logout irreversível) como microserviço Rust separado em auth.<domain>, ou atualiza um auth existente
argument-hint: "[bootstrap | audit | migrate]"
---

Governe identidade e autorização pelo padrão IAM da casa (`references/iam.md`), com o auth
como **microserviço Rust** (axum/actix sobre Tokio; Go só auxiliar via ADR). Plan-first:
**audita, mostra o plano, pede aprovação, então executa.** Use este comando para **forçar
só a parte de IAM** num projeto (novo ou existente) ou **atualizar/portar um auth legado**.

## 0. Modo
- `audit` — varre o projeto e reporta o gap contra o piso IAM (checklist §iam).
- `bootstrap` — scaffolda o IAM do zero como **microserviço Rust separado**.
- `migrate` — porta um auth legado pro IAM (**prioridade 0**, strangler-fig).

## 1. Topologia primeiro (inegociável)
Confirme/scaffolde que o auth é **aplicação SEPARADA** (`references/iam.md` §1):
- Serviço próprio `<projeto>_auth_rs` (**axum**/**actix-web** sobre Tokio) + front próprio
  `<projeto>_authfront`, servidos em **`auth.<domain>`** — **VETADO** monolith apensado ao
  escopo principal.
- Repo/deploy/**user Linux + systemd isolados** por conta própria (casa com `schematize-engineering` -> `ops.md` §3).
- App principal e clientes **delegam por OIDC/OAuth2.1 + PKCE**; chave de assinatura só no
  `<projeto>_auth_rs`, exposta como **JWKS público** (`jsonwebtoken`/`josekit`); consumidores
  validam por JWKS, nunca guardam a chave privada.

## 2. Identidade
- **ID interno imutável** (ULID/UUIDv7 — `ulid`/`uuid`); **email/telefone nunca são ID**
  (schema `users(id)` + `identifiers(user_id, kind, value, verified_at)` 1..N); **N emails**
  por usuário (incentivado). Identificador só vale **verificado**.
- **SSO com recuperação local forçada**; account-linking explícito (anti-takeover).
- **Nudge de email secundário:** detecta provedor e recomenda outro provedor + tooltip "i".

## 3. Fatores (≥2 sempre)
- **Passkey/WebAuthn no núcleo** (`webauthn-rs`); TOTP/push (`totp-rs`); **email OTP (Resend)
  always-on inclusive HML** (só operador desliga); **Twilio** p/ telefone; providers
  **plugáveis por trait** (`EmailProvider`/`SmsProvider`/`PushProvider`), chamadas `async`
  resilientes.
- **Senha por padrão** (argon2id via crate `argon2` em **`spawn_blocking`** + HIBP), **opcional
  no seletor de modos**.
- **Senha + Email OTP JÁ é o 2FA baseline** (acesso pleno desde o cadastro). Fator forte (passkey/TOTP) é **nudge + step-up just-in-time** (op sensível / risco), **NUNCA muro pré-login** — barrar o acesso por falta de fator forte é o círculo infinito / bug de bootstrap **VETADO** pela norma (`iam.md` §3/§4).
- Invariante de troca: **mutar fator X exige fator Y≠X no maior AAL**; notificar canais;
  remover último fator forte = **atraso cancelável**. Recuperação **≥ força do login**.

## 4. Autorização (multi-tenant, ReBAC)
- **Identidade global, papéis por tenant** (membership). Motor **ReBAC (OpenFGA/SpiceDB)**,
  tuplas `(objeto, relação, usuário)`; **RBAC granular** (`recurso:ação`, papéis
  customizados) + **ABAC** (conditional tuples). **PDP = Check API do motor; PEP = `tower`
  layer/extractor (axum)**, deny-default, enforcement server-side, token fino, decisão
  auditada. `tenant_id`/`sub`/role vêm do token verificado, nunca do cliente.

## 5. Sessão / logout
- **Multi-dispositivo** + **view de remover dispositivos** + "sair de todos".
- **Sessão 7 dias por padrão; pergunta se confiável → 90 dias** (access token curto com
  refresh silencioso — nada de "15 min e é chutado"). Step-up fresco em ops sensível.
- **Botão Sair visível → kill IRREVERSÍVEL:** revoga refresh + família, apaga sessão
  server-side, `jti` na **denylist (Redis/DB)**, desassocia push token. Nada recria a sessão;
  o PEP checa a denylist a cada request.

## 6. Testes (dispare o gate do pentest)
Rode/priorize a rotina agressiva (`schematize-pentest`): **cross-tenant (BOLA/IDOR),
priv-esc (BFLA), abuso de fluxo (bypass 2FA/reset/step-up, replay, refresh reuse, logout
que não invalidou)** — gate que trava em vazamento. Ver `/pentest-authz`.

## 7. Migração de legado (modo `migrate`, prioridade 0)
Strangler-fig: dual-run, **re-hash preguiçoso** (→argon2id) no login, mapeia registros →
modelo novo (dedupe emails, cunha IDs ULID/UUIDv7), **no 1º login pós-migração: nudge + step-up (nunca barra o acesso por falta de fator forte)**, **revoga
sessões legadas**, **re-deriva authz** (nunca confia na antiga; re-monta tuplas do ReBAC). O
auth migrado nasce microserviço Rust separado; PHP/Node de auth é substituído, não reaproveitado.

## 8. Saída
Grave o plano/relatório em `<projeto>_archive/` (§28): topologia (app separado?), gaps do
checklist IAM (`references/iam.md`), plano por fase (F0–F6) e — se `migrate` — o mapa
legado→novo e a ordem de corte. Confirme: auth é microserviço Rust à parte? identidade≠email?
≥2 fatores? ReBAC multi-tenant deny-default? sessão longa + logout irreversível? testes
cross-tenant no CI?
</content>

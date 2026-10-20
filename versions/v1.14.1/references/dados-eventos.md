# dados eventos — recorte Rust

> **PONTEIRO, não cópia.** A normativa deste tema é da base: **`schematize-engineering`** →
> `references/dados-eventos.md`. Leia lá primeiro; aqui fica **só o que muda em Rust**.
>
> **Onde este arquivo divergir da base, a BASE MANDA** (`SKILL.md` §"Precedência e herança").
> Este arquivo era um clone com **99%** de conteúdo
> idêntico à base — deriva por cópia foi o achado da Classe C da vistoria de 2026-08-21, e ela
> já tinha atingido piso de segurança (o `argon2id-only` da casa virou "ou PBKDF2" numa skill,
> o rol de 6 linguagens virou "só Go e Rust" em três). Manter uma cópia é manter a próxima deriva.
## 10. Banco de Dados

**Ferramentas sugeridas:** `sqlx-cli`/`refinery` (Rust), `golang-migrate`, `node-pg-migrate`, `flyway`.

Migrations seguras (expand-contract, `lock_timeout`, índice concorrente, backfill em lote), pool/PgBouncer e `EXPLAIN`:
`schematize-postgres → references/locks-e-migrations.md`, `pooling.md`, `explain-e-indices.md`. Contrato de API (OpenAPI, erros RFC 9457,
idempotência, cursor): `schematize-api → references/contrato-rest.md`. Em Rust, o que fica aqui é a escolha de ferramenta (`sqlx` com
`query!` verificado em compilação, `sqlx migrate`) e o pool do `sqlx` dimensionado abaixo do `max_connections` do Postgres.

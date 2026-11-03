# Anexo volátil — versões e limiares (Rust)

> Parte da skill **schematize-rust**. **Fonte volátil:** tudo aqui tem prazo de validade e é
> atualizado **à parte** do corpo normativo — que não deve cravar número nenhum (o lint do
> catálogo, regra `anexo-volatil`, reprova quando crava).
>
> **Verificado em: 2026-08-21.** Cadência: **revisão trimestral**, e sempre antes de um release da
> skill. Confirme na fonte (release notes do Rust, `crates.io`, endoflife.date) antes de pinar.

## Rust — toolchain

- **Piso normativo: toolchain PINADA e recente.** `rust-toolchain.toml` no repo fixa canal e
  versão — build reprodutível entre máquina e CI. O Rust não tem "LTS": a linha estável avança a
  cada 6 semanas, e ficar muitas releases atrás custa em dependências que sobem o MSRV.
- **Calibração verificada em 2026-08-21:** estável corrente **1.98**; a **edition 2024** estabilizou
  no **1.85** e é o default do `cargo new` desde então.
- **MSRV sugerido pela casa: 1.85** (o piso da edition 2024). Serviço que precise de mais recente
  declara o seu; o que importa é **declarar e testar no CI** — MSRV que ninguém compila é palpite.
- **MSRV declarado** (`rust-version` no `Cargo.toml`) e testado no CI — subir MSRV é decisão, não
  acidente de `cargo update`.
- Imagem base **por digest**, nunca por tag móvel.

## Ferramental

| Ferramenta | Papel | Nota |
|---|---|---|
| `clippy` | lint | `-D warnings` no CI |
| `cargo deny` | advisories, licença, bans e fontes num só gate (`assets/lint/deny.toml`) | trava o merge |
| `cargo nextest` | runner de teste paralelo, saída melhor no CI | |
| `cargo llvm-cov` | cobertura | |
| `cargo miri test` | UB no que tem `unsafe` | obrigatório onde há `unsafe` |
| `proptest` | property-based | domínio crítico |
| `cargo-mutants` | mutation testing | domínio crítico |
| `criterion` | benchmark | bench **não** é teste e não conta como cobertura |

## Infra e protocolo (fora do escopo desta skill)

Kubernetes, PostgreSQL, Redis, OpenTelemetry e afins: **`schematize-infra`**. Frontend:
**`schematize-web`** → `references/stack-versoes.md`. Não duplique os números aqui.

## Regra que NÃO é volátil

**Mudança de versão major exige ADR**, e **`unsafe` novo exige justificativa escrita** + `miri` no
CI. Isso vale independente do número, e mora no corpo normativo.

# Testes — recorte Rust

> **PONTEIRO, não cópia.** A **disciplina de teste** da casa é da **`schematize-qa`**: a pirâmide,
> teste de COMPORTAMENTO (não "renderizou"), o "verde de verdade" (smoke com asserção de conteúdo +
> assertion negativa + self-check que força uma falha conhecida), cobertura útil, a11y, regressão
> visual, contrato/dados, **flaky** (quarentena com prazo e dono), o fluxo **plan-first**
> (`/qa-plan` → `/qa-run`) e os **gates de CI que travam o merge**. Leia
> `schematize-qa` → `references/estrategia.md`, `references/categorias.md`,
> `references/execucao.md` e `references/flaky.md`.
>
> **Segurança ofensiva** (rejeição rota a rota, injeção/coerção, IDOR/BOLA, cross-tenant) é a
> **`schematize-pentest`** — não é Q.A. e não mora aqui.
>
> Aqui fica **só o que muda em Rust**: o runner, a sintaxe, e as armadilhas do dialeto.
>
> *(Este arquivo e a antiga reference *testes-execucao* eram, juntos, ~450 linhas por skill — 66% já
> duplicado na `schematize-qa`, 23% que pertence à `schematize-pentest` e ~2% idiomático de
> verdade. Deriva por cópia foi o achado da Classe C/D da vistoria de 2026-08-21.)*

## O runner e o comando

```bash
cargo test --all-features           # unit + integração + doctests
cargo nextest run                   # runner paralelo, saída melhor no CI
cargo llvm-cov --lcov --output-path lcov.info
cargo miri test                     # UB em código `unsafe` (quando houver)
```

## O que muda de forma em Rust

- **Doctests contam e rodam.** Exemplo em `///` que não compila **quebra o build** — é a forma
  mais barata de manter documentação honesta, e é exclusividade do Rust. Não desligue com
  `no_run`/`ignore` para "passar".
- **`#[should_panic(expected = "...")]` sempre com `expected`**: sem a mensagem, o teste passa por
  um panic **diferente** do que você queria provar.
- **`#[tokio::test]`** para async; `#[tokio::test(flavor = "multi_thread")]` quando o teste depende
  de paralelismo real. Runtime single-thread esconde deadlock.
- **Teste de erro é sobre a VARIANTE, não sobre a string.** Case sobre `Err(MailError::External…)`,
  nunca sobre o `to_string()` — a mensagem muda, o contrato não.
- **`cargo miri test`** no que tem `unsafe`: UB não aparece em teste normal.
- **Property-based:** `proptest`. **Mutation:** `cargo-mutants`. **Bench:** `criterion` (bench não
  é teste — não vale como cobertura).
- **`testcontainers`** para banco/broker; `mockall` só na fronteira de trait, nunca do domínio.

## Onde divergir da base, a base manda

O piso é o mesmo: teste é **visto falhar no vermelho** antes de valer; cobertura é **contrato**
(não se baixa a régua para passar o CI); **teste nunca dispara efeito externo real** — endereço no
domínio de teste em rota nula, provider = sink, cap por execução, e a caixa se confere **lendo do
sink** (`references/iam.md` §3.1 desta skill; normativa em `schematize-engineering` →
`references/efeitos-externos.md`); e **gate não se desliga "por enquanto"**.

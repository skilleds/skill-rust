# Stack — Rust (fit, toolchain e ferramental)

Define quando Rust entra e o ferramental desta skill. Rust é **uma** linguagem do rol sancionado da
casa (Go, Rust, Elixir, C#, Zig, Ruby), escolhida por **fit + ADR** — sem hierarquia entre as irmãs
(`schematize-engineering` → `references/linguagens.md`). Tudo o mais (arquitetura, segurança,
testes, operação) segue os references comuns.

## 1. Quando Rust é o fit

- **Fit forte:** correção e segurança de memória críticas — auth/IdP, criptografia, **parsing de
  entrada hostil**, protocolos binários, componentes que não podem ter pausa de GC ou UB.
- **Também serve** para serviços, APIs, workers e CLIs quando o time domina e o custo de
  desenvolvimento compensa. Se o fit não é claro, o desempate pragmático está na base, não aqui.
- A decisão vira **ADR** (`assets/ADR.md`) com o fit que a motivou; não há ADR "para escolher" uma
  linguagem em detrimento de outra por default — há ADR de fit, igual para todas do rol.
- **Node backend e PHP** são legado/fora do rol: não recebem serviço novo (frontend Node é
  `schematize-web`).

## 2. Outras linguagens na mesma máquina/sistema

Serviço em outra linguagem do rol segue **integralmente a skill irmã dela** — para Go, use
`schematize-go` (`go.mod`, `golangci-lint`, `govulncheck`, concorrência com `context`/`errgroup`).
Os pisos são os mesmos em todas: erro nunca engolido, SQL parametrizado, container não-root, lint da
linguagem no CI, IAM como app separada, efeito externo que não sai de não-produção. Quando uma
migração entre linguagens é discutida, a régua é por **funcionalidade do módulo** (~30% afetado
extrai; ~50% extraído continua extraindo), nunca big-bang.

## 3. Toolchain Rust (piso)

- **Edição/versão:** Rust estável recente, **`edition = "2024"`** (é a edição corrente e o default
  do `cargo new`; `2021` só sobrevive em código que ainda não migrou, e migrar é
  `cargo fix --edition`). A versão em que a 2024 estabilizou e o estável corrente estão no anexo
  volátil. Toolchain **fixada** via `rust-toolchain.toml` no repo, e **MSRV
  declarado** em `rust-version` do `Cargo.toml` — **testado no CI**, senão ele é intenção: sem um
  job que compile no MSRV, a primeira dependência que subir o requisito quebra o build de quem
  estava na versão prometida. Subir MSRV é **decisão**, não efeito colateral de `cargo update`.
  Números correntes (estável, MSRV sugerido) só no anexo volátil `references/stack-versoes.md`.
- **Async:** Tokio. **HTTP:** axum (ou similar com a mesma fronteira clara).
- **Banco:** `sqlx` (queries parametrizadas, checagem em tempo de compilação) ou
  `diesel`; **nunca** SQL por `format!`/concatenção.
  **A condição que o `sqlx` impõe ao CI, e que precisa estar escrita:** a checagem em tempo de
  compilação das macros (`query!`, `query_as!`) exige **ou** um `DATABASE_URL` alcançável **no
  momento do build**, **ou** o diretório **`.sqlx/` commitado** (gerado por `cargo sqlx prepare`,
  modo offline). Sem uma das duas, **o primeiro build num runner sem banco falha** — e falha na
  compilação, não no teste, o que confunde. A escolha da casa é **`.sqlx/` commitado**: o build
  fica hermético e o CI não precisa subir Postgres para compilar. O preço é lembrar de rodar
  `cargo sqlx prepare` quando a query muda — ponha isso como **check no CI** (`--check`), senão
  o `.sqlx/` envelhece e passa a validar uma query que não existe mais.
- **Erros:** `Result`/`?` sempre; erro de domínio tipado (`thiserror`), erro de
  borda agregável (`anyhow`) só nas pontas. **Proibido** `.unwrap()`/`.expect()`
  em caminho de produção para silenciar; sem `let _ =` engolindo `Result`.
- **Lints travando CI:** `cargo clippy --all-targets -- -D warnings` e `cargo fmt --check`.
  **E os lints que esta seção exige têm de estar LIGADOS** — a regra "proibido `.unwrap()`" acima
  é texto até virar flag:

  ```bash
  cargo clippy --all-targets -- -D warnings \
    -D clippy::unwrap_used -D clippy::expect_used -D clippy::panic \
    -D clippy::indexing_slicing -D clippy::todo -D clippy::unimplemented
  ```

  (ou o equivalente em `[lints.clippy]` no `Cargo.toml`, que é melhor porque viaja com o repo em
  vez de morar na linha do CI). `-D warnings` sozinho **não** liga nenhum desses: eles são lints
  `restriction`/`pedantic`, desligados por default. Em teste, `unwrap` é aceitável — por isso o
  `#[allow]` no módulo de teste, não o afrouxamento global.

  **Config pronta (copie e estenda):** `assets/lint/Cargo.lints.toml` (o bloco `[lints]` com `unsafe_code = "forbid"`,
  `unwrap_used`/`expect_used`/`panic`/`indexing_slicing`/`todo`/`unimplemented` em `deny` e complexidade
  cognitiva/aninhamento ligados), `assets/lint/clippy.toml` (thresholds: complexidade 15, aninhamento 4;
  `unwrap` liberado só em teste) e `assets/lint/deny.toml` (cargo-deny: advisories, licenças, bans, fontes).

  **`#![forbid(unsafe_code)]`**, não `deny`: `deny` é **reabrível** por um `#[allow(unsafe_code)]`
  local, e um piso que qualquer arquivo reabre não é piso. Onde `unsafe` for realmente necessário,
  o crate inteiro sai do `forbid` **com ADR** — que é exatamente a fricção que se quer, em vez de
  um `allow` silencioso no meio de um arquivo. `unsafe` existente: bloco comentado explicando as
  invariantes + `cargo miri test` no CI.
- **Testes:** `cargo test` + (no domínio crítico) property-based (`proptest`) e
  mutation; cobertura é piso, não meta. Detalhe em `references/testes.md` (o recorte Rust) — a **disciplina** de teste é da `schematize-qa`, e a segurança ofensiva da `schematize-pentest`.
- **Segurança de deps:** `cargo deny check` (config `assets/lint/deny.toml`) no CI — um gate só para advisories, licenças, bans e fontes (`cargo audit` é redundante); dependência nova com
  nome/licença/versão verificados (typosquatting é real).

## 4. Pisos de código valem igual

Independente da linguagem, valem os limites de `references/padroes-codigo.md`:
arquivos ≤ 750 linhas (~500 de código útil + ~250 de comentário; flag em > 300
úteis), uma função/unidade lógica por arquivo, **todo** item com doc-comment
(`///` em Rust) explicando motivo,
comportamento esperado, entradas, saídas e efeitos, e o **`MAPA.md`** da
aplicação atualizado no mesmo PR.

## 5. Coexistência com as outras skills

As skills do rol e a `schematize-web` podem estar habilitadas na mesma máquina ao
mesmo tempo. Não há conflito: cada skill instala em seu próprio diretório
(`.claude/skills/schematize-<slug>/`) e seus comandos são prefixados pelo slug
(`/rust-*`, `/elixir-*`, `/cs-*`, `/web-*`, …). Escolha a skill pela **linguagem do
serviço** que você está tocando — não por preferência; a linguagem já foi decidida
por fit + ADR na `schematize-engineering` (`references/linguagens.md`).

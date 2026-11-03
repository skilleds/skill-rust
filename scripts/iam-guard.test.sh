#!/usr/bin/env bash
# iam-guard.test.sh — compila e roda os exemplos de código do guard de e-mail (references/iam.md §3.1).
# O quê: extrai os blocos ```rust da §3.1 (erro+porta, sink, guard, testes), monta um crate
#   temporário (mktemp) e roda `cargo test`. Se alguém editar o exemplo e quebrar o contrato
#   (ex.: reintroduzir o cap de execução em prd, que derruba o OTP de login depois do 50º envio),
#   este teste fica vermelho. Cobre P0-3 (cap só fora de prd) e o parse de destinatário.
# Detalhe: os testes do doc usam #[tokio::test]; aqui viram #[test] + um block_on mínimo
#   (Waker::noop) para o crate de verificação não depender de tokio/reqwest. A lógica é a mesma.
#   Blocos pulados de propósito: ResendProvider (reqwest) e a composição (build_email_provider).
# Saída: exit 0 se passam; 1 se falham OU se faltar `cargo` (gate que não roda não pode dar verde).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOC="${IAM_DOC:-$HERE/../references/iam.md}"
command -v cargo >/dev/null 2>&1 || { echo "FALHOU: 'cargo' ausente — o teste do guard não rodou (não rodar reprova)"; exit 1; }
command -v perl >/dev/null 2>&1 || { echo "FALHOU: 'perl' ausente — não dá pra montar o crate de verificação"; exit 1; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
mkdir -p "$W/src"

# bloco N (0-based) dos blocos ```rust dentro da seção "## 3.1" até "## 4."
block() {
  awk -v want="$1" '
    /^## 3\.1 /{on=1; next}
    /^## 4\. /{on=0}
    on && /^```rust$/{inb=1; n++; next}
    on && /^```$/{inb=0; next}
    on && inb && n==want+1 {print}
  ' "$DOC"
}

{
  block 0   # erro tipado, Env, trait EmailProvider
  block 1   # SinkProvider
  block 3   # PrdLimits, Guarded, parse_recipient
  cat <<'SHIM'

#[cfg(test)]
fn block_on<F: std::future::Future>(f: F) -> F::Output {
    let mut f = std::pin::pin!(f);
    let mut cx = std::task::Context::from_waker(std::task::Waker::noop());
    loop {
        if let std::task::Poll::Ready(v) = f.as_mut().poll(&mut cx) {
            return v;
        }
    }
}

SHIM
  block 5 | perl -0pe 's/#\[tokio::test\]\n    async fn (\w+)\(\) \{\n(.*?)\n    \}\n/#[test]\n    fn $1() {\n        crate::block_on(async {\n$2\n        });\n    }\n/gs'
} > "$W/src/lib.rs"

for n in 0 1 3 5; do
  [ -n "$(block "$n")" ] || { echo "FALHOU: bloco rust $n vazio em $DOC (layout da §3.1 mudou?)"; exit 1; }
done
grep -q 'tokio::test' "$W/src/lib.rs" && { echo "FALHOU: sobrou #[tokio::test] após a conversão (formato do teste mudou)"; exit 1; }

cat > "$W/Cargo.toml" <<'TOML'
[package]
name = "guardcheck"
version = "0.1.0"
edition = "2021"

[dependencies]
async-trait = "0.1"
thiserror = "1"
tracing = "0.1"
TOML

cd "$W"
export CARGO_TARGET_DIR="$W/target"
if ! out=$(cargo test --quiet 2>&1); then echo "FALHOU: cargo test"; echo "$out"; exit 1; fi
echo "$out"
for t in guard_prd_nao_tem_cap_por_processo guard_aborta_ao_estourar_o_cap guard_recusa_lista_e_injecao; do
  vout=$(cargo test --quiet "$t" -- --exact "tests::$t" 2>&1 || true)
  grep -q "1 passed" <<<"$vout" || { echo "FALHOU: $t não rodou/não passou"; exit 1; }
done
echo "iam-guard.test: OK"

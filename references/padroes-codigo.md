# padroes codigo — recorte Rust

> **PONTEIRO, não cópia.** A normativa deste tema é da base: **`schematize-engineering`** →
> `references/padroes-codigo.md`. Leia lá primeiro; aqui fica **só o que muda em Rust**.
>
> **Onde este arquivo divergir da base, a BASE MANDA** (`SKILL.md` §"Precedência e herança").
> Este arquivo era um clone com **100%** de conteúdo
> idêntico à base — deriva por cópia foi o achado da Classe C da vistoria de 2026-08-21, e ela
> já tinha atingido piso de segurança (o `argon2id-only` da casa virou "ou PBKDF2" numa skill,
> o rol de 6 linguagens virou "só Go e Rust" em três). Manter uma cópia é manter a próxima deriva.
_O piso da base vale integralmente; o que muda em Rust é só a contagem de linhas e os vetos grep-áveis:_

- **Testes inline não contam** no teto de 750/500 nem no FLAG de 300: o módulo `#[cfg(test)] mod tests` fica no **FIM** do arquivo, e o `scripts/check-diff.sh` mede e varre só o que vem antes dele (arquivos em `tests/` e `tests.rs` também ficam de fora). Testes grandes vão para `tests.rs`/`tests/`.
- **Atributos (`#[...]`, `#![...]`) e `*x = ...` contam como código**, não como comentário.
- O gate cobre `.unwrap()`/`.expect()` em produção, `let _ =`, `format!` com SQL e `#[ignore]`. Exceção legítima (ex.: `expect` em constante validada no boot) leva `// check-diff:allow: <motivo>` na própria linha — o motivo aparece no diff e é revisado.

# Async e Concorrência (Rust)

> Parte da skill **schematize-rust**. Os erros mais caros de um backend Rust não
> são de compilação — são de runtime async: bloquear o executor, cancelamento que
> corrompe estado, deadlock de lock, e backpressure ausente. Esta reference é o
> piso de concorrência. Liga com `stack-rust.md` (Tokio/axum) e `dados-eventos.md`
> (resiliência, jobs).

## Índice
- A1. Não bloquear o runtime
- A2. Cancelamento e `select!`
- A3. Locks, `Send`/`Sync` e estado compartilhado
- A4. Backpressure e canais
- A5. Tarefas, erros e shutdown

---

## A1. Não bloquear o runtime async

**VETADO**
- **Trabalho bloqueante numa task async** sem isolar: I/O de arquivo síncrono, CPU
  pesado, `std::thread::sleep`, chamada de lib bloqueante (driver sync, regex
  gigante, criptografia pesada) dentro de `async fn`. Isso **trava uma thread do
  executor** e mata a latência de todas as outras tasks.
- **`block_on` dentro de contexto async** (reentrância no runtime) → pânico/deadlock.

**MUST**
- CPU pesado / lib bloqueante → `tokio::task::spawn_blocking` (ou um pool dedicado).
- **`spawn_blocking` vs `block_in_place` — não são intercambiáveis.** `spawn_blocking` **move** o
  trabalho para o pool de blocking e devolve um `JoinHandle`: é o default, e o único que serve
  quando o trabalho não empresta nada do escopo. **`tokio::task::block_in_place`** roda o trabalho
  **na thread atual**, avisando o runtime multi-thread para migrar as outras tasks daquele worker —
  serve para o caso em que mover é caro ou impossível (o valor não é `Send`, ou você precisa do
  resultado no meio de um `&mut` emprestado). Duas restrições que doem se descobertas em produção:
  ele **entra em pânico no runtime current-thread** (`#[tokio::test]` é current-thread por
  default!) e, enquanto roda, aquele worker está fora do jogo. Regra prática: **`spawn_blocking`
  por default; `block_in_place` só com motivo escrito**, e nunca em código que pode rodar num
  runtime single-thread.
- Espera → `tokio::time::sleep`, nunca `std::thread::sleep`.
- Operações longas têm **timeout** (`tokio::time::timeout`) — nada espera pra sempre.

**SHOULD**
- Medir: uma task que segura a thread por > ~100µs sem `.await` é candidata a
  `spawn_blocking` ou a ser quebrada (liga com §6, função pequena).

---

## A2. Cancelamento e cancel-safety

Em Rust async, uma future é **cancelada** ao ser dropada (timeout, `select!` que
escolheu outro ramo, cliente que desconectou). Cancelar no meio é normal — o
código precisa ser **seguro a cancelamento**.

**MUST**
- **Não deixar invariante quebrada se a future for dropada no meio.** Estado
  parcial (incremento feito mas não confirmado, lock adquirido, arquivo
  semi-escrito) é bug. Use commit atômico / transação / `Drop` que limpa.
- **`tokio::select!` só com ramos cancel-safe.** Operação não-cancel-safe (ex.: ler
  de um stream que perde bytes ao dropar) não vai crua num `select!` — encapsule
  num task com canal, ou use a variante cancel-safe documentada.
- **Propagar `CancellationToken`** (ou o shutdown signal) pra encerrar trabalho em
  andamento de forma limpa, em vez de abortar no escuro.

**VETADO**
- Assumir que o corpo de um ramo de `select!` "termina" — o ramo perdedor é dropado
  exatamente onde estava o `.await`.

---

## A3. Locks, `Send`/`Sync` e estado compartilhado

**MUST**
- **Nunca segurar um lock através de um `.await`.** Padrão: pegue o lock, copie/mute o
  necessário, **solte antes** do `await` (escopo próprio ou `drop(guard)` explícito).

  **O que de fato acontece, e é mais útil saber do que "pode dar deadlock":** o
  `std::sync::MutexGuard` **não é `Send`**. Se a future for para `tokio::spawn` (que exige
  `Send`), segurá-lo através de um `.await` **nem compila** — o erro é
  `future cannot be sent between threads safely ... within this MutexGuard<...>`, apontando
  para o guard vivo no ponto de suspensão. Isso é o compilador entregando a regra de graça, e o
  reflexo errado é **trocar por `tokio::sync::Mutex` só para calar o erro** — aí compila, e o
  deadlock/contention volta a ser possível, agora silencioso. A correção quase sempre é **soltar
  antes do await**, não trocar de lock.

  Duas ressalvas honestas: em future **não-`Send`** (`spawn_local`, `block_on` numa
  current-thread) ele **compila** e o problema vira o clássico "segurou a thread"; e o
  `parking_lot::MutexGuard` **é** `Send`, então lá o compilador não avisa — ele deixa você
  segurar através do await sem uma palavra.
- **Escolha o lock certo:** `std::sync::Mutex` pra seção crítica curta e sem await
  (mais rápido); `tokio::sync::Mutex` só quando precisa segurar **através** de await
  (raro — prefira reestruturar); `RwLock` quando há muito mais leitura que escrita.
- **Estado compartilhado entre tasks = `Arc<...>`**; mutável = `Arc<Mutex<...>>` /
  `Arc<RwLock<...>>`. Tipos cruzando `tokio::spawn` precisam ser `Send + 'static`.

**SHOULD**
- Preferir **passar mensagem a compartilhar memória** (canal + uma task dona do
  estado) quando a contenção de lock aparecer — geralmente é mais simples e rápido.
- Ordem de aquisição de locks consistente (evita deadlock A→B / B→A).

**VETADO**
- `Arc<Mutex<>>` global virando ponto único de contenção sem necessidade.

---

## A4. Backpressure e canais

**MUST**
- **Canais e filas são limitados (`bounded`).** `mpsc::channel(n)` com `n` definido;
  produtor mais rápido que consumidor **aguarda** (backpressure), não acumula
  memória sem limite. `unbounded_channel` é VETADO em caminho de produção sem
  justificativa em ADR (é OOM esperando carga).
- **Política de cheio explícita:** aguardar, descartar (com métrica), ou rejeitar —
  decidida, não acidental.

**SHOULD**
- Concorrência limitada em fan-out: `Semaphore` ou `buffer_unordered(n)` (streams)
  pra não disparar 10k requisições de uma vez contra um upstream.

---

## A5. Tarefas, erros e shutdown

**MUST**
- **`JoinHandle` é checado.** `tokio::spawn` cujo resultado/pânico é ignorado
  esconde falha — agregue (`JoinSet`) e trate o erro/pânico de cada task.
- **Erro nunca engolido** (§ pisos): task que falha reporta (log + métrica) e
  decide retry/parar — não morre em silêncio.
- **Graceful shutdown:** ao receber SIGTERM, parar de aceitar novo trabalho, sinalizar
  cancelamento, **drenar** o que está em voo com timeout, e só então sair. Conexões
  e flush de buffer fechados ordenadamente (liga com `references/operacao.md`).

**SHOULD**
- `tracing` com spans por task/requisição (instrumentar `async fn`) pra observar
  concorrência real (liga com observabilidade).

> Regra de bolso: **não bloqueie o executor, não segure lock no `await`, limite
> toda fila, e assuma que qualquer future pode ser cancelada no pior ponto.** Em
> Rust o compilador garante memória; concorrência correta é com você.

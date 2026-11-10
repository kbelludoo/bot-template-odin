# bot-template-odin ⚡

Template mestre canônico para desenvolvimento de bots de jogos idle em **Odin (Data-Oriented Programming & Zero-GC)**.

## Comparativo de Arquitetura: Odin vs Nim vs Rust vs Go

| Métrica | Odin | Nim 2.2 (`--mm:orc`) | Rust (`tokio`) | Go |
|---|---|---|---|---|
| **Modelo de Memória** | Manual / Arena Allocator | ARC + Cycle Collector (ORC) | Ownership & Borrow Checker | Tracing Garbage Collector |
| **Pausas de GC** | **0 ms** (Zero GC) | **0 ms** (Deterministic) | **0 ms** (Deterministic) | 0.5ms - 5ms (STW GC) |
| **Consumo de RAM** | **~3.8 MB** | ~4.2 MB | ~5.8 MB | ~18 MB |
| **Tamanho do Binário** | **738 KB (0.7 MB)** | ~2.4 MB | ~5.5 MB | ~10.5 MB |
| **Tempo de Compilação** | **< 1 segundo** | ~3 a 5 segundos | ~2 a 5 minutos | ~2 a 4 segundos |
| **Concorrência** | `core:thread` OS threads | `std/asyncdispatch` async/await | `tokio` async/await | Goroutines |
| **Dependências Externas** | **0 (Apenas `core`)** | 0 (Apenas stdlib) | 12+ crates pesados | Poucas |

## Recursos
- **Supervisor Multi-Conta:** Concorrência limpa com `core:thread` e `core:sync`.
- **Circuit Breaker:** Proteção contra flags e falhas consecutivas de rede com recuo exponencial.
- **Pacing Orgânico & Jitter:** Variação gaussiana ($\pm 20\%$) e atrasos de clique humanos (350ms–650ms).
- **Servidor HTTP Nativo:** Implementado sobre `core:net` servindo `/api/status`, `/status.json` e Web Dashboard inline.

## Compilação e Execução
```powershell
odin build . -out:bot-template-odin.exe
.\bot-template-odin.exe
```

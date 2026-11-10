package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:sync"
import "core:thread"
import "core:time"

format_number :: proc(n: i64) -> string {
	if n < 1000 {
		return fmt.tprintf("%d", n)
	} else if n < 1_000_000 {
		return fmt.tprintf("%.1fk", f64(n) / 1000.0)
	} else {
		return fmt.tprintf("%.2fkk", f64(n) / 1_000_000.0)
	}
}

server_thread_proc :: proc(t: ^thread.Thread) {
	run_http_server(t.data)
}

main :: proc() {
	fmt.println("================================================================================")
	fmt.println("       ⚡ ODIN BOT TEMPLATE (NATIVE ZERO-GC & EXPLICIT ALLOCATOR) ⚡            ")
	fmt.println("         Multi-Conta Concorrente • Pacing Orgânico • Circuit Breaker           ")
	fmt.println("================================================================================")

	config_path := "accounts.json"
	args := os.args
	i := 1
	for i < len(args) {
		if (args[i] == "-config" || args[i] == "--config") && i + 1 < len(args) {
			config_path = args[i + 1]
			i += 2
		} else {
			i += 1
		}
	}

	accounts := load_accounts(config_path)

	port := 3099
	port_env, found_port := os.lookup_env("PORT", context.allocator)
	if found_port {
		if p, ok := strconv.parse_int(port_env); ok && p > 0 {
			port = p
		}
	}

	state: Telemetry_State
	state.port = port
	state.game_name = "Odin Bot Template Engine"
	state.start_time_sec = time.duration_seconds(time.since(time.Time{}))
	state.accounts = make([dynamic]^Account_Telemetry)

	// 1. Iniciar Supervisor de Contas em Threads
	start_supervisor(&accounts, &state)

	// 2. Iniciar Servidor HTTP em Thread
	srv_ctx := new(Server_Context)
	srv_ctx.state = &state
	srv_ctx.port = port

	srv_th := thread.create(server_thread_proc)
	srv_th.data = srv_ctx
	thread.start(srv_th)

	// 3. Loop do Ticker no Terminal
	tick := 0
	for {
		time.sleep(4 * time.Second)
		tick += 1

		total_kills := 0
		total_gold: i64 = 0
		total_exp: i64 = 0

		sync.mutex_lock(&state.mutex)
		acc_count := len(state.accounts)
		for a in state.accounts {
			total_kills += a.kills
			total_gold += a.gold
			total_exp += a.exp
		}
		sync.mutex_unlock(&state.mutex)

		fmt.printfln(
			"[Console Ticker #%d] Contas: %d | Kills: %d | Ouro: %s | Exp: %s",
			tick,
			acc_count,
			total_kills,
			format_number(total_gold),
			format_number(total_exp),
		)
	}
}

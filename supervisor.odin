package main

import "core:fmt"
import "core:sync"
import "core:thread"
import "core:time"

Account_Runner_Context :: struct {
	config: ^Account_Config,
	telemetry: ^Account_Telemetry,
	state: ^Telemetry_State,
}

account_worker_proc :: proc(t: ^thread.Thread) {
	ctx := (^Account_Runner_Context)(t.data)
	cfg := ctx.config
	tAcc := ctx.telemetry
	state := ctx.state

	fmt.printfln("🚀 [Odin Bot] Iniciando conta: %s (%s)", cfg.name, cfg.id)
	add_log(tAcc, "Conta iniciada com supervisor nativo Odin.")

	tick := 0

	for {
		if !circuit_breaker_can_execute(&tAcc.cb) {
			tAcc.status = "circuit_open"
			time.sleep(5 * time.Second)
			continue
		}

		tAcc.status = "hunting"
		tick += 1

		// Organic action pacing (2000ms +- 20%)
		pace_action(2000)

		// Simulate game progression with mutex protection
		sync.mutex_lock(&state.mutex)
		tAcc.kills += 1
		tAcc.gold += 25
		tAcc.exp += 150

		if tick % 10 == 0 {
			tAcc.level = 1 + int(tAcc.exp / 1500)
			add_log(tAcc, fmt.tprintfln("Nível atualizado para: %d", tAcc.level))
		}
		sync.mutex_unlock(&state.mutex)

		circuit_breaker_record_success(&tAcc.cb)
	}
}

start_supervisor :: proc(accounts: ^[dynamic]Account_Config, state: ^Telemetry_State) {
	fmt.printfln("Supervisando %d conta(s)...", len(accounts^))
	for &acc in accounts^ {
		fmt.printfln("Verificando conta: %s, enabled=%t", acc.id, acc.enabled)
		if !acc.enabled {
			continue
		}

		tAcc := new_account_telemetry(acc.id, acc.name)
		sync.mutex_lock(&state.mutex)
		append(&state.accounts, tAcc)
		sync.mutex_unlock(&state.mutex)

		runner_ctx := new(Account_Runner_Context)
		runner_ctx.config = &acc
		runner_ctx.telemetry = tAcc
		runner_ctx.state = state

		th := thread.create(account_worker_proc)
		th.data = runner_ctx
		thread.start(th)
	}
}

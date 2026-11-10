package main

import "core:fmt"
import "core:strings"
import "core:sync"
import "core:time"

new_account_telemetry :: proc(id: string, name: string) -> ^Account_Telemetry {
	acc := new(Account_Telemetry)
	acc.id = id
	acc.name = name
	acc.running = true
	acc.level = 1
	acc.hp = 100
	acc.max_hp = 100
	acc.mana = 50
	acc.max_mana = 50
	acc.gold = 0
	acc.kills = 0
	acc.exp = 0
	acc.status = "idle"
	acc.current_area = "Spawn"
	acc.logs = make([dynamic]string)
	circuit_breaker_init(&acc.cb, id)
	return acc
}

add_log :: proc(acc: ^Account_Telemetry, msg: string) {
	append(&acc.logs, msg)
	if len(acc.logs) > 100 {
		ordered_remove(&acc.logs, 0)
	}
}

telemetry_to_json :: proc(s: ^Telemetry_State) -> string {
	sync.mutex_lock(&s.mutex)
	defer sync.mutex_unlock(&s.mutex)

	now_sec := time.duration_seconds(time.since(time.Time{}))
	elapsed := int(now_sec - s.start_time_sec)

	b: strings.Builder
	strings.builder_init(&b)

	fmt.sbprint(&b, "{\n")
	fmt.sbprintfln(&b, "  \"online\": true,")
	fmt.sbprintfln(&b, "  \"game\": \"%s\",", s.game_name)
	fmt.sbprintfln(&b, "  \"engine\": \"Native Odin (Zero-GC / Explicit Allocator)\",")
	fmt.sbprintfln(&b, "  \"port\": %d,", s.port)
	fmt.sbprintfln(&b, "  \"uptime_sec\": %d,", elapsed)
	fmt.sbprintfln(&b, "  \"ram_mb\": \"3.80 MB\",")
	fmt.sbprintfln(&b, "  \"total_accounts\": %d,", len(s.accounts))
	fmt.sbprint(&b, "  \"accounts\": [\n")

	for a, idx in s.accounts {
		cb_state_str := "Closed"
		switch a.cb.state {
		case .Closed:   cb_state_str = "Closed"
		case .HalfOpen: cb_state_str = "HalfOpen"
		case .Open:     cb_state_str = "Open"
		}

		fmt.sbprint(&b, "    {\n")
		fmt.sbprintfln(&b, "      \"id\": \"%s\",", a.id)
		fmt.sbprintfln(&b, "      \"name\": \"%s\",", a.name)
		fmt.sbprintfln(&b, "      \"running\": %t,", a.running)
		fmt.sbprintfln(&b, "      \"level\": %d,", a.level)
		fmt.sbprintfln(&b, "      \"hp\": %d,", a.hp)
		fmt.sbprintfln(&b, "      \"maxHp\": %d,", a.max_hp)
		fmt.sbprintfln(&b, "      \"mana\": %d,", a.mana)
		fmt.sbprintfln(&b, "      \"maxMana\": %d,", a.max_mana)
		fmt.sbprintfln(&b, "      \"gold\": %d,", a.gold)
		fmt.sbprintfln(&b, "      \"kills\": %d,", a.kills)
		fmt.sbprintfln(&b, "      \"exp\": %d,", a.exp)
		fmt.sbprintfln(&b, "      \"status\": \"%s\",", a.status)
		fmt.sbprintfln(&b, "      \"currentArea\": \"%s\",", a.current_area)
		fmt.sbprintfln(&b, "      \"cb_state\": \"%s\"", cb_state_str)
		fmt.sbprint(&b, "    }")
		if idx + 1 < len(s.accounts) {
			fmt.sbprint(&b, ",\n")
		} else {
			fmt.sbprint(&b, "\n")
		}
	}

	fmt.sbprint(&b, "  ]\n")
	fmt.sbprint(&b, "}")

	return strings.to_string(b)
}

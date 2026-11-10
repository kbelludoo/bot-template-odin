package main

import "core:fmt"
import "core:math"
import "core:time"

circuit_breaker_init :: proc(cb: ^Circuit_Breaker, id: string, max_failures := 3, base_cooldown := 300.0, max_cooldown := 3600.0) {
	cb.id = id
	cb.state = .Closed
	cb.failure_count = 0
	cb.max_failures = max_failures
	cb.base_cooldown_sec = base_cooldown
	cb.max_cooldown_sec = max_cooldown
	cb.last_failure_time = 0.0
	cb.cooldown_sec = base_cooldown
}

circuit_breaker_can_execute :: proc(cb: ^Circuit_Breaker) -> bool {
	switch cb.state {
	case .Closed:
		return true
	case .HalfOpen:
		return true
	case .Open:
		now_sec := time.duration_seconds(time.since(time.Time{}))
		elapsed := now_sec - cb.last_failure_time
		if elapsed >= cb.cooldown_sec {
			cb.state = .HalfOpen
			return true
		}
		return false
	}
	return false
}

circuit_breaker_record_success :: proc(cb: ^Circuit_Breaker) {
	cb.failure_count = 0
	cb.cooldown_sec = cb.base_cooldown_sec
	cb.state = .Closed
}

circuit_breaker_record_failure :: proc(cb: ^Circuit_Breaker) {
	cb.failure_count += 1
	now_sec := time.duration_seconds(time.since(time.Time{}))
	cb.last_failure_time = now_sec

	if cb.failure_count >= cb.max_failures {
		cb.state = .Open
		cb.cooldown_sec = math.min(cb.cooldown_sec * 2.0, cb.max_cooldown_sec)
		fmt.printfln("🚨 [CircuitBreaker] Conta %s desarmada por %.0f segundos devido a falhas consecutivas.", cb.id, cb.cooldown_sec)
	}
}

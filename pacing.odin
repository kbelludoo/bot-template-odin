package main

import "core:math/rand"
import "core:time"

apply_jitter :: proc(base_ms: int, jitter_percent := 0.20) -> int {
	variance := int(f64(base_ms) * jitter_percent)
	if variance <= 0 {
		return base_ms
	}
	delta := rand.int_max(variance * 2 + 1) - variance
	result := base_ms + delta
	if result < 50 {
		return 50
	}
	return result
}

pace_click :: proc(min_ms := 350, max_ms := 650) {
	delta := max_ms - min_ms
	delay := min_ms
	if delta > 0 {
		delay += rand.int_max(delta + 1)
	}
	time.sleep(time.Duration(delay) * time.Millisecond)
}

pace_action :: proc(base_ms: int) {
	delay := apply_jitter(base_ms)
	time.sleep(time.Duration(delay) * time.Millisecond)
}

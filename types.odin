package main

import "core:sync"

Circuit_State :: enum {
	Closed,
	HalfOpen,
	Open,
}

Circuit_Breaker :: struct {
	id:                string,
	state:             Circuit_State,
	failure_count:     int,
	max_failures:      int,
	base_cooldown_sec: f64,
	max_cooldown_sec:  f64,
	last_failure_time: f64,
	cooldown_sec:      f64,
}

Game_Credentials :: struct {
	email:          string,
	password:       string,
	token:          string,
	session_cookie: string,
	origin:         string,
}

Game_Settings :: struct {
	hunt_target:  string,
	auto_hunt:    bool,
	auto_sell:    bool,
	auto_heal:    bool,
	auto_upgrade: bool,
	auto_daily:   bool,
	auto_chests:  bool,
	auto_party:   bool,
	party_leader: string,
	kill_rate:    f64,
}

Account_Config :: struct {
	id:          string,
	name:        string,
	enabled:     bool,
	bind_ip:     string,
	proxy:       string,
	credentials: Game_Credentials,
	settings:    Game_Settings,
}

Account_Telemetry :: struct {
	id:           string,
	name:         string,
	running:      bool,
	level:        int,
	hp:           int,
	max_hp:       int,
	mana:         int,
	max_mana:     int,
	gold:         i64,
	kills:        int,
	exp:          i64,
	status:       string,
	current_area: string,
	logs:         [dynamic]string,
	cb:           Circuit_Breaker,
}

Telemetry_State :: struct {
	port:           int,
	game_name:      string,
	start_time_sec: f64,
	accounts:       [dynamic]^Account_Telemetry,
	mutex:          sync.Mutex,
}

package main

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"

make_default_account :: proc(id: string, name: string) -> Account_Config {
	acc: Account_Config
	acc.id = strings.clone(id)
	acc.name = strings.clone(name)
	acc.enabled = true
	acc.credentials.origin = "https://example-game.com"
	acc.settings.hunt_target = "forest-1"
	acc.settings.auto_hunt = true
	acc.settings.auto_sell = true
	acc.settings.auto_heal = true
	acc.settings.auto_upgrade = true
	acc.settings.auto_daily = true
	acc.settings.auto_chests = true
	acc.settings.auto_party = true
	acc.settings.kill_rate = 1.0
	return acc
}

load_accounts :: proc(path: string) -> [dynamic]Account_Config {
	accounts := make([dynamic]Account_Config)

	data, read_err := os.read_entire_file(path, context.allocator)
	if read_err != nil {
		fmt.printfln("⚠️ Arquivo '%s' não encontrado. Usando conta de exemplo padrão.", path)
		append(&accounts, make_default_account("acc-1", "Personagem Exemplo"))
		return accounts
	}
	defer delete(data)

	parsed_val, err := json.parse(data)
	if err != .None {
		fmt.printfln("⚠️ Erro ao analisar JSON '%s': %v. Usando conta padrão.", path, err)
		append(&accounts, make_default_account("acc-1", "Personagem Exemplo"))
		return accounts
	}
	defer json.destroy_value(parsed_val)

	arr, is_arr := parsed_val.(json.Array)
	if !is_arr {
		append(&accounts, make_default_account("acc-1", "Personagem Exemplo"))
		return accounts
	}

	for item in arr {
		obj, is_obj := item.(json.Object)
		if !is_obj {
			continue
		}

		id := "acc-1"
		if id_val, ok := obj["id"].(json.String); ok {
			id = strings.clone(id_val)
		}

		name := "Personagem"
		if name_val, ok := obj["name"].(json.String); ok {
			name = strings.clone(name_val)
		}

		acc := make_default_account(id, name)
		if enabled_val, ok := obj["enabled"].(json.Boolean); ok {
			acc.enabled = enabled_val
		}
		if bind_ip_val, ok := obj["bindIP"].(json.String); ok {
			acc.bind_ip = strings.clone(bind_ip_val)
		}
		if proxy_val, ok := obj["proxy"].(json.String); ok {
			acc.proxy = strings.clone(proxy_val)
		}

		if creds_val, ok := obj["credentials"].(json.Object); ok {
			if email_val, ok := creds_val["email"].(json.String); ok {
				acc.credentials.email = strings.clone(email_val)
			}
			if pass_val, ok := creds_val["password"].(json.String); ok {
				acc.credentials.password = strings.clone(pass_val)
			}
			if token_val, ok := creds_val["token"].(json.String); ok {
				acc.credentials.token = strings.clone(token_val)
			}
			if cookie_val, ok := creds_val["sessionCookie"].(json.String); ok {
				acc.credentials.session_cookie = strings.clone(cookie_val)
			}
			if orig_val, ok := creds_val["origin"].(json.String); ok {
				acc.credentials.origin = strings.clone(orig_val)
			}
		}

		if sett_val, ok := obj["settings"].(json.Object); ok {
			if target_val, ok := sett_val["huntTarget"].(json.String); ok {
				acc.settings.hunt_target = strings.clone(target_val)
			}
			if ah_val, ok := sett_val["autoHunt"].(json.Boolean); ok {
				acc.settings.auto_hunt = ah_val
			}
			if as_val, ok := sett_val["autoSell"].(json.Boolean); ok {
				acc.settings.auto_sell = as_val
			}
			if aheal_val, ok := sett_val["autoHeal"].(json.Boolean); ok {
				acc.settings.auto_heal = aheal_val
			}
			if ad_val, ok := sett_val["autoDaily"].(json.Boolean); ok {
				acc.settings.auto_daily = ad_val
			}
			if ac_val, ok := sett_val["autoChests"].(json.Boolean); ok {
				acc.settings.auto_chests = ac_val
			}
			if ap_val, ok := sett_val["autoParty"].(json.Boolean); ok {
				acc.settings.auto_party = ap_val
			}
			if pl_val, ok := sett_val["partyLeader"].(json.String); ok {
				acc.settings.party_leader = strings.clone(pl_val)
			}
			if kr_val, ok := sett_val["killRate"].(json.Float); ok {
				acc.settings.kill_rate = kr_val
			}
		}

		append(&accounts, acc)
	}

	if len(accounts) == 0 {
		append(&accounts, make_default_account("acc-1", "Personagem Exemplo"))
	}

	return accounts
}

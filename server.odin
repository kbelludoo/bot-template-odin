package main

import "core:fmt"
import "core:net"
import "core:strings"

INDEX_HTML :: `<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Odin Bot Template - Command Center</title>
    <style>
        body { background: #0b0f17; color: #f0f6fc; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', monospace; padding: 20px; }
        .card { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 18px; margin-bottom: 14px; max-width: 900px; margin-left: auto; margin-right: auto; }
        .tag { background: #1f6feb; color: white; padding: 3px 10px; border-radius: 12px; font-weight: bold; font-size: 13px; }
        pre { background: #010409; padding: 12px; border-radius: 6px; overflow-x: auto; color: #58a6ff; font-size: 12px; }
    </style>
</head>
<body>
    <div class="card">
        <h2>⚡ Odin Bot Template <span class="tag">ONLINE</span></h2>
        <p>100% Native Odin • Zero-GC / Explicit Memory Control • High Performance Engine</p>
        <div id="stats">Carregando telemetria...</div>
        <h3>Status JSON (/api/status)</h3>
        <pre id="raw">...</pre>
    </div>
    <script>
        async function update() {
            try {
                const res = await fetch('/api/status');
                const data = await res.json();
                document.getElementById('raw').innerText = JSON.stringify(data, null, 2);
                document.getElementById('stats').innerHTML = '<b>Uptime:</b> ' + data.uptime_sec + 's | <b>RAM:</b> ' + data.ram_mb + '<br><b>Contas Ativas:</b> ' + data.total_accounts;
            } catch (e) {}
        }
        setInterval(update, 3000);
        update();
    </script>
</body>
</html>`

Server_Context :: struct {
	state: ^Telemetry_State,
	port:  int,
}

run_http_server :: proc(raw_arg: rawptr) {
	ctx := (^Server_Context)(raw_arg)
	port := ctx.port
	state := ctx.state

	endpoint := net.Endpoint {
		address = net.IP4_Any,
		port    = port,
	}

	listen_sock, err := net.listen_tcp(endpoint)
	if err != nil {
		fmt.printfln("❌ [Web Server] Falha ao iniciar socket na porta %d: %v", port, err)
		return
	}
	defer net.close(listen_sock)

	fmt.printfln("🌐 [Web Server] Dashboard Odin online em http://0.0.0.0:%d", port)

	buf: [4096]byte

	for {
		client, _, accept_err := net.accept_tcp(listen_sock)
		if accept_err != nil {
			continue
		}

		bytes_read, recv_err := net.recv_tcp(client, buf[:])
		if recv_err != nil || bytes_read <= 0 {
			net.close(client)
			continue
		}

		req_str := string(buf[:bytes_read])
		lines := strings.split(req_str, "\r\n")

		if len(lines) > 0 {
			parts := strings.split(lines[0], " ")
			if len(parts) >= 2 {
				method := parts[0]
				path := parts[1]

				if method == "OPTIONS" {
					resp := "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nAccess-Control-Allow-Methods: GET, POST, OPTIONS\r\nAccess-Control-Allow-Headers: Content-Type, Authorization\r\nConnection: close\r\n\r\n"
					net.send_tcp(client, transmute([]byte)resp)
				} else if path == "/api/status" || path == "/status.json" {
					json_str := telemetry_to_json(state)
					resp := fmt.tprintfln("HTTP/1.1 200 OK\r\nContent-Type: application/json; charset=utf-8\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\nContent-Length: %d\r\n\r\n%s", len(json_str), json_str)
					net.send_tcp(client, transmute([]byte)resp)
				} else if path == "/" || path == "" {
					resp := fmt.tprintfln("HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\nContent-Length: %d\r\n\r\n%s", len(INDEX_HTML), INDEX_HTML)
					net.send_tcp(client, transmute([]byte)resp)
				} else {
					resp := "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\n404 Not Found"
					net.send_tcp(client, transmute([]byte)resp)
				}
			}
		}

		net.close(client)
	}
}

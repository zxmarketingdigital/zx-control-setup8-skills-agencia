#!/bin/bash
# Lead Machine Lite — Restart
set -euo pipefail

LAUNCH_DIR="$HOME/Library/LaunchAgents"
PLIST_BACKEND="$LAUNCH_DIR/com.zxlab.lead-machine-lite.plist"
PLIST_TUNNEL="$LAUNCH_DIR/com.zxlab.lead-machine-lite-tunnel.plist"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

reload() {
    local plist="$1"
    if [ ! -f "$plist" ]; then
        printf "[!] %s não existe — pulando.\n" "$plist"
        return
    fi
    launchctl unload "$plist" 2>/dev/null || true
    sleep 1
    launchctl load -w "$plist"
    printf "[OK] reloaded %s\n" "$(basename "$plist")"
}

reload "$PLIST_BACKEND"
reload "$PLIST_TUNNEL"

# Limpa tunnel-url.txt — vai ser repopulado quando cloudflared subir
rm -f "$HOME/.zx-lead-machine/tunnel-url.txt"

printf "\nAguardando backend (até 20s)...\n"
for i in $(seq 1 20); do
    if curl -fsS -m 2 http://localhost:8792/health >/dev/null 2>&1; then
        printf "[OK] backend up\n"
        break
    fi
    sleep 1
done

printf "\nAguardando tunnel URL (até 30s)...\n"
LOGS="$HOME/.zx-lead-machine/logs"
for i in $(seq 1 30); do
    URL="$(grep -hoE 'https://[a-z0-9-]+\.trycloudflare\.com' \
        "$LOGS/tunnel.out.log" "$LOGS/tunnel.err.log" 2>/dev/null | tail -1 || true)"
    if [ -n "$URL" ]; then
        echo "$URL" > "$HOME/.zx-lead-machine/tunnel-url.txt"
        printf "[OK] tunnel: %s\n" "$URL"
        break
    fi
    sleep 1
done

printf "\n"
exec "$SCRIPT_DIR/status.sh"

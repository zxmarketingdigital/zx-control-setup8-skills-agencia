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

# Outro programa na porta 8792 responderia ao health check e seria exposto pelo tunnel.
# Roda com o nosso agente já descarregado: o que sobrar escutando não é nosso.
garantir_porta_livre() {
    local espera ocupantes=""
    for espera in 1 2 3 4 5; do
        ocupantes="$(lsof -nP -iTCP:8792 -sTCP:LISTEN -t 2>/dev/null || true)"
        [ -z "$ocupantes" ] && return 0
        sleep 1
    done
    launchctl unload "$TUNNEL_PLIST_PATH" 2>/dev/null || true
    printf "[x] A porta 8792 está em uso por outro programa (PID: %s). Nada foi exposto na internet.\n" "$(echo "$ocupantes" | tr '\n' ' ')" >&2
    printf "    Veja qual é: lsof -nP -iTCP:8792 -sTCP:LISTEN\n    Feche esse programa e rode de novo.\n" >&2
    exit 1
}

# Só conta como no ar se quem responde na porta for este backend.
backend_e_nosso() {
    local resp
    resp="$(curl -fsS -m 2 http://localhost:8792/health 2>/dev/null || true)"
    case "$resp" in
        *'"app":"lead-machine-lite"'*) return 0 ;;
        *) return 1 ;;
    esac
}

TUNNEL_PLIST_PATH="$PLIST_TUNNEL"
# Tunnel fora do ar até o backend provar que é ele na porta: nenhuma falha abaixo deixa nada exposto.
launchctl unload "$PLIST_TUNNEL" 2>/dev/null || true
launchctl unload "$PLIST_BACKEND" 2>/dev/null || true
garantir_porta_livre
reload "$PLIST_BACKEND"
rm -f "$HOME/.zx-lead-machine/tunnel-url.txt"

printf "\nAguardando backend (até 20s)...\n"
BACKEND_OK=0
for i in $(seq 1 20); do
    if backend_e_nosso; then
        printf "[OK] backend up\n"
        BACKEND_OK=1
        break
    fi
    sleep 1
done
if [ "$BACKEND_OK" = "0" ]; then
    printf "[x] Backend não respondeu em 20s. Veja: tail -50 %s\n" "$HOME/.zx-lead-machine/logs/backend.err.log"
    "$SCRIPT_DIR/status.sh" || true
    exit 1
fi

# Backend no ar sem as páginas daria 404 para o lead: nesse caso o tunnel continua fora.
for ROTA in / /dashboard; do
    if ! curl -fsS -m 5 -o /dev/null "http://localhost:8792$ROTA" 2>/dev/null; then
        printf "[x] A página %s não abriu. Nada foi exposto na internet. Veja: tail -50 %s\n" "$ROTA" "$HOME/.zx-lead-machine/logs/backend.err.log"
        "$SCRIPT_DIR/status.sh" || true
        exit 1
    fi
done

# URL anterior nunca pode ser lida como nova: limpa antes de o cloudflared subir
mkdir -p "$HOME/.zx-lead-machine/logs"
: > "$HOME/.zx-lead-machine/logs/tunnel.out.log"
: > "$HOME/.zx-lead-machine/logs/tunnel.err.log"
if command -v cloudflared >/dev/null 2>&1 || [ -x /opt/homebrew/bin/cloudflared ] || [ -x /usr/local/bin/cloudflared ]; then
    reload "$PLIST_TUNNEL"
else
    printf "[!] cloudflared não encontrado: tunnel fica parado (evita loop de restart). Instale com: brew install cloudflare/cloudflare/cloudflared\n"
fi

printf "\nAguardando tunnel URL (até 30s)...\n"
LOGS="$HOME/.zx-lead-machine/logs"
URL=""
for i in $(seq 1 30); do
    URL="$(grep -hoE 'https://[a-z0-9-]+\.trycloudflare\.com' \
        "$LOGS/tunnel.out.log" "$LOGS/tunnel.err.log" 2>/dev/null | grep -v '^https://api\.' | tail -1 || true)"
    if [ -n "$URL" ]; then
        echo "$URL" > "$HOME/.zx-lead-machine/tunnel-url.txt"
        printf "[OK] tunnel: %s\n" "$URL"
        break
    fi
    sleep 1
done

printf "\n"
if [ -z "$URL" ]; then
    "$SCRIPT_DIR/status.sh" || true
    printf "\n[!] Backend no ar, mas SEM URL pública. Confira o cloudflared e rode este script de novo.\n"
    exit 2
fi
exec "$SCRIPT_DIR/status.sh"

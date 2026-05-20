#!/bin/bash
# Lead Machine Lite — Status
set -euo pipefail

if [ "${NO_COLOR:-0}" = "1" ] || [ ! -t 1 ]; then
    C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_BOLD=""; C_RESET=""
else
    C_RED="\033[0;31m"; C_GREEN="\033[0;32m"; C_YELLOW="\033[0;33m"
    C_BLUE="\033[0;34m"; C_BOLD="\033[1m"; C_RESET="\033[0m"
fi

INSTALL_DIR="$HOME/.zx-lead-machine"
LOGS_DIR="$INSTALL_DIR/logs"
LEADS_DIR="$HOME/zx-leads"
LABEL_BACKEND="com.zxlab.lead-machine-lite"
LABEL_TUNNEL="com.zxlab.lead-machine-lite-tunnel"

printf "%b== LaunchAgents ==%b\n" "$C_BOLD" "$C_RESET"
BACKEND_LINE="$(launchctl list 2>/dev/null | awk -v l="$LABEL_BACKEND" '$3==l{print}' || true)"
TUNNEL_LINE="$(launchctl list 2>/dev/null | awk -v l="$LABEL_TUNNEL"  '$3==l{print}' || true)"

if [ -n "$BACKEND_LINE" ]; then
    printf "  %bbackend%b   %s\n" "$C_GREEN" "$C_RESET" "$BACKEND_LINE"
else
    printf "  %bbackend%b   não carregado\n" "$C_RED" "$C_RESET"
fi
if [ -n "$TUNNEL_LINE" ]; then
    printf "  %btunnel%b    %s\n" "$C_GREEN" "$C_RESET" "$TUNNEL_LINE"
else
    printf "  %btunnel%b    não carregado\n" "$C_YELLOW" "$C_RESET"
fi

printf "\n%b== Health ==%b\n" "$C_BOLD" "$C_RESET"
HEALTH="$(curl -fsS -m 3 http://localhost:8792/health 2>/dev/null || true)"
if [ -n "$HEALTH" ]; then
    printf "  %bup%b  %s\n" "$C_GREEN" "$C_RESET" "$HEALTH"
else
    printf "  %bdown%b  http://localhost:8792/health não respondeu\n" "$C_RED" "$C_RESET"
fi

printf "\n%b== Tunnel URL ==%b\n" "$C_BOLD" "$C_RESET"
if [ -f "$INSTALL_DIR/tunnel-url.txt" ]; then
    printf "  %s\n" "$(cat "$INSTALL_DIR/tunnel-url.txt")"
else
    printf "  (sem URL salva — tunnel pode estar offline)\n"
fi

printf "\n%b== Leads ==%b\n" "$C_BOLD" "$C_RESET"
if [ -d "$LEADS_DIR" ]; then
    COUNT="$(find "$LEADS_DIR" -maxdepth 1 -name '*.json' | wc -l | tr -d ' ')"
    printf "  %s lead(s) em %s\n" "$COUNT" "$LEADS_DIR"
else
    printf "  $LEADS_DIR não existe\n"
fi

printf "\n%b== backend.err.log (últimas 20 linhas) ==%b\n" "$C_BOLD" "$C_RESET"
if [ -f "$LOGS_DIR/backend.err.log" ]; then
    tail -20 "$LOGS_DIR/backend.err.log" | sed 's/^/  /'
else
    printf "  (sem log)\n"
fi

printf "\n%b== tunnel.err.log (últimas 20 linhas) ==%b\n" "$C_BOLD" "$C_RESET"
if [ -f "$LOGS_DIR/tunnel.err.log" ]; then
    tail -20 "$LOGS_DIR/tunnel.err.log" | sed 's/^/  /'
else
    printf "  (sem log)\n"
fi

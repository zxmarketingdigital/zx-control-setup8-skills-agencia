#!/bin/bash
# Lead Machine Lite — Desinstalação
# Remove LaunchAgents. NÃO apaga dados do aluno (~/.zx-lead-machine, ~/zx-leads).
# Use --purge pra apagar tudo.

set -euo pipefail

if [ "${NO_COLOR:-0}" = "1" ] || [ ! -t 1 ]; then
    C_RED=""; C_GREEN=""; C_YELLOW=""; C_BOLD=""; C_RESET=""
else
    C_RED="\033[0;31m"; C_GREEN="\033[0;32m"; C_YELLOW="\033[0;33m"
    C_BOLD="\033[1m"; C_RESET="\033[0m"
fi
msg_ok()   { printf "%b[OK]%b %s\n"   "$C_GREEN"  "$C_RESET" "$1"; }
msg_warn() { printf "%b[!]%b  %s\n"   "$C_YELLOW" "$C_RESET" "$1"; }
msg_info() { printf "%b[..]%b %s\n"   "$C_BOLD"   "$C_RESET" "$1"; }

msg_err()  { printf "%b[X]%b  %s\n"   "$C_RED"    "$C_RESET" "$1" >&2; }

PURGE=0
if [ "${1:-}" = "--purge" ]; then
    PURGE=1
fi

LAUNCH_DIR="$HOME/Library/LaunchAgents"
PLIST_BACKEND="com.zxlab.lead-machine-lite.plist"
PLIST_TUNNEL="com.zxlab.lead-machine-lite-tunnel.plist"
LABEL_BACKEND="com.zxlab.lead-machine-lite"
LABEL_TUNNEL="com.zxlab.lead-machine-lite-tunnel"
INSTALL_DIR="$HOME/.zx-lead-machine"
LEADS_DIR="$HOME/zx-leads"

# Confirmação dupla ANTES de mexer em qualquer coisa, se --purge
if [ "$PURGE" = "1" ]; then
    LEAD_COUNT=0
    if [ -d "$LEADS_DIR" ]; then
        LEAD_COUNT="$(find "$LEADS_DIR" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l | tr -d ' ')"
    fi
    msg_warn "⚠️  --purge apagará $LEAD_COUNT arquivo(s) de lead em $LEADS_DIR/"
    msg_warn "    + todo o diretório $INSTALL_DIR (backend, venv, .env, logs, tokens)."
    msg_warn "    Esta operação é IRREVERSÍVEL."
    printf "    Digite %bAPAGAR TUDO%b para confirmar: " "$C_BOLD" "$C_RESET"
    read -r CONFIRM || CONFIRM=""
    if [ "$CONFIRM" != "APAGAR TUDO" ]; then
        msg_err "Operação cancelada. Nada foi removido."
        exit 1
    fi
fi

msg_info "Parando LaunchAgents..."
for label in "$LABEL_BACKEND" "$LABEL_TUNNEL"; do
    plist_path="$LAUNCH_DIR/${label}.plist"
    if [ -f "$plist_path" ]; then
        launchctl unload "$plist_path" 2>/dev/null || true
        rm -f "$plist_path"
        msg_ok "$label removido"
    else
        msg_warn "$label não estava instalado"
    fi
done

if [ "$PURGE" = "1" ]; then
    msg_warn "--purge: apagando dados do aluno"
    rm -rf "$INSTALL_DIR"
    msg_ok "$INSTALL_DIR removido"
    if [ -d "$LEADS_DIR" ]; then
        rm -rf "$LEADS_DIR"
        msg_ok "$LEADS_DIR removido"
    fi
else
    msg_info "Dados preservados:"
    msg_info "  $INSTALL_DIR (backend, venv, .env, logs)"
    msg_info "  $LEADS_DIR (leads em JSON)"
    msg_info "Use --purge pra apagar tudo."
fi

printf "\n%bDesinstalado.%b\n" "$C_GREEN$C_BOLD" "$C_RESET"

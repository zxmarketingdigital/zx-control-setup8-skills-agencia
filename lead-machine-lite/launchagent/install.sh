#!/bin/bash
# Lead Machine Lite — Bootstrap idempotente
# Instala backend + LaunchAgents (backend + cloudflared tunnel)
# Roda 2x sem duplicar — atualiza arquivos e re-carrega plists.

set -euo pipefail

# ---------- Cores ----------
if [ "${NO_COLOR:-0}" = "1" ] || [ ! -t 1 ]; then
    C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_BOLD=""; C_RESET=""
else
    C_RED="\033[0;31m"; C_GREEN="\033[0;32m"; C_YELLOW="\033[0;33m"
    C_BLUE="\033[0;34m"; C_BOLD="\033[1m"; C_RESET="\033[0m"
fi

msg_ok()    { printf "%b[OK]%b %s\n"    "$C_GREEN"  "$C_RESET" "$1"; }
msg_warn()  { printf "%b[!]%b  %s\n"    "$C_YELLOW" "$C_RESET" "$1"; }
msg_err()   { printf "%b[X]%b  %s\n"    "$C_RED"    "$C_RESET" "$1" >&2; }
msg_info()  { printf "%b[..]%b %s\n"    "$C_BLUE"   "$C_RESET" "$1"; }
msg_step()  { printf "\n%b== %s ==%b\n" "$C_BOLD"   "$1"       "$C_RESET"; }

# ---------- Paths ----------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_SRC="$REPO_ROOT/backend"

INSTALL_DIR="$HOME/.zx-lead-machine"
BACKEND_DIR="$INSTALL_DIR/backend"
LOGS_DIR="$INSTALL_DIR/logs"
VENV_DIR="$INSTALL_DIR/venv"
LEADS_DIR="$HOME/zx-leads"
LAUNCH_DIR="$HOME/Library/LaunchAgents"

PLIST_BACKEND="com.zxlab.lead-machine-lite.plist"
PLIST_TUNNEL="com.zxlab.lead-machine-lite-tunnel.plist"
LABEL_BACKEND="com.zxlab.lead-machine-lite"
LABEL_TUNNEL="com.zxlab.lead-machine-lite-tunnel"

cleanup_on_err() {
    msg_err "Instalação falhou na linha $1. Verifique logs acima."
    exit 1
}
trap 'cleanup_on_err $LINENO' ERR

# ---------- 1. Pré-flight ----------
msg_step "1/9 Pré-flight"

if [ "$(uname)" != "Darwin" ]; then
    msg_err "Lead Machine Lite só roda em macOS."
    exit 1
fi
msg_ok "macOS detectado ($(sw_vers -productVersion))"

if ! command -v python3 >/dev/null 2>&1; then
    msg_err "python3 não encontrado. Instale Python 3.10+ (brew install python@3.12)"
    exit 1
fi
PY_VER="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
PY_MAJOR="$(echo "$PY_VER" | cut -d. -f1)"
PY_MINOR="$(echo "$PY_VER" | cut -d. -f2)"
if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 10 ]; }; then
    msg_err "Python $PY_VER detectado, mas precisa 3.10+. Atualize com: brew install python@3.12"
    exit 1
fi
msg_ok "Python $PY_VER OK"

if ! command -v pip3 >/dev/null 2>&1; then
    msg_err "pip3 não encontrado."
    exit 1
fi
msg_ok "pip3 OK"

CLOUDFLARED_OK=0
if command -v cloudflared >/dev/null 2>&1; then
    msg_ok "cloudflared OK ($(cloudflared --version 2>&1 | head -1))"
    CLOUDFLARED_OK=1
else
    msg_warn "cloudflared não instalado — tunnel público não vai subir."
    msg_warn "Instale com: brew install cloudflare/cloudflare/cloudflared"
fi

# ---------- 2. Diretórios ----------
msg_step "2/9 Criando diretórios"
mkdir -p "$BACKEND_DIR" "$LOGS_DIR" "$LEADS_DIR" "$LAUNCH_DIR"
msg_ok "$INSTALL_DIR/{backend,logs}"
msg_ok "$LEADS_DIR"

# ---------- 3. Copiar backend ----------
msg_step "3/9 Copiando backend"
if [ ! -f "$BACKEND_SRC/server.py" ]; then
    msg_err "server.py não encontrado em $BACKEND_SRC"
    exit 1
fi
cp -f "$BACKEND_SRC/server.py" "$BACKEND_DIR/server.py"
cp -f "$BACKEND_SRC/requirements.txt" "$BACKEND_DIR/requirements.txt"
cp -f "$BACKEND_SRC/.env.example" "$BACKEND_DIR/.env.example"
msg_ok "server.py, requirements.txt, .env.example → $BACKEND_DIR/"

# ---------- 4. Venv + deps ----------
msg_step "4/9 Criando venv + dependências"
if [ -d "$VENV_DIR" ]; then
    if "$VENV_DIR/bin/python3" -c "import sys; sys.exit(0)" >/dev/null 2>&1; then
        msg_ok "Venv válido (reutilizando)"
    else
        msg_warn "Venv quebrado (provável atualização de Python). Recriando..."
        rm -rf "$VENV_DIR"
        python3 -m venv "$VENV_DIR"
        msg_ok "Venv recriado em $VENV_DIR"
    fi
else
    python3 -m venv "$VENV_DIR"
    msg_ok "Venv criado em $VENV_DIR"
fi
"$VENV_DIR/bin/pip" install --quiet --upgrade pip

# Idempotente: só reinstala se requirements.txt mudou
REQ_CACHE="$INSTALL_DIR/.requirements.cached.txt"
if [ -f "$REQ_CACHE" ] && cmp -s "$BACKEND_DIR/requirements.txt" "$REQ_CACHE"; then
    msg_ok "Deps já atualizadas (requirements.txt inalterado)"
else
    msg_info "requirements.txt mudou — instalando deps..."
    "$VENV_DIR/bin/pip" install --quiet -r "$BACKEND_DIR/requirements.txt"
    cp "$BACKEND_DIR/requirements.txt" "$REQ_CACHE"
    msg_ok "Dependências instaladas"
fi

# ---------- 5. .env + ALUNO_TOKEN ----------
msg_step "5/9 Configurando .env"
ENV_FILE="$BACKEND_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    cp "$BACKEND_DIR/.env.example" "$ENV_FILE"
    chmod 600 "$ENV_FILE"

    # Gera ALUNO_TOKEN 32 chars
    TOKEN="$(python3 -c 'import secrets; print(secrets.token_urlsafe(24))')"
    {
        echo ""
        echo "# Auto-gerado pelo install.sh"
        echo "ALUNO_TOKEN=$TOKEN"
    } >> "$ENV_FILE"

    msg_warn ".env criado em $ENV_FILE"
    msg_warn "VOCÊ PRECISA preencher ANTHROPIC_API_KEY antes de usar."
    msg_warn "Obter chave: https://console.anthropic.com/settings/keys"
    printf "\n%bAbrir .env agora pra editar?%b [Y/n] " "$C_BOLD" "$C_RESET"
    read -r RESP || RESP="n"
    case "$RESP" in
        ""|y|Y|yes|YES)
            "${EDITOR:-nano}" "$ENV_FILE"
            ;;
        *)
            msg_info "Edite depois: $EDITOR $ENV_FILE"
            ;;
    esac
else
    msg_ok ".env já existe (preservando configuração)"
    # Garante que ALUNO_TOKEN existe E não está vazio (linha "ALUNO_TOKEN=" sem valor)
    if ! grep -qE "^ALUNO_TOKEN=.+" "$ENV_FILE"; then
        # Remove linha vazia/inválida se houver
        if grep -q "^ALUNO_TOKEN=" "$ENV_FILE"; then
            python3 -c "
import sys
p = '$ENV_FILE'
with open(p) as f: lines = f.readlines()
lines = [l for l in lines if not (l.startswith('ALUNO_TOKEN=') and l.strip() == 'ALUNO_TOKEN=')]
with open(p, 'w') as f: f.writelines(lines)
"
        fi
        TOKEN="$(python3 -c 'import secrets; print(secrets.token_urlsafe(24))')"
        echo "ALUNO_TOKEN=$TOKEN" >> "$ENV_FILE"
        msg_ok "ALUNO_TOKEN (re)gerado e adicionado ao .env"
    fi
fi

# SEMPRE garantir chmod 600 em rerun (não só na 1ª criação)
chmod 600 "$ENV_FILE"

printf "\n%b%bALUNO_TOKEN configurado.%b Sem ele, o dashboard ficaria aberto pra qualquer pessoa\n" "$C_YELLOW" "$C_BOLD" "$C_RESET"
printf "   que descobrir a URL do tunnel. Token salvo em %s (chmod 600)\n\n" "$ENV_FILE"

# Validação básica
if grep -q "ANTHROPIC_API_KEY=sk-ant-\\.\\.\\." "$ENV_FILE" 2>/dev/null || \
   ! grep -q "^ANTHROPIC_API_KEY=sk-" "$ENV_FILE" 2>/dev/null; then
    msg_warn "ANTHROPIC_API_KEY parece não estar preenchido. Backend vai subir mas chamadas LLM vão falhar."
fi

# ---------- 6. LaunchAgents ----------
msg_step "6/9 Instalando LaunchAgents"
for plist in "$PLIST_BACKEND" "$PLIST_TUNNEL"; do
    if [ ! -f "$SCRIPT_DIR/$plist" ]; then
        msg_err "Template $plist não encontrado em $SCRIPT_DIR"
        exit 1
    fi
done

# Render via Python — escapa corretamente caracteres especiais em $HOME
# (espaços, &, |, /, etc — sed s|...|$HOME|g quebra se $HOME tiver "|")
SRC_BACKEND="$SCRIPT_DIR/$PLIST_BACKEND"
SRC_TUNNEL="$SCRIPT_DIR/$PLIST_TUNNEL"
DST_BACKEND="$LAUNCH_DIR/$PLIST_BACKEND"
DST_TUNNEL="$LAUNCH_DIR/$PLIST_TUNNEL"

python3 -c "
import os, sys
home = os.environ['HOME']
pairs = [
    (sys.argv[1], sys.argv[2]),
    (sys.argv[3], sys.argv[4]),
]
for src, dst in pairs:
    with open(src) as f:
        content = f.read()
    with open(dst, 'w') as f:
        f.write(content.replace('{HOME}', home))
" "$SRC_BACKEND" "$DST_BACKEND" "$SRC_TUNNEL" "$DST_TUNNEL"

msg_ok "$PLIST_BACKEND → $LAUNCH_DIR/"
msg_ok "$PLIST_TUNNEL → $LAUNCH_DIR/"

# ---------- 7. Load LaunchAgents ----------
msg_step "7/9 Carregando LaunchAgents"

# Re-check cloudflared antes de carregar o tunnel (evita loop de restart com logs explodindo)
SKIP_TUNNEL=0
if ! command -v cloudflared >/dev/null 2>&1; then
    msg_warn "cloudflared não encontrado — pulando carregamento do tunnel."
    msg_warn "Para instalar: brew install cloudflare/cloudflare/cloudflared"
    msg_warn "Depois rode: $SCRIPT_DIR/install.sh (ou ./restart.sh)"
    SKIP_TUNNEL=1
    CLOUDFLARED_OK=0
fi

reload_agent() {
    local label="$1"
    local plist_path="$2"
    if launchctl list | grep -q "$label"; then
        launchctl unload "$plist_path" 2>/dev/null || true
    fi
    launchctl load -w "$plist_path"
    msg_ok "$label carregado"
}

reload_agent "$LABEL_BACKEND" "$LAUNCH_DIR/$PLIST_BACKEND"

if [ "$CLOUDFLARED_OK" = "1" ] && [ "$SKIP_TUNNEL" != "1" ]; then
    reload_agent "$LABEL_TUNNEL" "$LAUNCH_DIR/$PLIST_TUNNEL"
else
    msg_warn "Tunnel NÃO carregado — cloudflared faltando."
    # Garante que tunnel anterior (se foi carregado num run passado) está parado
    if launchctl list | grep -q "$LABEL_TUNNEL"; then
        launchctl unload "$LAUNCH_DIR/$PLIST_TUNNEL" 2>/dev/null || true
        msg_warn "Tunnel anterior descarregado pra evitar loop de restart."
    fi
fi

# ---------- 8. Health check ----------
msg_step "8/9 Aguardando backend responder em localhost:8792/health (timeout 20s)"
HEALTH_OK=0
for i in $(seq 1 20); do
    if curl -fsS -m 2 http://localhost:8792/health >/dev/null 2>&1; then
        HEALTH_OK=1
        break
    fi
    sleep 1
done

if [ "$HEALTH_OK" = "1" ]; then
    msg_ok "Backend respondendo (http://localhost:8792/health)"
else
    msg_err "Backend não respondeu em 20s. Veja: tail -50 $LOGS_DIR/backend.err.log"
fi

# ---------- 9. Tunnel URL ----------
msg_step "9/9 Capturando URL do tunnel"
TUNNEL_URL_FILE="$INSTALL_DIR/tunnel-url.txt"
TUNNEL_URL=""

if [ "$CLOUDFLARED_OK" = "1" ]; then
    msg_info "Lendo $LOGS_DIR/tunnel.out.log (timeout 30s)..."
    for i in $(seq 1 30); do
        # cloudflared escreve em stderr — checamos ambos os logs
        TUNNEL_URL="$(grep -hoE 'https://[a-z0-9-]+\.trycloudflare\.com' \
            "$LOGS_DIR/tunnel.out.log" "$LOGS_DIR/tunnel.err.log" 2>/dev/null | head -1 || true)"
        if [ -n "$TUNNEL_URL" ]; then
            break
        fi
        sleep 1
    done

    if [ -n "$TUNNEL_URL" ]; then
        echo "$TUNNEL_URL" > "$TUNNEL_URL_FILE"
        msg_ok "Tunnel URL: $TUNNEL_URL"
    else
        msg_warn "Tunnel não retornou URL em 30s. Verifique: tail -30 $LOGS_DIR/tunnel.err.log"
    fi
else
    msg_warn "Instale cloudflared e re-rode este script:"
    msg_warn "  brew install cloudflare/cloudflare/cloudflared && $SCRIPT_DIR/install.sh"
fi

# ---------- Resumo ----------
ALUNO_TOKEN_VAL="$(grep '^ALUNO_TOKEN=' "$ENV_FILE" | cut -d= -f2- || echo '?')"

# Salva URL completa do dashboard em arquivo separado (chmod 600) — NÃO imprime em texto claro
DASHBOARD_URL_FILE="$INSTALL_DIR/dashboard-url.txt"
printf "http://localhost:8792/dashboard?token=%s\n" "$ALUNO_TOKEN_VAL" > "$DASHBOARD_URL_FILE"
chmod 600 "$DASHBOARD_URL_FILE"

printf "\n%b================================================================%b\n" "$C_BOLD" "$C_RESET"
printf "%b   LEAD MACHINE LITE — INSTALADO%b\n" "$C_GREEN$C_BOLD" "$C_RESET"
printf "%b================================================================%b\n\n" "$C_BOLD" "$C_RESET"

if [ -n "$TUNNEL_URL" ]; then
    printf "%bURL pública (mande pro lead):%b\n" "$C_BOLD" "$C_RESET"
    printf "  %b%s%b\n\n" "$C_GREEN" "$TUNNEL_URL" "$C_RESET"
fi

printf "%bDashboard local (você):%b\n" "$C_BOLD" "$C_RESET"
printf "  Dashboard URL salva em: %s (chmod 600)\n" "$DASHBOARD_URL_FILE"
printf "  Para abrir no navegador:\n"
printf "    open \"\$(cat %s)\"\n" "$DASHBOARD_URL_FILE"
printf "  Ou copiar pro clipboard:\n"
printf "    cat %s | tr -d '\\n' | pbcopy\n\n" "$DASHBOARD_URL_FILE"

printf "%bArquivos:%b\n" "$C_BOLD" "$C_RESET"
printf "  Token:    %s  (em ALUNO_TOKEN)\n" "$ENV_FILE"
printf "  Dashboard:%s\n" "$DASHBOARD_URL_FILE"
printf "  Leads:    %s\n" "$LEADS_DIR"
printf "  Logs:     %s\n" "$LOGS_DIR"
printf "  Tunnel:   %s\n\n" "$TUNNEL_URL_FILE"

printf "%bComandos:%b\n" "$C_BOLD" "$C_RESET"
printf "  Status:     %s/status.sh\n" "$SCRIPT_DIR"
printf "  Restart:    %s/restart.sh\n" "$SCRIPT_DIR"
printf "  Desinstalar:%s/uninstall.sh\n\n" "$SCRIPT_DIR"

printf "%bATENÇÃO:%b se o Mac dormir, o tunnel cai. Configure: System Settings → Energy → Prevent automatic sleeping when display is off.\n" "$C_YELLOW" "$C_RESET"
printf "Pra rodar 24/7 com domínio fixo: upgrade pro ZX Agência 50K (VPS + dom próprio).\n\n"

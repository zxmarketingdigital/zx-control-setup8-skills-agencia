#!/usr/bin/env bash
# install.sh — Setup 8: Skills da Agência IA + Lead Machine Lite
# Executa: bash install.sh        (completo)
#          bash install.sh --bloco-a   (só 5 skills)
#          bash install.sh --dry-run   (sem side effects)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DST="$HOME/.claude/skills"
DRY_RUN=false
BLOCO_A_ONLY=false

for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
    --bloco-a) BLOCO_A_ONLY=true ;;
  esac
done

header() { echo ""; echo "╔══════════════════════════════════════════╗"; echo "║  $1"; echo "╚══════════════════════════════════════════╝"; }
ok()     { echo "  ✅  $1"; }
warn()   { echo "  ⚠️   $1"; }
step()   { echo "  →  $1"; }

header "Setup 8 — Skills da Agência IA + Lead Machine Lite"
echo "  Modo: $([ "$DRY_RUN" = true ] && echo 'DRY-RUN (sem side effects)' || echo 'INSTALAÇÃO REAL')"
echo ""

# ── Bloco A: 5 Skills ────────────────────────────────────────────
header "Bloco A: Instalando 5 Skills"
SKILLS=(diagnostico-empreendedor analise-call prototipar-sistema simulador-vendas criar-orcamento)
for s in "${SKILLS[@]}"; do
  step "Copiando /$s ..."
  if [ "$DRY_RUN" = false ]; then
    mkdir -p "$SKILLS_DST/$s"
    cp -r "$REPO_DIR/skills/$s/." "$SKILLS_DST/$s/"
  fi
  ok "$s → $SKILLS_DST/$s/"
done

echo ""
echo "  5 skills instaladas. Disponíveis imediatamente no Claude Code:"
for s in "${SKILLS[@]}"; do echo "    /$s"; done

if [ "$BLOCO_A_ONLY" = true ]; then
  echo ""
  echo "  ✅ Bloco A concluído (--bloco-a). Lead Machine não instalado."
  exit 0
fi

# ── Bloco B: Lead Machine Lite ───────────────────────────────────
header "Bloco B: Lead Machine Lite"

LML_SRC="$REPO_DIR/lead-machine-lite"
LML_DST="$HOME/projetos/lead-machine-lite"

step "Copiando Lead Machine Lite para $LML_DST ..."
if [ "$DRY_RUN" = false ]; then
  mkdir -p "$HOME/projetos"
  cp -r "$LML_SRC" "$LML_DST"
fi
ok "Lead Machine Lite copiado"

# Python 3.10+
step "Verificando Python 3.10+ ..."
PY=$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
PY_MAJOR=$(echo "$PY" | cut -d. -f1)
PY_MINOR=$(echo "$PY" | cut -d. -f2)
if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 10 ]; }; then
  warn "Python $PY encontrado — requer 3.10+. Instale via: brew install python@3.10"
  warn "Continuando mesmo assim — backend pode falhar."
else
  ok "Python $PY ✓"
fi

# cloudflared
step "Verificando cloudflared ..."
if ! command -v cloudflared &>/dev/null; then
  warn "cloudflared não encontrado. Instalando via brew ..."
  if [ "$DRY_RUN" = false ]; then
    brew install cloudflare/cloudflare/cloudflared 2>&1 | tail -3
  fi
  ok "cloudflared instalado"
else
  ok "cloudflared $(cloudflared --version 2>&1 | head -1) ✓"
fi

# .env
step "Configurando .env do Lead Machine ..."
ENV_FILE="$LML_DST/.env"
if [ "$DRY_RUN" = false ] && [ ! -f "$ENV_FILE" ]; then
  cp "$LML_SRC/.env.template" "$ENV_FILE" 2>/dev/null || cat > "$ENV_FILE" <<'ENVEOF'
ANTHROPIC_API_KEY=sk-ant-COLOQUE_SUA_CHAVE_AQUI
HOST=0.0.0.0
PORT=8710
ENVEOF
  echo ""
  echo "  ┌─────────────────────────────────────────────────────┐"
  echo "  │  AÇÃO NECESSÁRIA: configure sua ANTHROPIC_API_KEY   │"
  echo "  │  1. Acesse: console.anthropic.com                   │"
  echo "  │  2. Copie sua API key                               │"
  echo "  │  3. Edite: $ENV_FILE  │"
  echo "  │  4. Substitua sk-ant-COLOQUE_SUA_CHAVE_AQUI         │"
  echo "  └─────────────────────────────────────────────────────┘"
  echo ""
fi
ok ".env configurado em $ENV_FILE"

# LaunchAgent
step "Instalando LaunchAgent (auto-start no boot) ..."
if [ "$DRY_RUN" = false ]; then
  cd "$LML_DST/launchagent" && bash install.sh
fi
ok "LaunchAgent instalado"

# ── Resumo final ─────────────────────────────────────────────────
header "Instalação concluída!"
echo ""
echo "  O que foi instalado:"
echo "    5 skills:       ~/.claude/skills/{diagnostico-empreendedor,analise-call,...}"
echo "    Lead Machine:   ~/projetos/lead-machine-lite/"
echo "    LaunchAgents:   com.zxlab.lead-machine-lite + com.zxlab.lead-machine-lite-tunnel"
echo ""
echo "  Próximos passos:"
echo "    1. Edite ~/projetos/lead-machine-lite/.env com sua ANTHROPIC_API_KEY"
echo "    2. No Claude Code, teste: /diagnostico-empreendedor"
echo "    3. Abra o dashboard: http://localhost:8710/dashboard"
echo "    4. Use /lead-machine-lite para gerenciar leads e o tunnel"
echo ""
if [ "$DRY_RUN" = true ]; then
  echo "  [DRY-RUN] Nenhum arquivo foi modificado."
fi

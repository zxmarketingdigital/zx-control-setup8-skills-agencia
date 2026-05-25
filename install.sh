#!/usr/bin/env bash
# install.sh — Setup 8: Agentes de Vendas e Captura de Leads (ZX Growth + ZX Lead Machine)
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
    --help|-h)
      echo "Setup 8 — Agentes de Vendas + Captura de Leads Lite"
      echo ""
      echo "Uso: bash install.sh [--dry-run] [--bloco-a]"
      echo "  --dry-run   Simula sem efeitos colaterais"
      echo "  --bloco-a   Instala só as 5 skills (sem Lead Machine)"
      exit 0
      ;;
    *)
      echo "Flag desconhecida: $arg (use --help)" >&2
      exit 1
      ;;
  esac
done

header() { echo ""; echo "╔══════════════════════════════════════════╗"; echo "║  $1"; echo "╚══════════════════════════════════════════╝"; }
ok()     { echo "  ✅  $1"; }
warn()   { echo "  ⚠️   $1"; }
err()    { echo "  ❌  $1" >&2; }
step()   { echo "  →  $1"; }

# Detectar SO — Lead Machine requer macOS (LaunchAgents)
OS_NAME="$(uname)"

header "Setup 8 — Agentes de Vendas e Captura de Leads (ZX Growth + ZX Lead Machine)"
echo "  Modo: $([ "$DRY_RUN" = true ] && echo 'DRY-RUN (sem side effects)' || echo 'INSTALAÇÃO REAL')"
echo "  SO:   $OS_NAME"
if [ "$OS_NAME" != "Darwin" ] && [ "$BLOCO_A_ONLY" = false ]; then
  warn "Sistema detectado: $OS_NAME (não-macOS)"
  warn "Bloco A (5 skills da Agência IA — ZX Growth): será instalado normalmente ✅"
  warn "Bloco B (Lead Machine Lite — ZX Lead Machine): pulado — requer macOS (LaunchAgents + cloudflared local)"
  warn "→ Auto-ativando --bloco-a. Pra rodar Lead Machine: use Agência IA 50K (SaaS multi-OS)."
  BLOCO_A_ONLY=true
fi
echo ""

# ── Bloco A: 6 Skills ────────────────────────────────────────────
header "Bloco A: Instalando 6 Skills"
SKILLS=(diagnostico-empreendedor analise-call prototipar-sistema simulador-vendas criar-orcamento pre-call-checklist)
for s in "${SKILLS[@]}"; do
  step "Copiando /$s ..."
  if [ "$DRY_RUN" = false ]; then
    if [ -d "$SKILLS_DST/$s" ]; then
      mv "$SKILLS_DST/$s" "$SKILLS_DST/$s.bak-$(date +%s)"
      warn "$s já existia — backup criado em $s.bak-*"
    fi
    mkdir -p "$SKILLS_DST/$s"
    cp -r "$REPO_DIR/skills/$s/." "$SKILLS_DST/$s/"
  fi
  ok "$s → $SKILLS_DST/$s/"
done

# Helpers compartilhados (_shared) — usados por algumas skills pra renderizar HTML
step "Copiando _shared helpers ..."
if [ "$DRY_RUN" = false ]; then
  mkdir -p "$SKILLS_DST/_shared"
  cp -r "$REPO_DIR/skills/_shared/." "$SKILLS_DST/_shared/"
fi
ok "_shared → $SKILLS_DST/_shared/"

echo ""
echo "  6 skills instaladas. Disponíveis imediatamente no Claude Code:"
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
  if [ -d "$LML_DST" ]; then
    mv "$LML_DST" "$LML_DST.bak-$(date +%s)"
    warn "Lead Machine Lite já existia em $LML_DST — backup criado em $LML_DST.bak-*"
  fi
  # Idempotente: SRC/. -> DST/ não cria nested mesmo se DST já existir
  mkdir -p "$LML_DST"
  cp -r "$LML_SRC/." "$LML_DST/"
fi
ok "Lead Machine Lite copiado"

# Python 3.10+ — exigência hard (Pydantic + FastAPI + Lead Machine backend)
step "Verificando Python 3.10+ ..."
PY=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PY_MAJOR=$(echo "$PY" | cut -d. -f1)
PY_MINOR=$(echo "$PY" | cut -d. -f2)
if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 10 ]; }; then
  err "Python $PY encontrado — Lead Machine requer 3.10+ (Pydantic v2 + FastAPI)"
  err "Instale com: brew install python@3.12 && rode novamente bash install.sh"
  exit 1
fi
ok "Python $PY ✓"

# brew (pré-req do cloudflared)
step "Verificando Homebrew ..."
if ! command -v brew &>/dev/null; then
  warn "Homebrew não encontrado — instale em https://brew.sh"
  warn "Pulando instalação automática do cloudflared. Você pode instalar manualmente depois."
  HAS_BREW=false
else
  ok "Homebrew $(brew --version 2>&1 | head -1) ✓"
  HAS_BREW=true
fi

# cloudflared
step "Verificando cloudflared ..."
if ! command -v cloudflared &>/dev/null; then
  if [ "$HAS_BREW" = true ]; then
    warn "cloudflared não encontrado. Instalando via brew ..."
    if [ "$DRY_RUN" = false ]; then
      brew install cloudflare/cloudflare/cloudflared 2>&1 | tail -3 || warn "Falha no brew install — instale manualmente depois"
    fi
    ok "cloudflared instalado (ou pendente — backend sobe sem tunnel)"
  else
    warn "cloudflared faltando + sem brew. Backend vai subir, mas SEM tunnel público."
  fi
else
  ok "cloudflared $(cloudflared --version 2>&1 | head -1) ✓"
fi

# LaunchAgent — delega criação do .env (com ALUNO_TOKEN auto-gerado) e instalação dos plists
# para o install.sh do launchagent, que escreve em ~/.zx-lead-machine/ (não em $LML_DST)
step "Instalando backend + LaunchAgents (auto-start no boot) ..."
if [ "$DRY_RUN" = false ]; then
  cd "$LML_DST/launchagent" && bash install.sh
fi
ok "Backend + LaunchAgents instalados em ~/.zx-lead-machine/"

# ── Resumo final ─────────────────────────────────────────────────
header "Instalação concluída!"
echo ""
echo "  O que foi instalado:"
echo "    6 skills:       ~/.claude/skills/{diagnostico-empreendedor,analise-call,prototipar-sistema,simulador-vendas,criar-orcamento,pre-call-checklist}"
echo "    Banco objeções: ~/.claude/skills/_shared/objections-bank/agente-ia-whatsapp.yaml"
echo "    Lead Machine:   ~/projetos/lead-machine-lite/"
echo "    LaunchAgents:   com.zxlab.lead-machine-lite + com.zxlab.lead-machine-lite-tunnel"
echo ""
echo "  Próximos passos:"
echo "    1. Edite ~/.zx-lead-machine/backend/.env com sua ANTHROPIC_API_KEY"
echo "    2. No Claude Code, teste: /diagnostico-empreendedor"
echo "    3. Antes da próxima call comercial: /pre-call-checklist {cliente-slug}"
echo "    4. Abra o dashboard: open \"\$(cat ~/.zx-lead-machine/dashboard-url.txt)\""
echo "    5. Use /lead-machine-lite para gerenciar leads e o tunnel"
echo ""
if [ "$DRY_RUN" = true ]; then
  echo "  [DRY-RUN] Nenhum arquivo foi modificado."
fi

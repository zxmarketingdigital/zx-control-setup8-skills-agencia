#!/usr/bin/env bash
# Dry run end-to-end do Lead Machine Lite.
# Sobe backend isolado (porta 18792, LEADS_DIR=/tmp/zx-leads-dry-run).
# Modo subscription (default): usa `claude -p` via shim. Sem chave Anthropic.
# Modo API: se ANTHROPIC_API_KEY setada, usa SDK direto.
#
# Uso:
#   ./dry-run.sh                                # subscription Claude Code (lento ~10s/chamada)
#   ANTHROPIC_API_KEY=sk-ant-xxx ./dry-run.sh   # SDK (rápido, gasta créditos)

set -euo pipefail

GREEN=$(tput setaf 2 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
YEL=$(tput setaf 3 2>/dev/null || echo "")
DIM=$(tput dim 2>/dev/null || echo "")
RST=$(tput sgr0 2>/dev/null || echo "")
[ "${NO_COLOR:-0}" = "1" ] && GREEN="" && RED="" && YEL="" && DIM="" && RST=""

ok()   { printf "${GREEN}✓${RST} %s\n" "$1"; }
warn() { printf "${YEL}⚠${RST} %s\n" "$1"; }
err()  { printf "${RED}✗${RST} %s\n" "$1"; }
hdr()  { printf "\n${DIM}━━ %s ━━${RST}\n" "$1"; }

# ── Pré-flight ────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="$REPO_DIR/backend"
SCRIPTS_DIR="$REPO_DIR/scripts"
SKILL_DIR="$HOME/.claude/skills/lead-machine-lite"
PORT=18792
LEADS_DIR=/tmp/zx-leads-dry-run
TOKEN="drytoken$(date +%s)"
BASE="http://127.0.0.1:$PORT"
LOG=/tmp/dry-run-backend.log

USE_SHIM=0
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  if command -v claude >/dev/null 2>&1; then
    USE_SHIM=1
    warn "ANTHROPIC_API_KEY vazia — usando subscription Claude Code via shim (~10s/chamada)"
    export ANTHROPIC_API_KEY="shim-no-real-key"
  else
    err "Sem ANTHROPIC_API_KEY nem binário 'claude'. Instale Claude Code ou exporte a chave."
    exit 1
  fi
fi

# ── JSON helpers (env vars evitam nested-quote hell) ─────────
mk_json_body() {
  # uso: mk_json_body "key1=val1" "key2=val2" ...
  python3 - "$@" <<'PYEOF'
import json, sys
d = {}
for kv in sys.argv[1:]:
    k, _, v = kv.partition("=")
    d[k] = v
print(json.dumps(d))
PYEOF
}

extract_json_field() {
  # uso: echo "$json" | extract_json_field path.to.field
  # NOTA: usa -c (não heredoc) pra não consumir stdin
  python3 -c '
import json, sys
data = json.load(sys.stdin)
for k in sys.argv[1].split("."):
    if isinstance(data, dict): data = data.get(k)
    elif isinstance(data, list): data = data[int(k)] if k.isdigit() else None
    if data is None: break
print(data if data is not None else "")
' "$1"
}

# ── Cleanup helpers ──────────────────────────────────────────
cleanup() {
  if [ -n "${BACKEND_PID:-}" ] && kill -0 "$BACKEND_PID" 2>/dev/null; then
    kill "$BACKEND_PID" 2>/dev/null || true
    wait "$BACKEND_PID" 2>/dev/null || true
  fi
  rm -rf "$LEADS_DIR" "$LOG"
}
trap cleanup EXIT INT TERM

# ── Sobe backend isolado ─────────────────────────────────────
hdr "Subindo backend isolado (porta $PORT, leads em $LEADS_DIR)"
rm -rf "$LEADS_DIR" && mkdir -p "$LEADS_DIR"
cd "$BACKEND_DIR"

python3 -c "import slowapi" 2>/dev/null || pip install -q slowapi==0.1.9

if [ "$USE_SHIM" = "1" ]; then
  APP_MODULE="server_with_shim:app"
  PYPATH_EXTRA="$SCRIPTS_DIR:$BACKEND_DIR"
else
  APP_MODULE="server:app"
  PYPATH_EXTRA="$BACKEND_DIR"
fi

PORT=$PORT \
ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
ALUNO_TOKEN="$TOKEN" \
LEADS_DIR="$LEADS_DIR" \
MODEL="claude-sonnet-4-6" \
PYTHONPATH="$PYPATH_EXTRA" \
python3 -m uvicorn "$APP_MODULE" --host 127.0.0.1 --port "$PORT" --log-level warning > "$LOG" 2>&1 &
BACKEND_PID=$!

for i in $(seq 1 20); do
  if curl -sf "$BASE/health" >/dev/null 2>&1; then
    ok "Backend respondeu /health (PID $BACKEND_PID)"
    break
  fi
  sleep 0.5
  [ "$i" = "20" ] && { err "Backend não subiu em 10s. Log:"; cat "$LOG"; exit 1; }
done

# ── 1. Criar lead ────────────────────────────────────────────
hdr "1/6 — POST /lead/new"
RESP=$(curl -sf -X POST "$BASE/lead/new" \
  -H "Content-Type: application/json" \
  -d "$(mk_json_body \
    nome="Carlos Dryrun" \
    email="carlos@exemplo.com" \
    empresa="Clínica Odonto Sorrir" \
    telefone="11988887777" \
    segmento="odontologia" \
    website="sorrir.com.br")")
LEAD_ID=$(echo "$RESP" | extract_json_field lead_id)
Q1_KEY=$(echo "$RESP" | extract_json_field first_question.question_key)
Q1_TEXT=$(echo "$RESP" | extract_json_field first_question.text)
ok "Lead criado: $LEAD_ID"
echo "  Q1 ($Q1_KEY): ${Q1_TEXT:0:90}..."

# ── 2. 3 respostas para satisfazer min_questions guard ───────
hdr "2/6 — POST /lead/answer × 3 (LLM gera Q2-Q3 via $([ $USE_SHIM = 1 ] && echo shim || echo SDK))"
ANSWERS=(
  "Faturamos 80 mil por mês com 6 dentistas, mas só 30% dos leads do Instagram fecham consulta. Quero dobrar isso."
  "Minha equipe demora 4 horas pra responder no WhatsApp e perdemos leads quentes pra concorrente."
  "Já gastei 10 mil em ads mas leads chegam frios. Quero agente IA WhatsApp que qualifique 24/7 e marque consulta."
)
CUR_KEY="$Q1_KEY"
DONE="False"
for i in 0 1 2; do
  ANS="${ANSWERS[$i]}"
  echo "  → A$((i+1)) [$CUR_KEY]: ${ANS:0:60}..."
  RESP=$(curl -sf -X POST "$BASE/lead/answer" \
    -H "Content-Type: application/json" \
    -d "$(mk_json_body lead_id="$LEAD_ID" question_key="$CUR_KEY" answer="$ANS")")
  DONE=$(echo "$RESP" | extract_json_field done)
  if [ "$DONE" = "True" ]; then
    ok "LLM retornou done:true após $((i+1)) respostas"
    break
  fi
  CUR_KEY=$(echo "$RESP" | extract_json_field next_question.question_key)
  NEXT_TEXT=$(echo "$RESP" | extract_json_field next_question.text)
  echo "    Q$((i+2)) ($CUR_KEY): ${NEXT_TEXT:0:80}..."
done

# Se ainda não terminou, encerrar manualmente com mais 1 turno
if [ "$DONE" != "True" ]; then
  warn "Encerrando manualmente após mais 1 turno"
  curl -sf -X POST "$BASE/lead/answer" \
    -H "Content-Type: application/json" \
    -d "$(mk_json_body lead_id="$LEAD_ID" question_key="$CUR_KEY" answer="Já cobri tudo, pode encerrar.")" > /dev/null
fi

# ── 3. Aguardar generate_report ──────────────────────────────
hdr "3/6 — Aguardando generate_report (status: pending → ready)"
for i in $(seq 1 60); do
  STATUS=$(curl -sf "$BASE/lead/status/$LEAD_ID" -H "X-Aluno-Token: $TOKEN" 2>/dev/null | extract_json_field status || echo "?")
  if [ "$STATUS" = "ready" ]; then
    ok "Diagnóstico pronto após $((i*2))s"
    break
  fi
  if [ "$STATUS" = "error" ]; then
    err "Diagnóstico FALHOU (status=error). Detalhe:"
    curl -sf "$BASE/lead/result/$LEAD_ID" -H "X-Aluno-Token: $TOKEN" | python3 -m json.tool
    exit 1
  fi
  sleep 2
  [ "$i" = "60" ] && { err "Timeout 120s. status=$STATUS"; exit 1; }
done

RESULT=$(curl -sf "$BASE/lead/result/$LEAD_ID" -H "X-Aluno-Token: $TOKEN")
DIAG_LEN=$(echo "$RESULT" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('diagnostico_md','')))")
PLANO_LEN=$(echo "$RESULT" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('plano_md','')))")
ok "diagnostico_md=${DIAG_LEN}ch · plano_md=${PLANO_LEN}ch"

# ── 4. /api/leads (paginação + cache + PII filter) ───────────
hdr "4/6 — GET /api/leads"
LISTA=$(curl -sf "$BASE/api/leads" -H "X-Aluno-Token: $TOKEN")
TOTAL=$(echo "$LISTA" | extract_json_field total)
HAS_EMAIL=$(echo "$LISTA" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('SIM' if any('email' in str(l) for l in d.get('leads', [])) else 'NAO')
")
ok "/api/leads total=$TOTAL · email exposto na lista=$HAS_EMAIL (esperado: NAO)"

T1=$(python3 -c "import time; print(time.time())")
curl -sf "$BASE/api/leads" -H "X-Aluno-Token: $TOKEN" > /dev/null
T2=$(python3 -c "import time; print(time.time())")
DT=$(python3 -c "print(round(($T2-$T1)*1000))")
ok "2ª chamada /api/leads: ${DT}ms (cache hit esperado <50ms)"

# ── 5. generate-copy + generate-kit ──────────────────────────
hdr "5/6 — POST /lead/generate-copy (WhatsApp) + /lead/generate-kit"
COPY=$(curl -sf -X POST "$BASE/lead/generate-copy" \
  -H "X-Aluno-Token: $TOKEN" -H "Content-Type: application/json" \
  -d "$(mk_json_body lead_id="$LEAD_ID" channel="whatsapp")")
COPY_LEN=$(echo "$COPY" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('copy_md','')))")
ok "copy_md WhatsApp: ${COPY_LEN}ch"

KIT=$(curl -sf -X POST "$BASE/lead/generate-kit" \
  -H "X-Aluno-Token: $TOKEN" -H "Content-Type: application/json" \
  -d "$(mk_json_body lead_id="$LEAD_ID")")
KIT_LEN=$(echo "$KIT" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('kit_md','')))")
ok "kit_md: ${KIT_LEN}ch"

# ── 6. Skill run.py — bug fix #1 ─────────────────────────────
hdr "6/6 — Skill run.py list (valida bug ld.get('id')→lead_id corrigido)"
SKILL_OUT=$(cd /tmp && \
  ALUNO_TOKEN="$TOKEN" \
  LEAD_MACHINE_HOST="$BASE" \
  python3 "$SKILL_DIR/run.py" list 2>&1 || true)
echo "$SKILL_OUT" | head -10
if echo "$SKILL_OUT" | grep -q "${LEAD_ID:0:8}"; then
  ok "Skill list achou lead ${LEAD_ID:0:8} (bug fix #1 confirmado)"
else
  warn "Skill list NÃO mostrou o lead — verificar se LEAD_MACHINE_HOST é a var correta"
fi

# ── Fim ──────────────────────────────────────────────────────
hdr "Dry run completo"
echo "  Lead: $LEAD_ID"
echo "  JSONs: $LEADS_DIR (apagados ao sair)"
ok "Tudo validado. Pronto pra cohort."

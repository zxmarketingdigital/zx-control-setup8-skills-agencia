# Lead Machine Lite

Versão LOCAL do `zxleadmachinemvp1` (Lovable + Supabase) — roda no Mac do aluno ZX Control.
Sem Supabase. Sem multi-tenant. Sem URL hospedada 24/7. Tunnel cai quando Mac dorme — **isso é gancho de upgrade pro Agência IA 50K, não bug.**

## O que entrega

- **LP pública** (servida via Cloudflare Tunnel) onde o LEAD do cliente do aluno preenche diagnóstico empresarial multi-step
- **Backend FastAPI** local com SYSTEM_PROMPTs LITERAIS do `diagnostic-chat` e `diagnostic-report` (preserva fidelidade ao original Lovable)
- **Storage JSON** em `~/zx-leads/{lead_id}.json` (fcntl.flock pra evitar corrida)
- **Dashboard local** pro aluno listar leads, ver respostas, gerar copy (6 canais: Instagram, LinkedIn, Email, WhatsApp, Facebook Ads, Google Ads) e lead kit comercial
- **LaunchAgents** (backend + tunnel) com KeepAlive
- **Skill orquestradora** `/lead-machine-lite` no Claude Code — wizard de terminal com 13 comandos

## Estrutura

```
lead-machine-lite/
├── backend/              # FastAPI (862 LOC) — SYSTEM_PROMPTs literais
│   ├── server.py
│   ├── requirements.txt
│   ├── .env.example
│   └── README.md
├── public/
│   └── index.html        # LP multi-step (860 LOC, marked.js via CDN)
├── dashboard/
│   └── index.html        # Dashboard local aluno (547 LOC, X-Aluno-Token)
└── launchagent/          # Instalação (691 LOC, 7 arquivos)
    ├── install.sh        # bootstrap idempotente
    ├── uninstall.sh
    ├── restart.sh
    ├── status.sh
    ├── com.zxlab.lead-machine-lite.plist           # backend
    ├── com.zxlab.lead-machine-lite-tunnel.plist    # tunnel
    └── README.md
```

Skill em `~/.claude/skills/lead-machine-lite/` (SKILL.md 122 + run.py 563 + reference.md 110 LOC).

## Endpoints do backend (porta 8792 por padrão)

| Método | Path | Descrição |
|---|---|---|
| GET | `/health` | `{ok: true}` |
| POST | `/lead/new` | Aluno cria lead → primeira pergunta |
| POST | `/lead/answer` | Lead responde → próxima pergunta ou `done:true` |
| GET | `/lead/status/{id}` | Progresso |
| GET | `/lead/result/{id}` | Diagnóstico final (`pending\|ready\|error`) |
| GET | `/api/leads` | Lista leads (aluno, requer X-Aluno-Token se setado) |
| GET | `/api/lead/{id}` | Detalhe completo |
| POST | `/lead/generate-copy` | `{lead_id, channel}` → copy markdown |
| POST | `/lead/generate-kit` | `{lead_id}` → kit comercial markdown |
| GET | `/dashboard` | Serve dashboard HTML |

## Instalação (aluno)

```bash
git clone <repo> ~/zx-control-skills-agencia
cd ~/zx-control-skills-agencia/lead-machine-lite/launchagent
./install.sh
# Editar ~/.zx-lead-machine/backend/.env e colocar ANTHROPIC_API_KEY
./restart.sh
./status.sh    # ver URL pública + health
```

## Validação executada (2026-05-20)

- ✅ `py_compile` backend OK (862 LOC)
- ✅ `py_compile` skill run.py OK (563 LOC)
- ✅ `bash -n` em todos os scripts (.sh)
- ✅ `plutil -lint` nos 2 plists
- ✅ Smoke test: backend sobe, `/health` 200, `/api/leads` 200 (lista vazia), `/dashboard` 200 com HTML válido
- ✅ Skill CLI `--help` lista 13 subcomandos

## Diferenciação 50K (gancho de upgrade)

| Lite (ZX Control R$497) | 50K (R$50K) |
|---|---|
| Mac do aluno = servidor | SaaS hospedado pelo Rafael |
| Tunnel cai quando Mac dorme | URLs públicas 24/7 |
| Storage JSON local single-user | CRM multi-cliente persistente |
| Sem auth (single-aluno) | Auth + RLS multi-tenant |
| Copy/kit on-demand | Call Coach realtime + Prototyper stateful |
| Suporte assíncrono | Suporte 1:1 + masterclasses |

## Origem (não inventado, reproduzido fielmente)

- Spec completa: [lead-machine-lite-spec.md](../lead-machine-lite-spec.md) (31KB)
- Repo original: `zxmarketingdigital/zxleadmachinemvp1`
- Functions originais portadas: `diagnostic-chat`, `diagnostic-report`, `generate-copy`, `generate-lead-kit`
- Functions NÃO portadas (intencional): `public-lead-bootstrap`, `public-lead-create`, `public-lead-answer`, `public-lead-status`, `public-lead-result` (substituídas por endpoints unificados sem Supabase)

SYSTEM_PROMPTs preservados literal no `backend/server.py` (CHAT_SYSTEM_PROMPT, REPORT_SYSTEM_PROMPT, COPY_SYSTEM_PROMPT, KIT_SYSTEM_PROMPT) com referência ao arquivo+linha do original em comentário acima de cada um.

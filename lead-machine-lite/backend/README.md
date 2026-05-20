# Lead Machine Lite — Backend

Versão local (Mac do aluno ZX Control) do ZX Lead Machine. Sem Supabase — arquivos JSON em `~/zx-leads/`.

## Run

```bash
cp .env.example .env   # editar ANTHROPIC_API_KEY
pip install -r requirements.txt
uvicorn server:app --host 0.0.0.0 --port 8792
```

## Endpoints

- `POST /lead/new` — cria lead, retorna `lead_id` + primeira pergunta
- `POST /lead/answer` — registra resposta, retorna próxima pergunta ou `done: true`
- `GET /lead/result/{lead_id}` — diagnóstico final (`pending|ready|error`)
- `GET /lead/status/{lead_id}` — progresso
- `GET /health` — `{ok: true}`

Storage: `~/zx-leads/{lead_id}.json`. LLM: Claude API direto (Sonnet 4.6).

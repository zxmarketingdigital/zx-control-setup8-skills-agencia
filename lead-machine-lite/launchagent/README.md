# Lead Machine Lite — Instalação local

Backend FastAPI + tunnel público (cloudflared) rodando 100% local no seu Mac.
O lead acessa pela URL pública; os dados nunca saem da sua máquina.

---

## Pré-requisitos

- **macOS** (testado em Sequoia 15+)
- **Python 3.10+** — verifique com `python3 --version`. Se faltar: `brew install python@3.12`
- **cloudflared** (opcional, mas necessário pra URL pública) — `brew install cloudflare/cloudflare/cloudflared`
- **Chave Anthropic** — pegue em [console.anthropic.com](https://console.anthropic.com/settings/keys)

---

## Instalação (1 comando)

Dentro da pasta do repo:

```bash
cd lead-machine-lite/launchagent
./install.sh
```

O script é **idempotente** — pode rodar quantas vezes quiser, sempre atualiza arquivos e re-carrega os serviços.

O que ele faz:

1. Verifica Python + pip + cloudflared
2. Cria `~/.zx-lead-machine/{backend,logs,venv}` e `~/zx-leads/`
3. Instala dependências em venv isolado
4. Cria `.env` (pede pra você editar e colar a chave Anthropic)
5. Gera um `ALUNO_TOKEN` aleatório (32 chars) pro dashboard
6. Instala 2 LaunchAgents (backend + tunnel)
7. Sobe os serviços e captura a URL pública

No final mostra:

```
URL pública (mande pro lead): https://abc-def-ghi.trycloudflare.com
Dashboard local (você):       http://localhost:8792/dashboard?token=...
```

---

## Onde acho a URL pública depois?

```bash
cat ~/.zx-lead-machine/tunnel-url.txt
# ou
./status.sh
```

---

## Comandos do dia a dia

```bash
./status.sh      # Saúde + logs + leads + URL atual
./restart.sh     # Reinicia backend + tunnel (URL muda)
./uninstall.sh   # Remove LaunchAgents (mantém dados)
./uninstall.sh --purge   # Remove TUDO (incluindo leads salvos)
```

Para atualizar para uma versão nova: `git pull` e rode `./install.sh` de novo.

---

## Troubleshooting

### "Mac dormiu, o tunnel parou"

Isso é esperado. O cloudflared cai junto com o sleep da rede.

**Soluções:**

- **Curto prazo:** abra `System Settings → Lock Screen` → coloque "Turn display off" em `Never` enquanto estiver atendendo o lead. Ou rode `caffeinate -di` em uma aba do terminal.
- **Médio prazo:** mantenha o Mac em pé ligado na tomada com display fechado (`clamshell mode`).
- **Solução definitiva:** subir esse mesmo backend numa VPS própria com domínio fixo (`leads.seudominio.com`). Isso é exatamente o que ensino no upgrade [ZX Agência IA 50K](https://zxlab.com.br/mission-control) — automação 24/7 sem depender do seu Mac.

### "A URL do tunnel muda toda vez"

`trycloudflare.com` gera URL aleatória a cada start. Pra URL fixa (`leads.seudominio.com`), você precisa:

1. Ter domínio próprio na Cloudflare
2. Criar named tunnel: `cloudflared tunnel create lead-machine`
3. Apontar CNAME e configurar `config.yml`

Documentação oficial: [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/install-and-setup/tunnel-guide/).

### "Porta 8792 em uso"

Edite `~/Library/LaunchAgents/com.zxlab.lead-machine-lite.plist` e troque a porta nos 2 lugares (`8792` em `ProgramArguments` e em `PORT`). Faça o mesmo em `com.zxlab.lead-machine-lite-tunnel.plist` (linha `--url http://localhost:8792`). Depois:

```bash
./restart.sh
```

### "Backend não sobe"

```bash
tail -50 ~/.zx-lead-machine/logs/backend.err.log
```

Causas comuns:

- `ANTHROPIC_API_KEY` faltando ou inválido em `~/.zx-lead-machine/backend/.env`
- Dependência travada — apague o venv e reinstale: `rm -rf ~/.zx-lead-machine/venv && ./install.sh`

### "Tunnel sobe mas URL não aparece"

```bash
tail -30 ~/.zx-lead-machine/logs/tunnel.err.log
```

Geralmente é cloudflared desatualizado: `brew upgrade cloudflared && ./restart.sh`.

---

## Layout dos arquivos instalados

```
~/.zx-lead-machine/
├── backend/
│   ├── server.py            ← código FastAPI (sobrescrito no install)
│   ├── requirements.txt
│   ├── .env.example
│   └── .env                 ← SUAS chaves (chmod 600)
├── venv/                    ← virtualenv isolado
├── logs/
│   ├── backend.out.log
│   ├── backend.err.log
│   ├── tunnel.out.log
│   └── tunnel.err.log
└── tunnel-url.txt           ← URL pública atual

~/zx-leads/
└── {lead_id}.json           ← um arquivo por lead diagnosticado

~/Library/LaunchAgents/
├── com.zxlab.lead-machine-lite.plist
└── com.zxlab.lead-machine-lite-tunnel.plist
```

---

## Desinstalar

```bash
./uninstall.sh           # remove só os LaunchAgents
./uninstall.sh --purge   # remove tudo (cuidado: apaga leads salvos)
```

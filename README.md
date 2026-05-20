# ZX Control — Setup 8: Skills da Agência IA + Lead Machine Lite no seu Mac

Setup oficial da Semana 8 do ZX Control Scale. 5 ferramentas profissionais de IA + máquina de captação de leads rodando no seu Mac — sem mensalidade, sem nuvem, sem depender de ninguém.

## Pré-requisitos

- macOS (Linux/Windows funcionam parcialmente — sem LaunchAgents)
- Setup 7 do ZX Control concluído (`phase_completed >= 7` em `~/.operacao-ia/config/config.json`)
- Python 3.10+ (backend Lead Machine exige 3.10; skills rodam em 3.9+) — `brew install python@3.12`
- Claude Code CLI instalado e configurado (`claude.ai/code` — pré-req do ZX Control)
- `cloudflared` pra tunnel público da LP — `brew install cloudflare/cloudflare/cloudflared` (o install.sh tenta instalar sozinho se faltar)
- `ANTHROPIC_API_KEY` pra LLM das skills e do diagnóstico de leads — gera em `console.anthropic.com/settings/keys`

## Instalação

```bash
git clone https://github.com/zxmarketingdigital/zx-control-setup8-skills-agencia
cd zx-control-setup8-skills-agencia
claude
```

Ao abrir o Claude, ele vai aguardar você digitar **`INICIAR SETUP SEMANA 8`** para começar.

A partir daí o setup é guiado — 5 etapas, cada uma com explicação + execução + validação.

## O que será instalado

- **5 Skills Bloco A** — Copie pra ~/.claude/skills/ e ficam disponíveis imediatamente no Claude Code
- **Lead Machine Lite backend** — FastAPI na porta local com LaunchAgent — inicia no boot do Mac
- **Cloudflared tunnel** — Expõe a LP de captação publicamente via URL pública
- **Lead Machine dashboard** — Interface local para gerenciar e visualizar leads


## Estrutura

```
skills-agencia/
├─ CLAUDE.md            # roteiro de instalação (lido pelo Claude Code)
├─ MASTERCLASS.md       # roteiro da aula em vídeo
├─ setup/               # scripts Python das etapas
├─ skills/              # SKILL.md (se aplicável)
├─ scripts/             # automações pós-setup
├─ docs/                # dashboard local (opcional)
└─ launchagents/        # plists macOS (opcional)
```

## Comandos pós-instalação

```
/diagnostico-empreendedor   Diagnóstico completo do seu perfil de empreendedor + plano 30d
/analise-call               Análise de call de vendas com feedback estruturado
/prototipar-sistema         Gera brief + protótipo HTML interativo pra cliente
/simulador-vendas           Simula lead pra você treinar a abordagem
/criar-orcamento            Proposta comercial estruturada em 3 minutos
/lead-machine-lite          Wizard completo: criar leads, ver diagnósticos, gerenciar tunnel

```

## Limitações conhecidas

- **macOS only**: LaunchAgents são exclusivos do macOS. Windows/Linux não suportados nesta versão.
- **Mac precisa ligado**: Tunnel e backend ficam offline quando o Mac dorme. Isso é feature — upgrade pro 50K resolve.
- **1 cliente por vez via Lead Machine**: Versão lite é single-tenant local. Multi-cliente 24/7 = ZX Growth SaaS (Agência IA 50K).


## Suporte

Mentoria semanal ZX Control: https://zxlab.com.br/mission-control
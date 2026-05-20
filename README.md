# ZX Control — Setup 8: Skills da Agência IA + Lead Machine Lite no seu Mac

Setup oficial da Semana 8 do ZX Control Scale. 5 ferramentas profissionais de IA + máquina de captação de leads rodando no seu Mac — sem mensalidade, sem nuvem, sem depender de ninguém.

## Pré-requisitos

- macOS (Linux/Windows funcionam parcialmente — sem LaunchAgents)
- Setup 7 do ZX Control concluído (`phase_completed >= 7` em `~/.operacao-ia/config/config.json`)
- Python 3.9+
- Claude Code instalado e configurado
- {'recurso': 'Claude Code CLI', 'pra_que_serve': 'rodar skills no terminal', 'como_obtem': 'claude.ai/code — pré-req do ZX Control'}
- {'recurso': 'Python 3.10+', 'pra_que_serve': 'backend Lead Machine', 'como_obtem': 'brew install python3 (install.sh verifica)'}
- {'recurso': 'cloudflared', 'pra_que_serve': 'tunnel público LP Lead Machine', 'como_obtem': 'brew install cloudflare/cloudflare/cloudflared (install.sh instala)'}
- {'recurso': 'ANTHROPIC_API_KEY', 'pra_que_serve': 'LLM das skills', 'como_obtem': 'console.anthropic.com — instrução no install.sh'}

## Instalação

```bash
git clone https://github.com/zxmarketingdigital/skills-agencia
cd skills-agencia
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
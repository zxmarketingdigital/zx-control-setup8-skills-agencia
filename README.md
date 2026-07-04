# ZX Control — Setup 8: Agentes de Vendas e Captura de Leads (ZX Growth + ZX Lead Machine)

Setup oficial da Semana 8 do ZX Control Scale. 6 skills da Agência IA (ZX Growth) + Lead Machine Lite (ZX Lead Machine) — agentes de vendas e captação de leads via diagnóstico empresarial — sem mensalidade, sem nuvem, sem depender de ninguém.

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

- **6 Skills Bloco A** — Copie pra ~/.claude/skills/ e ficam disponíveis imediatamente no Claude Code
- **Banco de objeções compartilhado** — `~/.claude/skills/_shared/objections-bank/` YAML por segmento, consumido por simulador/análise/orçamento
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
/analise-call               Análise de call de vendas com feedback + Risk Flags 🔴🟡🟢
/prototipar-sistema         Gera brief + protótipo HTML interativo pra cliente
/simulador-vendas           Simula lead — suporta --focus desvio-preco/omissao-mensalidade/sem-case
/criar-orcamento            Proposta com recorrência no header + ROI por nicho
/pre-call-checklist         Checklist obrigatório antes de qualquer call — 6 itens + frases-modelo
/lead-machine-lite          Wizard completo: criar leads, ver diagnósticos, gerenciar tunnel

```

## Suporte por sistema operacional

| Bloco | macOS | Linux | Windows |
|-------|-------|-------|---------|
| **A — 6 skills (ZX Growth)** | ✅ | ✅ | ✅ (WSL2 ou Python 3.10+ nativo) |
| **B — Lead Machine Lite (ZX Lead Machine)** | ✅ | ❌ | ❌ |

`install.sh` detecta o SO automaticamente:
- **macOS:** instala Bloco A + Bloco B (LaunchAgents + cloudflared tunnel)
- **Linux/Windows:** auto-ativa `--bloco-a` e instala APENAS as 6 skills. Pula o Lead Machine Lite com aviso. Você ganha as ferramentas de IA pra cliente (diagnóstico, análise call, prototipar sistema, simulador, orçamento). Lead Machine vem em versão multiplataforma na Agência IA 50K.

## Limitações conhecidas

- **Lead Machine Lite é macOS-only**: depende de LaunchAgents + cloudflared rodando local. Linux/Windows: usa Agência IA 50K (SaaS multi-tenant) ou monta servidor próprio com a stack do `lead-machine-lite/backend/`.
- **Mac precisa ligado** (só Bloco B): Tunnel e backend ficam offline quando o Mac dorme. Isso é feature — upgrade pro 50K resolve.
- **1 cliente por vez via Lead Machine**: Versão lite é single-tenant local. Multi-cliente 24/7 = ZX Growth SaaS (Agência IA 50K).


## Suporte

Mentoria semanal ZX Control: https://zxlab.com.br/mission-control
---
name: analise-call
description: "Analisa call de vendas (cola resumo ou busca no Zoom via MCP). Identifica objeções perdidas, gatilhos não usados, próximos passos sugeridos + script de follow-up sugerido (extra ZX LAB, não vem do schema original do ZX Growth). Output em Markdown. Use quando aluno disser: analisar call de vendas, revisar call comercial, feedback de call, análise call cliente, call coach, melhorar próxima call, follow-up call vendas, /analise-call."
model: sonnet
effort: medium
---

# analise-call — Análise de Call de Vendas (ZX Growth port)

## Resumo

Skill local que reproduz fielmente o analisador de calls do **ZX Growth** (Lovable / Supabase Edge Function `analyze-sales-call`). Recebe a transcrição/resumo de uma call de vendas, gera análise estruturada (score, strengths, blockers, improvements, objections, qualification, next_call_focus) e renderiza em Markdown salvo em `~/calls/{cliente-slug}/call-{YYYY-MM-DD}.md`.

Dois modos de entrada:

1. **Modo cola** — aluno cola texto da call (transcrição ou resumo) direto no chat.
2. **Modo Zoom MCP** — aluno pede pra buscar; a skill lista meetings recentes via `mcp__aca3ff2a-ebb3-4554-aec0-bc2d7d6dc9b2__search_meetings`, aluno escolhe, skill baixa transcrição via `mcp__aca3ff2a-ebb3-4554-aec0-bc2d7d6dc9b2__get_recording_resource` / `get_meeting_assets`.

## Origem

- Código fonte: `/tmp/zx-analise/zxgrowth/supabase/functions/analyze-sales-call/index.ts`
- Consumidor React (contexto de uso): `/tmp/zx-analise/zxgrowth/src/pages/app/CallDetail.tsx` (linhas 487–502)
- Detalhamento de port: `reference.md`

## ⚠️ REGRA DE FIDELIDADE — INVIOLÁVEL

Este SYSTEM_PROMPT, schema da função `analyze_call` e regras de avaliação são **cópia literal** do `analyze-sales-call/index.ts` do ZX Growth. **NUNCA reescrever, resumir, traduzir ou "melhorar"**. Mudar texto ou campos quebra paridade com a Edge Function em produção.

Mudanças permitidas: somente transporte (HTTP → conversação local), persistência (Supabase → Markdown local) e fonte da transcrição (upload → cola/MCP Zoom). Lógica do prompt + schema = intocáveis.

## Workflow

### Etapa 1 — Coleta da transcrição

**Se o aluno colou texto** → usar direto como `transcript_text`. Pedir título (`call_title`) se não estiver óbvio.

**Se aluno pediu busca Zoom**:

```
1. mcp__aca3ff2a-ebb3-4554-aec0-bc2d7d6dc9b2__search_meetings
   args: { query: "<termo, ex: cliente, dia>", limit: 10 }
2. Listar pro aluno escolher (índice numerado).
3. mcp__aca3ff2a-ebb3-4554-aec0-bc2d7d6dc9b2__get_meeting_assets
   args: { meeting_uuid: "<escolhido>" }
4. Procurar asset tipo "TRANSCRIPT" ou "AUDIO_TRANSCRIPT".
5. mcp__aca3ff2a-ebb3-4554-aec0-bc2d7d6dc9b2__get_recording_resource
   ou mcp__aca3ff2a-ebb3-4554-aec0-bc2d7d6dc9b2__get_file_content
   pra puxar o texto da transcrição (Zoom AI Companion já transcreve).
```

### Etapa 2 — Coletar contexto opcional do vendedor

Se aluno informar (ou já estiver no contexto do projeto), montar o bloco `user_context`:

```
- nome
- momento_profissional
- maior_dificuldade
- experiencia_ia
```

Não inventar. Se não tiver, omitir o bloco.

### Etapa 3 — Executar análise

**SYSTEM_PROMPT (literal — não editar):**

```
Você é um especialista em análise de calls de vendas. Seu papel é avaliar transcrições de ligações comerciais e fornecer feedback estratégico, prático e objetivo.

REGRAS CRÍTICAS:
1. Responda EXCLUSIVAMENTE no formato JSON especificado pela função "analyze_call"
2. Nunca inclua markdown, explicações ou texto fora do JSON
3. Use português brasileiro (pt-BR)
4. Seja objetivo e estratégico - sem frases motivacionais ou genéricas
5. O score deve ser um número inteiro de 0 a 100
6. Se a transcrição estiver curta, incompleta ou de baixa qualidade, aponte isso em blockers e sugira melhorias

CRITÉRIOS DE AVALIAÇÃO:
- Score 0-30: Call com problemas graves (sem rapport, sem qualificação, sem próximo passo)
- Score 31-50: Call básica com melhorias significativas necessárias
- Score 51-70: Call razoável com pontos a melhorar
- Score 71-85: Boa call com pequenos ajustes
- Score 86-100: Call excelente, modelo a seguir

CRITÉRIOS MÍNIMOS:
- strengths: 3 a 6 itens específicos
- blockers: 3 a 6 itens (erros que travam fechamento)
- improvements: 4 a 8 itens práticos com exemplos de frase
- objections: 2 a 5 itens (se não houver, indicar "não identificada claramente" e orientar como descobrir)
- next_call_focus: exatamente 3 itens prioritários
- qualification: sempre preenchido; se não houver informação, indicar "não identificado na call" e sugerir pergunta
```

**USER_PROMPT (template literal):**

```
Analise a seguinte call de vendas:

Título: {call_title}{contextInfo}

TRANSCRIÇÃO:
{transcript_text}

Forneça uma análise completa usando a função analyze_call.
```

Onde `contextInfo` é, se houver `user_context`:

```
\n\nContexto do vendedor:
Nome do vendedor: ...
Momento profissional: ...
Maior dificuldade: ...
Experiência com IA: ...
```

A skill (rodando dentro do Claude) executa o raciocínio diretamente — não há HTTP. Mas o output JSON deve respeitar **literalmente** o schema abaixo.

### Etapa 4 — Schema de output (literal do tool `analyze_call`)

```json
{
  "type": "object",
  "properties": {
    "score": { "type": "integer", "minimum": 0, "maximum": 100, "description": "Score geral da call de 0 a 100" },
    "strengths": { "type": "array", "items": { "type": "string" }, "minItems": 3, "maxItems": 6, "description": "Lista de 3 a 6 pontos fortes identificados na call" },
    "blockers": { "type": "array", "items": { "type": "string" }, "minItems": 3, "maxItems": 6, "description": "Lista de 3 a 6 erros ou bloqueios que travam o fechamento" },
    "improvements": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "title": { "type": "string", "description": "Título curto da melhoria" },
          "detail": { "type": "string", "description": "Explicação detalhada do que melhorar" },
          "example_phrase": { "type": "string", "description": "Exemplo de frase que poderia ser usada" }
        },
        "required": ["title", "detail", "example_phrase"]
      },
      "description": "Lista de 4 a 8 melhorias práticas com exemplos",
      "minItems": 4,
      "maxItems": 8
    },
    "next_call_focus": { "type": "array", "items": { "type": "string" }, "minItems": 3, "maxItems": 3, "description": "Exatamente 3 focos prioritários para a próxima call" },
    "objections": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "objection": { "type": "string", "description": "A objeção identificada ou 'não identificada claramente'" },
          "how_handled": { "type": "string", "description": "Como foi tratada na call" },
          "better_way": { "type": "string", "description": "Forma melhor de tratar essa objeção" }
        },
        "required": ["objection", "how_handled", "better_way"]
      },
      "description": "Lista de 2 a 5 objeções analisadas",
      "minItems": 2,
      "maxItems": 5
    },
    "qualification": {
      "type": "object",
      "properties": {
        "dor": { "type": "string", "description": "Dor/problema do cliente identificado ou 'não identificado na call - sugestão de pergunta'" },
        "urgencia": { "type": "string", "description": "Nível de urgência do cliente ou 'não identificado na call - sugestão de pergunta'" },
        "budget": { "type": "string", "description": "Orçamento disponível ou 'não identificado na call - sugestão de pergunta'" },
        "decisor": { "type": "string", "description": "Quem é o decisor ou 'não identificado na call - sugestão de pergunta'" },
        "proximo_passo": { "type": "string", "description": "Próximo passo acordado ou 'não identificado na call - sugestão de pergunta'" }
      },
      "required": ["dor", "urgencia", "budget", "decisor", "proximo_passo"],
      "description": "Qualificação do lead baseada na call"
    }
  },
  "required": ["score", "strengths", "blockers", "improvements", "next_call_focus", "objections", "qualification"]
}
```

**Pós-processamento** (do código original):

- `score = Math.max(0, Math.min(100, Math.round(Number(score) || 0)))`
- `model_version = "v1"` (constante)
- Se algum array vier vazio, manter `[]`
- `qualification` ausente → preencher cada campo com `"não identificado na call"`

### Etapa 5 — Renderizar Markdown

Estrutura do arquivo `~/calls/{cliente-slug}/call-{YYYY-MM-DD}.md`:

```markdown
# Análise de Call — {call_title}

**Data:** {YYYY-MM-DD} · **Score:** {score}/100 · **Modelo:** v1

## Qualificação (BANT+)
- **Dor:** {qualification.dor}
- **Urgência:** {qualification.urgencia}
- **Budget:** {qualification.budget}
- **Decisor:** {qualification.decisor}
- **Próximo passo:** {qualification.proximo_passo}

## Pontos Fortes
- ...

## Bloqueios (travam fechamento)
- ...

## Objeções
### {objection}
- **Como foi tratada:** {how_handled}
- **Forma melhor:** {better_way}

## Melhorias Práticas
### {title}
{detail}

> Frase exemplo: "{example_phrase}"

## Foco das próximas 3 calls
1. ...
2. ...
3. ...

## Script de Follow-up sugerido
(Claude gera mensagem WhatsApp/email curta baseada em `next_call_focus` + `qualification.proximo_passo` — esta seção é EXTRA, não vem do schema original, fica claramente marcada.)
```

### Etapa 6 — Gerar HTML + Registrar no Painel ZX LAB (obrigatório)

Padrão ZX LAB: toda skill produz **MD + HTML** (dark theme) e **registra no painel central** `~/zxlab-aluno/index.html`. Cria o painel automaticamente na primeira execução.

```bash
mkdir -p ~/calls/{slug}/

# 1) Escrever MD (Claude usa Write tool)
# 2) Gerar HTML com identidade dark ZX LAB
python3 ~/.claude/skills/_shared/md_to_html.py \
  ~/calls/{slug}/call-{date}.md \
  ~/calls/{slug}/call-{date}.html \
  "Análise de Call — {call_title}" \
  --skill analise-call \
  --cliente "{cliente_display}"

# 3) Registrar no painel central
python3 ~/.claude/skills/_shared/update_launcher.py \
  --html ~/calls/{slug}/call-{date}.html \
  --title "Análise de Call — {call_title}" \
  --skill analise-call \
  --cliente "{cliente_display}" \
  --summary "Score {score}/100. {1_linha_objecao_ou_proximo_passo}"

echo "✅ MD:    ~/calls/{slug}/call-{date}.md"
echo "✅ HTML:  ~/calls/{slug}/call-{date}.html"
echo "🎛️  Painel: open ~/zxlab-aluno/index.html"
echo "Score {score}/100"
```

`{slug}` = derivado do `call_title` (lowercase, sem acento, hífen).
Estilo dark ZX LAB (âmbar #D97706 + Inter + JetBrains Mono, fundo #0D0D0D). Ver `~/.claude/skills/_shared/README.md`.

## Comandos MCP Zoom (referência)

| MCP tool | Uso |
|---|---|
| `mcp__aca3ff2a-ebb3-4554-aec0-bc2d7d6dc9b2__search_meetings` | Buscar meetings por termo/data |
| `mcp__aca3ff2a-ebb3-4554-aec0-bc2d7d6dc9b2__recordings_list` | Listar gravações disponíveis |
| `mcp__aca3ff2a-ebb3-4554-aec0-bc2d7d6dc9b2__get_meeting_assets` | Listar assets (transcrição, áudio, sumário) de um meeting |
| `mcp__aca3ff2a-ebb3-4554-aec0-bc2d7d6dc9b2__get_recording_resource` | Baixar resource específico |
| `mcp__aca3ff2a-ebb3-4554-aec0-bc2d7d6dc9b2__get_file_content` | Ler conteúdo textual de transcrição |

## O que NÃO está portado

- **`realtime-call-coach`** (`/tmp/zx-analise/zxgrowth/supabase/functions/realtime-call-coach/index.ts`) — coach em tempo real durante a call (WebSocket / streaming). Skill local é **pós-call** apenas. Coach realtime exige áudio ao vivo + latência baixa que terminal Claude não entrega.
- Persistência em Supabase / RLS / auth — substituído por arquivo Markdown local em `~/calls/`.
- Rate limit / 429 / 402 do AI Gateway Lovable — não aplicável (Claude roda local).

Detalhes em `reference.md`.

# reference.md — analise-call

Port da Edge Function `analyze-sales-call` do ZX Growth (Lovable) pra skill local Claude Code.

## Tabela de Origem → Trecho usado → Adaptação

| Arquivo origem | Trecho / símbolo | O que foi feito | Adaptação |
|---|---|---|---|
| `supabase/functions/analyze-sales-call/index.ts` (linhas 98–121) | `systemPrompt` | Copiado **literal** pra SKILL.md (bloco "SYSTEM_PROMPT") | Nenhuma — fidelidade obrigatória |
| `index.ts` (linhas 123–130) | `userPrompt` template | Copiado **literal** como "USER_PROMPT template" | Nenhuma |
| `index.ts` (linhas 144–227) | Tool `analyze_call` parameters schema | Copiado **literal** em "Schema de output" | Removido `type: "function"` wrapper; mantidos todos os campos, types, minItems/maxItems, descriptions |
| `index.ts` (linhas 22–37) | Interface `AnalysisResult` | Espelhada no Markdown de saída | `model_version` continua `"v1"` (constante) |
| `index.ts` (linhas 86–96) | Montagem `contextInfo` | Copiada como template no workflow | Nenhuma — mesmas chaves (nome, momento_profissional, maior_dificuldade, experiencia_ia) |
| `index.ts` (linhas 271–288) | Pós-processamento (`Math.max/min/round`, fallback `qualification`) | Documentado na seção "Pós-processamento" | Nenhuma — Claude deve aplicar os mesmos clamps |
| `index.ts` (linhas 9–14) | Interface `UserContext` | Espelhada literalmente | Nenhuma |
| `src/pages/app/CallDetail.tsx` (linhas 487–502) | Chamada do consumidor React | Usada só pra confirmar shape de input `{ call_title, transcript_text, user_context }` | Input agora vem de chat (cola) ou MCP Zoom |
| `supabase/functions/realtime-call-coach/index.ts` | **NÃO PORTADO** | — | Realtime coach exige áudio streaming durante a call; skill é pós-call |

## Decisões de port

### Transporte
- Original: HTTP POST → Lovable AI Gateway (`ai.gateway.lovable.dev/v1/chat/completions`) com `model: "google/gemini-3-flash-preview"` + tool calling forçado.
- Skill: raciocínio direto do Claude (modelo `sonnet`, effort `medium`) seguindo o mesmo SYSTEM_PROMPT e produzindo JSON que respeita o schema.

### Persistência
- Original: resultado retornado JSON → frontend salva em tabela Supabase (`calls`).
- Skill: arquivo `~/calls/{cliente-slug}/call-{YYYY-MM-DD}.md` renderizado em Markdown humano (Rafael lê direto).

### Fonte de transcrição
- Original: usuário fazia upload de áudio → função `transcribe-audio` (não portada nesta skill) → `transcript_text` salvo.
- Skill: dois modos — (a) aluno cola texto, (b) MCP Zoom puxa transcrição já gerada pelo AI Companion.

### Auth + rate limit
- Original: JWT Supabase + handling de 429 / 402 da Lovable.
- Skill: nenhum — Claude local não tem esses gates.

## Por que `realtime-call-coach` foi descartado

Arquivo: `/tmp/zx-analise/zxgrowth/supabase/functions/realtime-call-coach/index.ts` (5.8K).
Função: alimentar coach ao vivo durante a call (provavelmente WebSocket / streaming).
Skill local **é pós-call** — análise depois que a transcrição existe. Coach realtime exigiria:

1. Captura de áudio em tempo real (não disponível via terminal).
2. Streaming bidirecional baixa latência (Claude Code não tem socket aberto durante uma call Zoom).
3. UI visual sobreposta (skill só gera Markdown).

Se Rafael quiser coach realtime, vira projeto separado (provavelmente app desktop). Não tem cabimento empacotar como skill.

## Campos do schema — referência rápida

| Campo | Tipo | Min | Max | Notas |
|---|---|---|---|---|
| `score` | int | 0 | 100 | clamp + round obrigatório |
| `strengths` | string[] | 3 | 6 | |
| `blockers` | string[] | 3 | 6 | |
| `improvements[]` | { title, detail, example_phrase } | 4 | 8 | example_phrase é frase pronta pra usar |
| `next_call_focus` | string[] | 3 | 3 | **exatos** 3 |
| `objections[]` | { objection, how_handled, better_way } | 2 | 5 | se nada, "não identificada claramente" |
| `qualification` | { dor, urgencia, budget, decisor, proximo_passo } | — | — | nunca vazio; usar "não identificado na call" |

## Critérios de score (literal do prompt original)

- 0–30 → problemas graves (sem rapport, sem qualificação, sem próximo passo)
- 31–50 → básica com melhorias significativas
- 51–70 → razoável
- 71–85 → boa, ajustes pequenos
- 86–100 → excelente, modelo

## Extensões locais (claramente marcadas como NÃO-originais)

- **Script de follow-up** renderizado no final do MD a partir de `next_call_focus` + `qualification.proximo_passo`. Marca: o original NÃO retorna esse campo; skill local adiciona como "seção extra" pra facilitar disparo WhatsApp/email pelo aluno.
- **Slug derivado do título** pra organizar em `~/calls/{slug}/`.

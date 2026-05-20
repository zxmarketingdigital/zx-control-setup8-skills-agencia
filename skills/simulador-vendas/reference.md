# simulador-vendas — Referência técnica

## Origem → Trecho → Adaptação

| Origem (ZX Growth) | Trecho relevante | Adaptação local |
|---|---|---|
| `supabase/functions/simulate-client-reply/index.ts` L60-77 | `systemPrompt` "Você é um CLIENTE/LEAD..." + tags | **Literal** no SKILL.md, injetado pelo Claude em cada turno |
| `simulate-client-reply/index.ts` L175-217 `buildClientPersona()` | Maps `orcamentoMap`/`urgenciaMap`/`decisorMap` + estrutura `VOCÊ É UM CLIENTE FICTÍCIO` | **Literais** no SKILL.md |
| `simulate-client-reply/index.ts` L219-247 `getScenarioInstructions()` | 3 blocos diagnostico/proposta/fechamento | **Literais** no SKILL.md |
| `simulate-client-reply/index.ts` L91-101 | `model: 'google/gemini-2.5-flash'`, temp 0.7, max 500 | Substituído: Claude Code do aluno conduz com o mesmo prompt |
| `simulate-client-reply/index.ts` L96 | `[VENDEDOR]: {seller_message}` | **Literal** — Claude DEVE prefixar a mensagem do aluno antes de gerar o turn |
| `simulate-client-reply/index.ts` L133-150 | Parse JSON com regex `\{[\s\S]*\}` + fallback `'Pode me explicar melhor?'` + tags `['confusão']` | Mantido — se response não for JSON parseável, fallback literal |
| `supabase/functions/generate-trainer-report/index.ts` L56-89 | `systemPrompt` coach + schema JSON do relatório | **Literal** no SKILL.md |
| `generate-trainer-report/index.ts` L92-94 | `formattedConversation`: `[VENDEDOR]: ... \n\n[CLIENTE]: ...` join `\n\n` | **Literal** |
| `generate-trainer-report/index.ts` L48-52 | `scenarioLabel` map (Diagnóstico/Proposta/Fechamento) | **Literal** |
| `generate-trainer-report/index.ts` L106 | User msg: `Analise esta conversa de simulação de vendas:\n\n{...}\n\nGere o relatório de feedback em JSON.` | **Literal** |
| `generate-trainer-report/index.ts` L102-110 | temp 0.5, max_tokens 2000 | Substituído por Claude direto |
| `generate-trainer-report/index.ts` L155-169 | Fallback report: score 50, "Análise inconclusiva", focus default `['Praticar mais', 'Fazer perguntas abertas', 'Ouvir ativamente']` | **Literal** — usar se Claude não devolver JSON parseável |
| `generate-trainer-report/index.ts` L172-185 | Normalização: `score` clamp 0-100, `next_session_focus.slice(0,3)`, arrays vazios default | **Literal** |
| `src/hooks/useTrainerSession.ts` L30-44 | Interface `TrainerReport` (schema completo dos campos do relatório) | **Literal** — schema do JSON salvo no MD |
| `src/hooks/useTrainerSession.ts` L46-57 | Interface `ScenarioContext` (source_type, scenario_type, difficulty, lead_data, scenario_brief) | **Literal** — exceto `source_type: 'crm_lead'` removido (sem CRM local) |
| Tabelas `trainer_sessions` / `trainer_messages` / `trainer_reports` | Persistência Supabase | Substituído por arquivo MD em `~/treino-vendas/sessao-{ts}.md` |
| Supabase Edge Function → HTTP POST request/response por turno | `useSimulateClientReply()` hook | Substituído por loop turn-by-turn no terminal Claude Code |

## Notas sobre o fluxo turn-by-turn

- **Ordem importa:** SYSTEM_PROMPT é construído a cada turno com `clientPersona + scenarioInstructions` **já interpolados** (não deixar `{segmento}` como placeholder).
- **History tracking:** manter `recent_messages: [{role: 'user'|'assistant', content}]` igual ao original. `role: 'user'` = vendedor (aluno), `role: 'assistant'` = cliente (Claude).
- **Cada mensagem nova do aluno** vem como `user` content `[VENDEDOR]: {texto}`. Claude responde como `assistant`.
- **Parse do JSON do cliente:** se o LLM retornar com fences ```json ... ```, fazer `replace(/```json|```/g, '').trim()` antes de parsear. Igual ao código original (linha 147).
- **Encerramento manual:** aluno pode dizer `fim` / `encerrar` / `parar` / `gerar relatório` a qualquer momento.
- **Encerramento automático (soft):** após 20 trocas (10 vendedor + 10 cliente), perguntar se quer continuar ou gerar relatório.
- **Dificuldade `hard`:** SYSTEM_PROMPT inclui linha 6 literal: `"Seja mais resistente e desconfiado."`. Caso contrário: `"Seja receptivo mas com dúvidas normais."`.
- **`source_type: 'crm_lead'`:** removido na skill local (sem acesso ao CRM do ZX Growth). Se um dia integrar com `agencia-ia-connect` (`pnfvlszwlumetdjsuktj`), reativar com o bloco `buildClientPersona` original (L176-183).

## Diretório de saída

- `~/treino-vendas/` — criar com `mkdir -p` na primeira execução.
- Nome do arquivo: `sessao-{YYYY-MM-DD-HHMM}.md` (sem segundos).
- Conteúdo: contexto + transcrição completa (com tags) + relatório formatado em MD.

## Possíveis evoluções (NÃO implementar agora)

- Modo `--crm-lead`: ler lead real do CRM `agencia-ia-connect` e usar `buildClientPersona` com `source_type='crm_lead'`.
- Modo `--audio`: gravar respostas do aluno via voice + transcrever.
- Histórico de scores por aluno (track progressão em sessões repetidas).
- Cada uma dessas exige nova rodada de fidelidade ao original — não inventar.

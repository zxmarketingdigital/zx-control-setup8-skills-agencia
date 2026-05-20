# reference — diagnostico-empreendedor

## Tabela origem → destino

| Origem (ZX Growth) | Trecho usado | Adaptação na skill |
|---|---|---|
| `generate-diagnostic/index.ts` L8-16 | `ALLOWED_PROFILES` (7) | Copiado literal pra seção "Listas Pré-Definidas" |
| `generate-diagnostic/index.ts` L18-26 | `ALLOWED_AREAS` (7) | Copiado literal pra seção "Listas Pré-Definidas" |
| `generate-diagnostic/index.ts` L125-143 | `systemPrompt` (diagnóstico) | Copiado literal em "SYSTEM_PROMPT do Diagnóstico" |
| `generate-diagnostic/index.ts` L145-154 | `userPrompt` template | Copiado literal como "User prompt template" |
| `generate-diagnostic/index.ts` L180-281 | Tool schema `generate_diagnostic` | Convertido em JSON schema enxuto em "Schema JSON do diagnóstico" — campos, enums, minItems/maxItems preservados |
| `generate-plan/index.ts` L104-178 | Prompt completo do plano | Copiado literal em "SYSTEM_PROMPT do Plano 30d" |
| `generate-plan/index.ts` L171-178 | Regras (tasks 18-30, cadence, due_date, pt-BR) | Replicadas no bloco "Validações hard-coded" do plano |
| `useDiagnosticChat.ts` L7-18 | `DIAGNOSTIC_QUESTIONS` (10) | Copiado literal Q1..Q10 no Workflow step 4 |
| `useDiagnosticChat.ts` L49-62 | `getWelcomeMessage` | Copiado literal em Workflow step 3 |
| `useDiagnosticChat.ts` L64-68 | `getCompletionMessage` | Copiado literal em Workflow step 5 |
| `Chat.tsx` L82-93 | Banner "refazer a cada 30 dias" | Mantido como mensagem final no step 10 |
| `Chat.tsx` L68-79 | Progress (Pergunta N de 10) | Implícito no Workflow — Claude pergunta uma por vez |

## Pontos de divergência justificados

| Original | Skill | Razão |
|---|---|---|
| Auth Supabase + RLS | Sem auth | Skill roda local no Claude Code do aluno — único usuário é ele mesmo |
| `chat_sessions` + `chat_messages` (Postgres) | Memória de conversa do Claude | Não precisa persistir entre sessões — diagnóstico é one-shot |
| `users_profile` table | Coleta de **contexto base** one-shot (nome, momento_profissional, maior_dificuldade, experiencia_ia) — **NÃO conta como pergunta do chat** | Original assume profile pré-existente (vem de `users_profile`). Skill coleta inline SOMENTE se aluno não tiver perfil prévio. As perguntas oficiais do chat continuam sendo APENAS Q1-Q10 — coleta de contexto é separada, não numerada. |
| Lovable AI Gateway (`google/gemini-2.5-flash` + tool calling) | Claude do aluno gera direto | Skill roda dentro de sessão Claude Code — modelo é o próprio Claude, sem API key |
| `diagnostics` + `plans` + `plan_tasks` tables | Arquivos MD em `~/meu-plano/` | Markdown legível pelo aluno, versionável no git pessoal |
| `temperature: 0.7`, `max_tokens: 8000` | Default Claude | Não aplicável — Claude decide |
| HTTP 429 / 402 (rate limit, créditos) | N/A | Não usa API externa |
| `existingDiagnostic` cache | N/A | Cada execução gera novo MD com data no filename — versionamento natural |

## O que NÃO foi portado (e por quê)

- **CORS headers + Deno.serve:** Skill não é HTTP server.
- **Supabase service role key handling:** Sem DB.
- **`profileError` / `messagesError` recovery paths:** Erros vêm da própria conversa — Claude pode pedir esclarecimento.
- **Tool calling estrito (enum validation pelo gateway):** Substituído por validações textuais que Claude deve respeitar (perfis/áreas ∈ listas).
- **Rollback de plan se tasks falhar (`generate-plan` L313-315):** Não aplicável — escrita de MD é atômica em arquivo único.
- **`day_number → due_date` fallback (`generate-plan` L278-292):** Claude calcula due_date direto a partir de start_date + day_number durante geração.

## Notas de adaptação

- **Welcome message:** depende de `profile?.experiencia_ia` (opcional no original). Mantido o `if (experiencia)` condicional no template literal.
- **Completion message — adaptação de UI (terminal vs web):** Original (`useDiagnosticChat.ts:67`) termina com `"👉 Clique no botão abaixo para ver seu diagnóstico."` porque a UI web tem um botão "Ver diagnóstico" depois da Q10. **Na skill, NÃO existe botão** — Claude segue direto pra geração após a última resposta. Por isso o texto final foi trocado pra `"👉 Gerando seu diagnóstico agora..."`, que é a ação real que acontece no terminal. Todo o resto da mensagem (bullets com `–` en-dash, "qual é seu perfil dominante" etc., emoji 👉, quebras `\n\n`) foi mantido EXATO. Justificativa: instruir o aluno a "clicar num botão" inexistente quebraria o fluxo conversacional do terminal.
- **Filename pattern `~/meu-plano/diagnostico-{YYYY-MM-DD}.md`:** novo (não havia no original). Permite múltiplos diagnósticos ao longo do tempo (aluno refaz a cada 30d → histórico).
- **Renderização Markdown do diagnóstico/plano:** estrutura definida na skill (tabelas, headers H2/H3, checkboxes `[ ]` pras tarefas das fases). Fiel aos campos do schema JSON original — só mudou a apresentação.

## Verificações pós-criação

```bash
cat ~/.claude/skills/diagnostico-empreendedor/SKILL.md | head -30
grep -c "Técnico Especialista" ~/.claude/skills/diagnostico-empreendedor/SKILL.md
grep -c "Agentes de Atendimento" ~/.claude/skills/diagnostico-empreendedor/SKILL.md
wc -l ~/.claude/skills/diagnostico-empreendedor/SKILL.md
```

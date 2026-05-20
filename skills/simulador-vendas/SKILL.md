---
name: simulador-vendas
description: "Simulador de call/chat de vendas para aluno treinar. Aluno define perfil do lead (segmento, objeção esperada, tom), skill simula respostas do lead (perfil derivado do scenario_brief com 6 campos: objetivo, segmento, persona, orçamento, urgência, decisor + nível de difficulty) e aluno pratica abordagem e fechamento. Ao final, gera feedback estruturado com plano de melhoria. Output: transcrição + análise + plano. Use quando aluno disser: simular venda, treinar vendas, simulador cliente, praticar objeção, role play vendas, treinar fechamento, simulador call, /simulador-vendas."
model: sonnet
effort: medium
---

# /simulador-vendas

Simulador de roleplay de vendas. O aluno é o **VENDEDOR**, o Claude Code interpreta o **CLIENTE/LEAD** seguindo um perfil definido. Ao final, gera feedback estruturado com plano de melhoria.

## Resumo

- Aluno escolhe cenário (`diagnostico` / `proposta` / `fechamento`), dificuldade (`normal` / `hard`) e perfil do lead.
- Claude simula respostas do cliente turn-by-turn, usando o SYSTEM_PROMPT **literal** do ZX Growth.
- Quando aluno disser `fim` (ou após N trocas), Claude gera relatório estruturado com score 0-100.
- Sessão salva em `~/treino-vendas/sessao-{YYYY-MM-DD-HHMM}.md`.

## Origem

Skill portada de duas Edge Functions do ZX Growth (Lovable):

- `~/projetos/zx-flow-white-label/.../supabase/functions/simulate-client-reply/index.ts` — simula resposta do cliente
- `~/projetos/zx-flow-white-label/.../supabase/functions/generate-trainer-report/index.ts` — gera relatório final

(Análise via `/tmp/zx-analise/zxgrowth/supabase/functions/`)

Hook React consumidor: `src/hooks/useTrainerSession.ts` (interface `TrainerReport` define schema do feedback).

## ⚠️ REGRA DE FIDELIDADE INVIOLÁVEL

- SYSTEM_PROMPT do cliente: **copiado literal** da função `simulate-client-reply`.
- SYSTEM_PROMPT do coach: **copiado literal** da função `generate-trainer-report`.
- Schema de input (`ScenarioContext`): **literal**, sem mudar nomes de campos.
- Schema de output (`TrainerReport`): **literal**, mesmos campos JSON.
- Maps de orçamento/urgência/decisor: **literais**.
- Instruções por cenário (diagnostico/proposta/fechamento): **literais**.
- Tags possíveis (`objeção`, `pergunta`, etc.): **literais**.

**NÃO** reescrever, **NÃO** traduzir, **NÃO** "melhorar". Se o original não tem perfis de lead pré-definidos enumerados, **NÃO INVENTAR** — usar `scenario_brief` (segmento/problema/orçamento/urgência/decisor/objetivo) como no original.

## Workflow

### 1. Coletar contexto da simulação

Perguntar ao aluno (1 mensagem só, lista enxuta):

```
1. Cenário: diagnostico | proposta | fechamento
2. Dificuldade: normal | hard
3. Lead fictício — preencha:
   - segmento (ex: ecommerce moda)
   - problema_principal (ex: CAC alto)
   - orcamento: baixo | medio | alto
   - urgencia: baixa | media | alta
   - decisor: dono | marketing | operacional | outro
   - objetivo_lead (ex: reduzir custo de aquisição em 30%)
```

Construir objeto `scenario_context`:

```json
{
  "source_type": "fictitious",
  "scenario_type": "diagnostico|proposta|fechamento",
  "difficulty": "normal|hard",
  "scenario_brief": {
    "segmento": "...",
    "problema_principal": "...",
    "orcamento": "baixo|medio|alto",
    "urgencia": "baixa|media|alta",
    "decisor": "dono|marketing|operacional|outro",
    "objetivo_lead": "..."
  }
}
```

### 2. Iniciar conversa turn-by-turn

- Aluno envia mensagem como VENDEDOR.
- Claude responde **incorporando o SYSTEM_PROMPT abaixo literalmente** + `clientPersona` + `scenarioInstructions`.
- Resposta DEVE ser JSON: `{"client_reply": "...", "tags": [...]}`.
- Claude exibe APENAS `client_reply` no chat; armazena `tags` no histórico.
- Manter histórico `recent_messages: [{role, content}, ...]` para próximas turnos.

### 3. Encerramento

Encerra quando:
- Aluno digita `fim`, `encerrar`, `parar`, `gerar relatório`.
- OU 20 trocas (vendedor + cliente) — soft cap, perguntar antes.

### 4. Gerar feedback

Aplicar SYSTEM_PROMPT do coach (literal abaixo) sobre toda a conversa. Output JSON `TrainerReport` literal:

```json
{
  "model_version": "v1",
  "score": 0-100,
  "strengths": [...],
  "blockers": [...],
  "improvements": [{"title", "detail", "example_phrase"}],
  "objections_handling": [{"objection", "how_handled", "better_way"}],
  "qualification_quality": {"nota": 0-100, "comentario": "..."},
  "closing_quality": {"nota": 0-100, "comentario": "..."},
  "next_session_focus": [...3 items max]
}
```

### 5. Salvar sessão

Path: `~/treino-vendas/sessao-{YYYY-MM-DD-HHMM}.md`

Estrutura do arquivo:

```markdown
# Treino de Vendas — {data}

## Contexto
- Cenário: {scenario_type}
- Dificuldade: {difficulty}
- Lead: {scenario_brief}

## Transcrição
[VENDEDOR]: ...
[CLIENTE]: ... (tags: ...)
...

## Feedback
Score: {score}/100

### Pontos fortes
- ...

### Bloqueios
- ...

### Melhorias
- **{title}** — {detail}
  - Exemplo: "{example_phrase}"

### Objeções
- {objection}
  - Como tratou: {how_handled}
  - Melhor abordagem: {better_way}

### Qualificação: {nota}/100 — {comentario}
### Fechamento: {nota}/100 — {comentario}

### Próximo treino — focar em
1. ...
2. ...
3. ...
```

### 6. Gerar HTML + Registrar no Painel ZX LAB (obrigatório)

Padrão ZX LAB: toda skill produz **MD + HTML** (dark theme) e **registra no painel central** `~/zxlab-aluno/index.html`. Cria o painel automaticamente na primeira execução.

```bash
# 1) Gerar HTML dark ZX LAB
python3 ~/.claude/skills/_shared/md_to_html.py \
  ~/treino-vendas/sessao-{YYYY-MM-DD-HHMM}.md \
  ~/treino-vendas/sessao-{YYYY-MM-DD-HHMM}.html \
  "Treino de Vendas — {data}" \
  --skill simulador-vendas \
  --cliente "Cenário {segmento}"

# 2) Registrar no painel central
python3 ~/.claude/skills/_shared/update_launcher.py \
  --html ~/treino-vendas/sessao-{YYYY-MM-DD-HHMM}.html \
  --title "Treino — {scenario_type} {segmento}" \
  --skill simulador-vendas \
  --cliente "Cenário {segmento}" \
  --summary "Score {score}/100. Próximo treino: {next_session_focus[0]}."
```

Mostrar ao aluno:
```
✅ MD:    ~/treino-vendas/sessao-{ts}.md
✅ HTML:  ~/treino-vendas/sessao-{ts}.html
🎛️  Painel: open ~/zxlab-aluno/index.html
Score {score}/100
```

Estilo dark ZX LAB (âmbar #D97706 + Inter + JetBrains Mono, fundo #0D0D0D). Ver `~/.claude/skills/_shared/README.md`.

---

## SYSTEM_PROMPT do CLIENTE (literal — simulate-client-reply)

Construir variáveis e injetar:

**`clientPersona`** (gerado por `buildClientPersona(context)`):

Se `source_type === 'fictitious'` e `scenario_brief` presente:

```
VOCÊ É UM CLIENTE FICTÍCIO:
- Segmento: {segmento || 'não especificado'}
- Problema principal: {problema_principal || 'não especificado'}
- Orçamento: {orcamentoMap[orcamento]}
- Urgência: {urgenciaMap[urgencia]}
- Perfil decisor: {decisorMap[decisor]}
- Objetivo: {objetivo_lead || 'resolver o problema mencionado'}
```

Maps **literais**:

```
orcamentoMap = {
  baixo:  'limitado, muito sensível a preço',
  medio:  'moderado, busca custo-benefício',
  alto:   'disponível, foca mais em valor que preço'
}

urgenciaMap = {
  baixa:  'Sem pressa, explorando opções',
  media:  'Quer resolver nos próximos meses',
  alta:   'Precisa resolver urgentemente'
}

decisorMap = {
  dono:        'Dono/CEO - decide sozinho',
  marketing:   'Marketing - precisa convencer diretoria',
  operacional: 'Operacional - precisa aprovar com gestor',
  outro:       'Outro stakeholder'
}
```

**`scenarioInstructions`** (literal por cenário):

`diagnostico`:
```
CENÁRIO: DIAGNÓSTICO (call de descoberta)
O vendedor está tentando entender suas dores e necessidades.
- Seja um pouco desconfiado no início
- Faça perguntas sobre como o vendedor pode ajudar
- Não revele todas as informações de uma vez
- Teste se o vendedor realmente entende seu problema
```

`proposta`:
```
CENÁRIO: PROPOSTA (apresentação de solução)
O vendedor está apresentando uma solução/proposta.
- Peça clareza sobre o que está incluso
- Questione sobre ROI e resultados esperados
- Compare mentalmente com outras opções
- Faça perguntas sobre implementação e suporte
```

`fechamento`:
```
CENÁRIO: FECHAMENTO (negociação final)
O vendedor está tentando fechar o negócio.
- Teste condições de pagamento e descontos
- Use objeções clássicas: "vou pensar", "preciso falar com meu sócio"
- Questione prazos e garantias
- Se convencido, dê sinais de compra
```

**SYSTEM_PROMPT final** (literal):

```
Você é um CLIENTE/LEAD em uma simulação de vendas. Você NÃO é um vendedor nem um mentor.

{clientPersona}

{scenarioInstructions}

REGRAS OBRIGATÓRIAS:
1. Responda SEMPRE como o cliente/lead, nunca como vendedor ou coach.
2. Seja coerente com seu perfil e o contexto do cenário.
3. Insira objeções realistas quando fizer sentido (mas não exagere, 1 a cada 3-4 mensagens no máximo).
4. Responda em português brasileiro natural e conversacional.
5. Mantenha respostas curtas (1-3 frases), como em uma conversa real.
6. {difficulty === 'hard' ? 'Seja mais resistente e desconfiado.' : 'Seja receptivo mas com dúvidas normais.'}

IMPORTANTE: Retorne SOMENTE um JSON válido neste formato exato, sem texto adicional:
{"client_reply": "sua resposta aqui", "tags": ["tag1", "tag2"]}

Tags possíveis: "objeção", "pergunta", "interesse", "confusão", "preço", "prazo", "confiança", "dúvida", "positivo", "negativo"
```

Mensagem do usuário em cada turno: `[VENDEDOR]: {seller_message}`.

Temperature original: `0.7`, max_tokens: `500`.

---

## SYSTEM_PROMPT do COACH (literal — generate-trainer-report)

Variáveis:

```
scenarioLabel = {
  diagnostico: 'Diagnóstico (descoberta de dores)',
  proposta:    'Proposta (apresentação de solução)',
  fechamento:  'Fechamento (negociação final)'
}
```

`contextDescription` (literal):

```
Lead Fictício:
- Segmento: {segmento || 'N/A'}
- Problema: {problema_principal || 'N/A'}
- Orçamento: {orcamento || 'N/A'}
- Urgência: {urgencia || 'N/A'}
- Decisor: {decisor || 'N/A'}
- Objetivo: {objetivo_lead || 'N/A'}
```

**SYSTEM_PROMPT** (literal):

```
Você é um coach de vendas expert analisando uma simulação de roleplay.

CONTEXTO DA SIMULAÇÃO:
{contextDescription}
Tipo: {scenarioLabel}
Dificuldade: {difficulty === 'hard' ? 'Difícil' : 'Normal'}

REGRAS DE ANÁLISE:
1. Seja PRÁTICO e DIRETO. Nada de palestra.
2. Foque em comportamentos observáveis na conversa.
3. Dê exemplos concretos de frases que poderiam ser usadas.
4. Score de 0-100 baseado em:
   - Qualidade das perguntas (se diagnóstico)
   - Clareza da proposta de valor (se proposta)
   - Habilidade de contornar objeções (se fechamento)
   - Condução geral da conversa
5. Seja exigente mas justo.

IMPORTANTE: Retorne SOMENTE um JSON válido neste formato exato, sem texto adicional:
{
  "model_version": "v1",
  "score": 75,
  "strengths": ["ponto forte 1", "ponto forte 2"],
  "blockers": ["problema 1", "problema 2"],
  "improvements": [
    { "title": "Título curto", "detail": "Explicação do que melhorar", "example_phrase": "Frase exemplo que poderia usar" }
  ],
  "objections_handling": [
    { "objection": "Objeção que apareceu", "how_handled": "Como foi tratada", "better_way": "Como poderia ser melhor" }
  ],
  "qualification_quality": { "nota": 70, "comentario": "Comentário sobre qualificação do lead" },
  "closing_quality": { "nota": 65, "comentario": "Comentário sobre tentativa de fechamento" },
  "next_session_focus": ["foco 1", "foco 2", "foco 3"]
}
```

Mensagem do usuário: `Analise esta conversa de simulação de vendas:\n\n{formattedConversation}\n\nGere o relatório de feedback em JSON.`

`formattedConversation`:
```
[VENDEDOR]: ...

[CLIENTE]: ...
```

Temperature original: `0.5`, max_tokens: `2000`.

---

## Perfis de lead pré-definidos

O código original **NÃO TEM** perfis pré-definidos enumerados (nem cético/ocupado/preço/dúvida-técnica). O perfil emerge de `scenario_brief` (segmento + problema + orçamento + urgência + decisor + objetivo) combinado com `difficulty` (`hard` → "mais resistente e desconfiado").

**NÃO INVENTAR** lista de perfis. Coletar os 6 campos do `scenario_brief` literal.

---

## Estrutura do feedback final (literal — TrainerReport interface)

Schema do `useTrainerSession.ts`:

```ts
interface TrainerReport {
  report_id: string;
  session_id: string;
  user_id: string;
  model_version: string;
  score: number;
  strengths: string[];
  blockers: string[];
  improvements: { title: string; detail: string; example_phrase: string }[];
  objections_handling: { objection: string; how_handled: string; better_way: string }[];
  qualification_quality: { nota: number; comentario: string };
  closing_quality: { nota: number; comentario: string };
  next_session_focus: string[];
  created_at: string;
}
```

Campos `report_id`/`session_id`/`user_id`/`created_at` na versão local equivalem ao filename `sessao-{YYYY-MM-DD-HHMM}.md`.

Normalização do output (do código original):
- `score`: `Math.min(100, Math.max(0, Number(...) || 50))`
- `next_session_focus`: máximo 3 items (`.slice(0, 3)`)
- Arrays vazios se não vierem do LLM.

---

## Adaptações vs original

| Original (Lovable) | Skill local |
|---|---|
| HTTP POST → `ai.gateway.lovable.dev` Gemini 2.5 Flash | Claude do aluno conduz a conversa diretamente |
| `supabase.functions.invoke('simulate-client-reply')` por turno | Loop turn-by-turn no terminal Claude Code |
| Persist em tabelas `trainer_sessions` / `trainer_messages` / `trainer_reports` | Arquivo MD local em `~/treino-vendas/sessao-{ts}.md` |
| `source_type: 'crm_lead'` lê do CRM | Removido — só `fictitious` (CRM do ZX Growth não está disponível aqui) |
| `lead_id` / `deal_id` / `user_id` | N/A (sessão local) |

**Inalterados:** todos os SYSTEM_PROMPTs, schemas JSON, maps, instruções de cenário, regras de parsing/fallback.

---

## Pitfalls

- NÃO esquecer de prefixar mensagem do aluno com `[VENDEDOR]:` ao montar o prompt do cliente.
- NÃO formatar o JSON do cliente fora do parser — se vier com ```json fences, strip antes (`replace /```json|```/g`).
- NO relatório, se Claude não devolver JSON parseável, usar fallback literal do código original (score 50 + texto "Análise inconclusiva").
- `next_session_focus`: cortar com `.slice(0, 3)` mesmo que LLM mande 5.

---
name: diagnostico-empreendedor
description: "Diagnóstico do aluno como empreendedor: aluno responde chat sobre si mesmo (background, skills, momento, recursos, tempo), sistema classifica em 1 dos 7 perfis pré-definidos (Técnico Especialista, Vendedor Comunicador, Executor Prático, Estrategista Visionário, Estudante Profissional, Especialista Mal Pago, Autodidata que Não Escala) + sugere EXATAMENTE 3 das 7 áreas de atuação alinhadas + gera plano de ação 30d com tarefas pra construir a agência IA dele mesmo. NÃO é pra diagnosticar cliente — é pro aluno. Use quando aluno disser: diagnóstico empreendedor, perfil empreendedor, qual meu perfil agência, plano 30 dias agência IA, montar minha agência, descobrir minha área agência IA, diagnóstico zx growth, /diagnostico-empreendedor."
model: sonnet
effort: medium
---

# Diagnóstico Empreendedor (Agência IA)

## Resumo

Diagnóstico **pro próprio aluno** (não pro cliente dele): aluno responde 10 perguntas sobre quem ele é como profissional, sistema classifica em **1 dos 7 perfis** + sugere **3 das 7 áreas de atuação** + gera **plano de ação 30 dias** com tarefas práticas pra ele construir a agência IA dele mesmo. Skill replica fielmente o ZX Growth original (edge functions Supabase) adaptado pra rodar 100% dentro do Claude Code, sem precisar de API key — o próprio Claude do aluno conduz o chat, classifica e gera o plano.

## Origem

- **Chat + diagnóstico:** `/tmp/zx-analise/zxgrowth/supabase/functions/generate-diagnostic/index.ts` (373 LOC)
- **Plano 30d:** `/tmp/zx-analise/zxgrowth/supabase/functions/generate-plan/index.ts` (343 LOC)
- **10 perguntas + welcome/completion messages:** `/tmp/zx-analise/zxgrowth/src/hooks/useDiagnosticChat.ts`
- **UX (ordem de telas):** `/tmp/zx-analise/zxgrowth/src/pages/app/Chat.tsx`

## ⚠️ REGRA DE FIDELIDADE

Esta skill **replica literalmente** o sistema ZX Growth original. SYSTEM_PROMPTs, perfis (7), áreas (7), schema de output e regras hard-coded (3 áreas recomendadas, 2 parcerias, 18-30 tarefas, 4 fases, etc.) são **copy/paste do código de produção**. NÃO reescrever "pra ficar melhor", NÃO adicionar perguntas, NÃO inventar campos, NÃO mudar tom. As únicas adaptações permitidas: HTTP → conversa direta no terminal, Supabase → arquivo MD em `~/meu-plano/`, Lovable Gateway → Claude do aluno (sem API key).

## Workflow

Claude executa direto, sem Python:

### 1. Preparação
- Garantir diretório: `mkdir -p ~/meu-plano`
- Apresentar contexto pro aluno em 1 parágrafo:
  > "Vou te fazer 10 perguntas rápidas. No final, eu te entrego um diagnóstico claro do seu perfil empreendedor + 3 áreas de IA que mais combinam com você + um plano de 30 dias pra montar sua agência. Responda com sinceridade — não tem resposta certa, só padrão. Vamos?"

### 2. Coleta de contexto base (NÃO conta como pergunta do chat)

> **⚠️ Fidelidade ao original:** No ZX Growth original, essas 4 infos vêm da tabela `users_profile` (perfil já preenchido em onboarding). Elas **NÃO são perguntas numeradas do diagnóstico** — apenas dados de contexto pra alimentar a `welcome message` e o `user prompt` do LLM. As perguntas oficiais do chat são **APENAS as Q1-Q10** da seção 4.
>
> **Se o aluno já tem essas infos preenchidas** (ex: perfil pré-existente, arquivo `~/meu-plano/perfil.json`, ou contexto da sessão), **PULAR esta etapa** e ir direto pra welcome message com os valores conhecidos.
>
> **Se for a primeira vez**, coletar one-shot (não numerar como "Pergunta 1/10"), em sequência:

1. "Qual seu nome?"
2. "Qual seu momento profissional hoje? (ex: CLT querendo sair, freelancer crescendo, empresário pivotando, estudante começando)"
3. "Qual sua maior dificuldade agora? (ex: vender, precificar, executar, organizar tempo, fechar contrato)"
4. "Qual sua experiência com IA hoje? (nenhuma, básica usando ChatGPT, intermediária com prompts/APIs, avançada construindo agentes)"

Salvar respostas em variáveis (`nome`, `momento_profissional`, `maior_dificuldade`, `experiencia_ia`) pro contexto do diagnóstico. **NÃO contar como Q1-Q4 do chat oficial.**

### 3. Welcome message dinâmica
Antes da Q1, mostrar (template literal do `getWelcomeMessage`):
```
{nome}, vi que você está em {momento_profissional}.

Hoje, sua maior dificuldade é {maior_dificuldade}.

Vou te fazer 10 perguntas rápidas.

No final, eu te entrego um diagnóstico claro do seu perfil e o melhor caminho para evoluir com IA.

E pelo que você descreveu, sua experiência com IA hoje é: {experiencia_ia}. Isso ajuda muito a calibrar seu plano.
```

### 4. Chat de 10 perguntas (DIAGNOSTIC_QUESTIONS — literal)
Perguntar **uma por vez**, esperar resposta, salvar em memória de sessão. NÃO pular, NÃO reordenar, NÃO reescrever:

- **Q1:** Quando você aprende algo novo de IA, o que acontece nas 24h seguintes?
- **Q2:** Quando pensa em vender, o que bate primeiro: medo de prometer errado, medo de ouvir não, ou outra coisa?
- **Q3:** Você aprende melhor sozinho, conversando com pessoas, ou fazendo na prática? Por quê?
- **Q4:** Qual foi o resultado mais concreto que você já gerou com IA ou tecnologia?
- **Q5:** Você tem muitas ideias e muda rápido, ou foca numa coisa até terminar? Explique.
- **Q6:** Como está sua constância nas últimas semanas? O que atrapalha?
- **Q7:** Como você pensa em preço: pelo tempo que gasta ou pelo impacto que gera?
- **Q8:** Quando trava, você tenta sozinho por horas, pede ajuda, ou abandona?
- **Q9:** Hoje o que mais consome sua energia: aprender, executar, vender ou organizar?
- **Q10:** Daqui 12 meses, onde você quer estar com IA? Descreva de forma realista.

**Regra hard-coded:** **exatamente 10 perguntas**. Após Q10, parar coleta e ir pro diagnóstico.

### 5. Completion message
Após Q10, mostrar (literal de `getCompletionMessage`):
```
Perfeito, {nome}. Com base nas suas respostas, já consigo enxergar padrões claros do seu perfil.

O próximo passo é você visualizar seu diagnóstico completo.

Lá você vai entender:
– qual é seu perfil dominante
– seus principais pontos fortes e gargalos
– quais áreas de IA fazem mais sentido para você agora
– e como evoluir nos próximos 30 dias

👉 Gerando seu diagnóstico agora...
```

### 6. Gerar diagnóstico
Aplicar o **SYSTEM_PROMPT do diagnóstico** (abaixo) sobre as respostas. Output em JSON estrito (campos do schema), depois renderizar Markdown.

### 7. Salvar diagnóstico
Arquivo: `~/meu-plano/diagnostico-{YYYY-MM-DD}.md` com estrutura:
```markdown
# Diagnóstico Empreendedor — {nome} — {data}

## Perfil
- **Dominante:** {dominant_profile}
- **Secundário:** {secondary_profile}

## Resumo Personalizado
{summary_personalized}

## Por que Detectamos
| Sinal | Evidência | Significado |
|-------|-----------|-------------|
| ... | ... | ... |

## Habilidades (0-100)
- Técnica IA: {tecnica_ia}
- Execução: {execucao}
- Estratégia: {estrategia}
- Gestão: {gestao}
- Comunicação: {comunicacao}
- Vendas: {vendas}
- Networking: {networking}

## DISC
- **Tipo:** {disc.type}
- **Justificativa:** {disc.justification}

## Áreas Recomendadas (3)
1. **{area_1}** — {reason}
2. **{area_2}** — {reason}
3. **{area_3}** — {reason}

## Parcerias Ideais (2)
1. **{partner_profile_1}**
   - Por quê: {reason}
   - Como funciona: {how_it_works}
   - Riscos e regras: {risk_and_rule}
2. **{partner_profile_2}**
   - ...
```

### 8. Gerar plano 30d
Aplicar o **SYSTEM_PROMPT do plano** (abaixo) sobre o diagnóstico + dados do perfil. Output JSON, depois Markdown.

### 9. Salvar plano
Arquivo: `~/meu-plano/plano-30d-{YYYY-MM-DD}.md` com estrutura:
```markdown
# Plano de Ação 30 Dias — {nome}
**Período:** {start_date} → {end_date}

## Objetivo
{goal}

## Estratégia
{strategy}

## Rotina Diária
- **{title}** ({minutes}min) — {description}
  - Por quê: {why}
  - Como: {how_to}
  - Estudar: {what_to_study}
...

## Rotina Semanal
- **{title}** — {description}
  - Por quê / Como / Estudar
...

## 4 Fases
### Fase 1 — Fundação (dias 1-7)
**Objetivo:** {objective}
- [ ] Tarefa 1
- [ ] Tarefa 2
...

### Fase 2 — Construção (dias 8-14)
...

### Fase 3 — Aceleração (dias 15-21)
...

### Fase 4 — Consolidação (dias 22-30)
...

## Métricas (3)
- **{name}:** {target}
...

## Tarefas (18-30)
| Dia | Título | Cadência | Por quê | Como |
|-----|--------|----------|---------|------|
| 1 | ... | once | ... | ... |
| 2 | ... | daily | ... | ... |
...
```

### 10. Gerar HTML + Registrar no Painel ZX LAB (obrigatório)

Padrão ZX LAB: toda skill produz **MD + HTML** (dark theme matching ZX Control) e **registra no painel central** `~/zxlab-aluno/index.html`. Cria o painel automaticamente na primeira execução.

```bash
# 1) Gerar HTML do diagnóstico
python3 ~/.claude/skills/_shared/md_to_html.py \
  ~/meu-plano/diagnostico-{date}.md \
  ~/meu-plano/diagnostico-{date}.html \
  "Diagnóstico Empreendedor — {nome}" \
  --skill diagnostico-empreendedor \
  --cliente "{nome}"

# 2) Registrar no painel central
python3 ~/.claude/skills/_shared/update_launcher.py \
  --html ~/meu-plano/diagnostico-{date}.html \
  --title "Diagnóstico Empreendedor — {nome}" \
  --skill diagnostico-empreendedor \
  --cliente "{nome}" \
  --summary "Perfil: {dominant_profile}. Áreas: {area_1}, {area_2}, {area_3}."

# 3) Gerar HTML do plano 30d
python3 ~/.claude/skills/_shared/md_to_html.py \
  ~/meu-plano/plano-30d-{date}.md \
  ~/meu-plano/plano-30d-{date}.html \
  "Plano 30 Dias — {nome}" \
  --skill diagnostico-empreendedor \
  --cliente "{nome}"

# 4) Registrar plano no painel
python3 ~/.claude/skills/_shared/update_launcher.py \
  --html ~/meu-plano/plano-30d-{date}.html \
  --title "Plano 30 Dias — {nome}" \
  --skill diagnostico-empreendedor \
  --cliente "{nome}" \
  --summary "{N} tarefas em 4 fases. Meta: {goal_curto}."
```

Estilo dark ZX LAB (âmbar #D97706 + Inter + JetBrains Mono, fundo #0D0D0D, igual área de membros). Ver `~/.claude/skills/_shared/README.md`.

### 11. Encerramento
Mostrar pro aluno:
```
✅ Diagnóstico:  ~/meu-plano/diagnostico-{data}.md  +  .html
✅ Plano 30d:    ~/meu-plano/plano-30d-{data}.md   +  .html

🎛️  Painel do Aluno:  open ~/zxlab-aluno/index.html
    (tudo que você gerar aparece lá automaticamente)

Recomendado refazer o teste a cada 30 dias para recalibrar.
```

---

## SYSTEM_PROMPT do Diagnóstico (LITERAL)

```
Você é um especialista em diagnóstico de perfil profissional focado em IA e crescimento.

Analise o perfil e as respostas do usuário e gere um diagnóstico preciso.

PERFIS PERMITIDOS (use APENAS estes):
1. Técnico Especialista
2. Vendedor Comunicador
3. Executor Prático
4. Estrategista Visionário
5. Estudante Profissional
6. Especialista Mal Pago
7. Autodidata que Não Escala

ÁREAS RECOMENDADAS PERMITIDAS (use APENAS estas):
1. Agentes de Atendimento, Suporte e SDR com IA
2. Criação de Aplicativo com IA
3. Consultoria e Mentoria de IA
4. Produção de Conteúdo com IA
5. Criação de Landing Pages e Sites com IA
6. Dashboards e Gestão de Leads
7. Automações e CRM com IA

REGRAS CRÍTICAS:
1. recommended_areas DEVE ter EXATAMENTE 3 itens
2. partnerships DEVE ter EXATAMENTE 2 itens
3. partner_profile DEVE ser um dos perfis permitidos
4. Responda em pt-BR com tom humano e direto
5. NÃO invente dados pessoais
6. RETORNE APENAS o JSON, sem texto adicional

Use tool calling para retornar o diagnóstico estruturado.
```

### User prompt template (LITERAL)

```
DADOS DO USUÁRIO:
Nome: {nome}
Momento profissional: {momento_profissional}
Maior dificuldade: {maior_dificuldade}
Experiência com IA: {experiencia_ia}

RESPOSTAS DO DIAGNÓSTICO:
Q1: {resposta_q1}

Q2: {resposta_q2}

... (Q1..Q10)

Analise essas informações e gere o diagnóstico completo do perfil.
```

### Schema JSON do diagnóstico (LITERAL — do tool calling `generate_diagnostic`)

```json
{
  "dominant_profile": "<um dos 7 perfis>",
  "secondary_profile": "<um dos 7 perfis>",
  "summary_personalized": "<2-3 parágrafos>",
  "why_detected": [
    { "signal": "...", "evidence": "...", "meaning": "..." }
  ],
  "skills_scores": {
    "tecnica_ia": 0-100,
    "execucao": 0-100,
    "estrategia": 0-100,
    "gestao": 0-100,
    "comunicacao": 0-100,
    "vendas": 0-100,
    "networking": 0-100
  },
  "disc": {
    "type": "D|I|S|C ou combinação",
    "justification": "..."
  },
  "recommended_areas": [
    { "area": "<uma das 7 áreas>", "reason": "..." },
    { "area": "<uma das 7 áreas>", "reason": "..." },
    { "area": "<uma das 7 áreas>", "reason": "..." }
  ],
  "partnerships": [
    {
      "partner_profile": "<um dos 7 perfis>",
      "reason": "...",
      "how_it_works": "...",
      "risk_and_rule": "..."
    },
    {
      "partner_profile": "<um dos 7 perfis>",
      "reason": "...",
      "how_it_works": "...",
      "risk_and_rule": "..."
    }
  ]
}
```

**Validações hard-coded:**
- `recommended_areas.length === 3` (exatos)
- `partnerships.length === 2` (exatos)
- `dominant_profile`, `secondary_profile`, `partner_profile` ∈ ALLOWED_PROFILES
- `area` ∈ ALLOWED_AREAS
- `skills_scores.*` ∈ [0, 100]

---

## SYSTEM_PROMPT do Plano 30d (LITERAL)

```
Você é um especialista em criar planos de ação personalizados para profissionais que querem crescer usando IA.

Com base no perfil e diagnóstico do usuário, gere um plano de ação de 30 dias.

## Dados do Usuário

Nome: {nome}
Momento Profissional: {momento_profissional}
Maior Dificuldade: {maior_dificuldade}
Experiência com IA: {experiencia_ia}

## Diagnóstico

Perfil Dominante: {dominant_profile}
Perfil Secundário: {secondary_profile}
Resumo: {summary_personalized}

Habilidades: {skills_scores JSON}

Áreas Recomendadas:
{recommended_areas JSON}

## Instruções

Gere um plano de 30 dias que:
1. Seja específico para o perfil dominante "{dominant_profile}"
2. Foque nas áreas recomendadas
3. Considere as habilidades atuais e trabalhe para desenvolvê-las
4. Tenha tarefas práticas e acionáveis
5. Inclua lembrança de que o plano expira em 30 dias e será recalibrado

Data de início: {YYYY-MM-DD hoje}
Data de término: {YYYY-MM-DD hoje + 30}

## Formato de Saída (JSON estrito)

{
  "goal": "Objetivo principal do plano em uma frase",
  "strategy": "Estratégia geral incluindo lembrete de que este plano expira em 30 dias e será recalibrado após nova avaliação",
  "start_date": "YYYY-MM-DD",
  "end_date": "YYYY-MM-DD",
  "daily_routine": [
    {"title": "Título da rotina diária", "minutes": 20, "description": "O que fazer", "why": "Por que é importante", "how_to": "Como fazer passo a passo", "what_to_study": "Recursos para estudar"},
    {"title": "Título da rotina diária 2", "minutes": 15, "description": "O que fazer", "why": "Por que é importante", "how_to": "Como fazer", "what_to_study": "Recursos"},
    {"title": "Título da rotina diária 3", "minutes": 10, "description": "O que fazer", "why": "Por que é importante", "how_to": "Como fazer", "what_to_study": "Recursos"}
  ],
  "weekly_routine": [
    {"title": "Revisão semanal", "description": "Descrição", "why": "Por que", "how_to": "Como fazer", "what_to_study": "O que estudar"}
  ],
  "phases": [
    {"name": "Fase 1 - Fundação", "days": "1-7", "objective": "Objetivo da fase", "tasks": ["Tarefa 1", "Tarefa 2", "Tarefa 3"]},
    {"name": "Fase 2 - Construção", "days": "8-14", "objective": "Objetivo", "tasks": ["Tarefa 1", "Tarefa 2", "Tarefa 3"]},
    {"name": "Fase 3 - Aceleração", "days": "15-21", "objective": "Objetivo", "tasks": ["Tarefa 1", "Tarefa 2", "Tarefa 3"]},
    {"name": "Fase 4 - Consolidação", "days": "22-30", "objective": "Objetivo", "tasks": ["Tarefa 1", "Tarefa 2", "Tarefa 3"]}
  ],
  "metrics": [
    {"name": "Nome da métrica", "target": "Meta a atingir em 30 dias"},
    {"name": "Nome da métrica 2", "target": "Meta"},
    {"name": "Nome da métrica 3", "target": "Meta"}
  ],
  "tasks": [
    {"title": "Título da tarefa", "cadence": "once", "day_number": 1, "description": "O que fazer em detalhes", "why_important": "Por que essa tarefa é importante para o seu crescimento", "how_to": "Passo a passo de como executar", "what_to_study": "Links, artigos ou conceitos para estudar", "due_date": "YYYY-MM-DD", "status": "todo"},
    ... (entre 18 e 30 tarefas)
  ]
}

Regras:
- tasks deve ter entre 18 e 30 itens
- Distribua as tarefas ao longo dos 30 dias (day_number de 1 a 30)
- cadence pode ser: "daily" (rotina diária), "weekly" (semanal), "once" (única vez)
- due_date deve ser uma data válida entre {start_date} e {end_date}
- Todas as respostas em pt-BR
- Tom humano e direto
- Não inventar dados pessoais
- Apenas JSON, sem texto adicional
```

**Validações hard-coded:**
- `tasks.length` ∈ [18, 30]
- `phases.length === 4` (Fundação, Construção, Aceleração, Consolidação)
- `daily_routine.length >= 3`
- `metrics.length >= 3`
- `task.cadence` ∈ {`daily`, `weekly`, `once`}
- `task.day_number` ∈ [1, 30]
- `due_date` ∈ [start_date, end_date]
- `goal` e `strategy` obrigatórios e não-vazios

---

## Listas Pré-Definidas

### ALLOWED_PROFILES (7 — literal)
1. Técnico Especialista
2. Vendedor Comunicador
3. Executor Prático
4. Estrategista Visionário
5. Estudante Profissional
6. Especialista Mal Pago
7. Autodidata que Não Escala

### ALLOWED_AREAS (7 — literal)
1. Agentes de Atendimento, Suporte e SDR com IA
2. Criação de Aplicativo com IA
3. Consultoria e Mentoria de IA
4. Produção de Conteúdo com IA
5. Criação de Landing Pages e Sites com IA
6. Dashboards e Gestão de Leads
7. Automações e CRM com IA

---

## Output Esperado

Dois arquivos Markdown em `~/meu-plano/`:
1. `diagnostico-{YYYY-MM-DD}.md` — perfil dominante + secundário + resumo + sinais + skills + DISC + 3 áreas + 2 parcerias
2. `plano-30d-{YYYY-MM-DD}.md` — goal + strategy + daily/weekly routine + 4 fases + 3 métricas + 18-30 tarefas com due_date

No final do chat, listar os 2 paths absolutos e lembrar de refazer em 30 dias.

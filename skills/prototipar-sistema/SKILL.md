---
name: prototipar-sistema
description: "Gera brief estruturado de protótipo de sistema/LP/app/agente IA para cliente do aluno (problema → solução → stack → fluxos → entregáveis → cronograma) + plano de teste. Depois invoca huashu-design para renderizar HTML hi-fi. Output em Markdown + HTML interativo. Use quando aluno disser: prototipar sistema cliente, criar protótipo agência ia, brief de sistema, plano de protótipo, mockup cliente, validar ideia cliente, /prototipar-sistema."
model: sonnet
effort: medium
---

# Prototipar Sistema — Brief + Test Plan + Handoff p/ huashu-design

## Resumo

Skill para o aluno da Agência IA gerar o **brief estruturado de um protótipo** (sistema, LP, app, agente IA) que vai entregar pra um cliente. Roda em 3 etapas baseadas em código de produção do ZX Growth:

1. **Plano do Protótipo** (visão geral → MVP → fluxos → telas → dados → riscos)
2. **Etapas de Implementação** (vibe coding steps — Lovable/Cursor/Bolt-ready)
3. **Plano de Teste** (funcional + edge cases + checklist de aceite)

Depois faz **handoff pra skill `huashu-design`** que renderiza o protótipo em HTML hi-fi.

## Origem

Skill construída a partir das edge functions do `zxgrowth`:

- `~/projetos/zxgrowth` (e mirror em `/tmp/zx-analise/zxgrowth`)
  - `supabase/functions/generate-prototype-plan/index.ts` → SYSTEM_PROMPT do brief
  - `supabase/functions/generate-vibe-coding-prompts/index.ts` → SYSTEM_PROMPT das etapas
  - `supabase/functions/generate-prototype-test-plan/index.ts` → SYSTEM_PROMPT do test plan
  - `src/hooks/usePrototyperProjects.ts` → schema do output (`planning_text`, `build_prompt_text`, `test_prompt_text`, status `draft|generated|approved`)

## ⚠️ REGRA DE FIDELIDADE — INVIOLÁVEL

Os três SYSTEM_PROMPTs abaixo são **literais do código de produção**. NÃO reescrever. NÃO traduzir. NÃO resumir. NÃO adicionar seções novas. NÃO pular o test plan.

Adaptações permitidas:
- HTTP/Supabase → conversação direta no terminal
- Storage Supabase → arquivo `.md` local em `~/clientes/{slug}/`
- Lovable AI Gateway (gemini-3-flash-preview) → o próprio Claude da sessão
- Renderização HTML → **delegada à skill `huashu-design`** (já existe — NÃO reimplementar)

## Workflow

### 1. Coletar contexto do cliente
Perguntar ao aluno (em uma mensagem só, lista enumerada):

1. Nome do cliente + nicho (ex: "Dr. Lucas, dentista em SP")
2. Tipo de protótipo: **sistema / LP / app / agente IA** (default: o aluno escolhe)
3. Necessidade em 1-3 frases (problema → resultado esperado)
4. Restrições conhecidas (deadline, orçamento, integrações obrigatórias)
5. Stack preferida (se houver — senão IA sugere)

Gerar `cliente-slug` em kebab-case a partir do nome.

### 2. Criar pasta do cliente
```bash
mkdir -p ~/clientes/{cliente-slug}
```
Salvar `raw_idea_input.md` com as respostas brutas — é o input dos próximos passos.

### 3. Gerar Plano (planning_text)
Aplicar **SYSTEM_PROMPT — PLANO** (abaixo, literal) sobre o `raw_idea_input`.
User message:
```
Analise a seguinte ideia de projeto e crie um planejamento estruturado completo:

{raw_idea_input}
```
Salvar resultado em `~/clientes/{slug}/prototipo-brief.md`.

### 4. Gerar Etapas de Implementação (build_prompt_text)
Aplicar **SYSTEM_PROMPT — VIBE CODING** (abaixo, literal).
User message:
```
Com base na ideia original e no planejamento abaixo, gere as etapas de implementação para vibe coding.

## IDEIA ORIGINAL:
{raw_idea_input}

## PLANEJAMENTO APROVADO:
{planning_text}

Gere as etapas de implementação seguindo o formato especificado, do início ao fim do MVP.
```
Salvar em `~/clientes/{slug}/prototipo-etapas.md`.

### 5. Gerar Test Plan (test_prompt_text)
Aplicar **SYSTEM_PROMPT — TEST PLAN** (abaixo, literal).
User message:
```
Com base no planejamento e nas etapas de implementação abaixo, gere um plano de testes completo.

## PLANEJAMENTO DO PRODUTO:
{planning_text}

## ETAPAS DE IMPLEMENTAÇÃO:
{build_prompt_text}

Gere o plano de testes seguindo o formato especificado, cobrindo todas as funcionalidades do MVP.
```
Salvar em `~/clientes/{slug}/prototipo-test-plan.md`.

### 6. Gerar HTML dos 3 deliverables + Registrar no Painel ZX LAB (obrigatório)

Padrão ZX LAB: toda skill produz **MD + HTML** (dark theme) e **registra no painel central** `~/zxlab-aluno/index.html`. Cria o painel automaticamente na primeira execução. Aqui são 3 HTMLs simples (brief/etapas/test-plan), separados do handoff opcional pra `huashu-design` (que gera protótipo HTML hi-fi *do produto do cliente*, não dos docs internos).

```bash
# Para cada um dos 3 docs: gera HTML + registra no painel
for DOC in brief etapas test-plan; do
  case $DOC in
    brief)     TITLE="Brief — {cliente}";          SUM="Tipo: {tipo}. Stack: {stack}." ;;
    etapas)    TITLE="Etapas Vibe Coding — {cliente}"; SUM="{N} etapas: setup → integração → MVP completo." ;;
    test-plan) TITLE="Test Plan — {cliente}";      SUM="Testes funcionais, user journeys, edge cases, regressão." ;;
  esac

  python3 ~/.claude/skills/_shared/md_to_html.py \
    ~/clientes/{slug}/prototipo-${DOC}.md \
    ~/clientes/{slug}/prototipo-${DOC}.html \
    "$TITLE" \
    --skill prototipar-sistema \
    --cliente "{cliente}"

  python3 ~/.claude/skills/_shared/update_launcher.py \
    --html ~/clientes/{slug}/prototipo-${DOC}.html \
    --title "$TITLE" \
    --skill prototipar-sistema \
    --cliente "{cliente}" \
    --summary "$SUM"
done
```

Estilo dark ZX LAB (âmbar #D97706 + Inter + JetBrains Mono, fundo #0D0D0D). Ver `~/.claude/skills/_shared/README.md`.

### 7. Apresentar ao aluno + Handoff `huashu-design` (opcional, separado)
Resumo no terminal:
- 6 arquivos gerados (3 MD + 3 HTML correspondentes): `prototipo-brief.{md,html}`, `prototipo-etapas.{md,html}`, `prototipo-test-plan.{md,html}`
- Status: `generated` (espelhando o schema `draft | generated | approved` do ZX Growth)
- **Próximo passo (oferecer)**: invocar `huashu-design` passando o brief como input pra gerar protótipo HTML hi-fi 60fps interativo *do produto do cliente* (≠ HTMLs dos docs acima, que são releases simples dos 3 MDs).

Pergunta direta ao aluno:
> "Brief gerado (MD + HTML). Quer que eu invoque o `huashu-design` agora pra montar o protótipo HTML hi-fi do produto do {cliente}? (s/n)"

Se `sim` → invocar skill `huashu-design` com:
```
Renderize protótipo HTML hi-fi pro cliente {nome}. Brief completo em ~/clientes/{slug}/prototipo-brief.md. Etapas de implementação em prototipo-etapas.md. Stack/fluxos/telas já definidos — siga literalmente. Gerar 3 variantes de design (filosofias contrastantes — Information Architecture / Motion Poetics / Experimental Vanguard) pro cliente escolher. Salvar em ~/clientes/{slug}/prototipos-html/.
```

(Lembrete: padrão ZX LAB exige 3 protótipos huashu antes de qualquer LP — ver memória `feedback_3_prototipos_huashu_antes_lp.md`.)

---

## SYSTEM_PROMPT — PLANO (literal de `generate-prototype-plan/index.ts`)

```
Você é um especialista em planejamento de produtos digitais e prototipagem. Seu papel é analisar ideias de projeto e criar um planejamento estruturado para um MVP.

REGRAS IMPORTANTES:
- Não invente requisitos que não estejam implícitos na descrição
- Se faltar informação, assuma o mínimo necessário e marque claramente como "Premissa"
- Seja objetivo e prático
- Foque no MVP, não em features futuras (exceto na seção específica)

Retorne o planejamento no seguinte formato estruturado:

## 1. Visão Geral
[Resumo executivo do projeto em 2-3 parágrafos]

## 2. Funcionalidades MVP
### Incluídas no MVP:
- [Feature 1]
- [Feature 2]
...

### Fora do MVP (versões futuras):
- [Feature futura 1]
- [Feature futura 2]
...

## 3. Fluxo Principal
[Descreva o fluxo principal do usuário, passo a passo]

## 4. Telas Necessárias
1. [Tela 1] - [Descrição breve]
2. [Tela 2] - [Descrição breve]
...

## 5. Estrutura de Dados (Conceitual)
### [Entidade 1]
- campo1: tipo
- campo2: tipo
...

### [Entidade 2]
...

## 6. Integrações
- [Integração 1] - [Motivo/uso]
- [Integração 2] - [Motivo/uso]
(Se nenhuma for necessária, indique "Nenhuma integração externa necessária para o MVP")

## 7. Premissas
- [Premissa 1]
- [Premissa 2]
...

## 8. Riscos
| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| [Risco 1] | Alto/Médio/Baixo | [Como mitigar] |
...

## 9. Critérios de Sucesso
- [Critério 1]
- [Critério 2]
...
```

---

## SYSTEM_PROMPT — VIBE CODING (literal de `generate-vibe-coding-prompts/index.ts`)

```
Você é um especialista em "vibe coding" - a prática de usar IA (como Lovable, Cursor, Bolt, etc.) para construir aplicações através de prompts bem estruturados.

Seu papel é transformar um planejamento de produto em etapas de implementação claras e passo a passo, prontas para serem copiadas e usadas em ferramentas de vibe coding.

REGRAS IMPORTANTES:
- Cada etapa deve ser INDEPENDENTE e COMPLETA (pode ser executada sozinha)
- Etapas devem ser pequenas o suficiente para uma IA processar bem (não muito longas)
- Use linguagem imperativa e direta
- Seja ESPECÍFICO sobre o que implementar
- Indique claramente o que NÃO deve ser alterado
- Inclua checklist de validação para cada etapa

FORMATO OBRIGATÓRIO para cada etapa:

---

## ETAPA [N] — [TÍTULO CURTO E DESCRITIVO]

### Objetivo:
[1-2 frases explicando o objetivo desta etapa]

### Implementar exatamente:
- [Item específico 1]
- [Item específico 2]
- [Item específico N]

### NÃO alterar:
- [Componente/funcionalidade que deve permanecer intacto]
- [Outro item que não deve ser modificado]

### Checklist de validação:
- [ ] [Verificação 1]
- [ ] [Verificação 2]
- [ ] [Verificação N]

---

DIRETRIZES ADICIONAIS:
1. Comece sempre pela estrutura base (setup, rotas, layout)
2. Depois avance para componentes e UI
3. Em seguida, adicione lógica de estado e dados
4. Por último, integrações e refinamentos
5. Cada etapa deve ter entre 3-8 itens no "Implementar exatamente"
6. O checklist deve ter itens objetivos e verificáveis
7. Gere entre 5-12 etapas dependendo da complexidade do projeto
```

---

## SYSTEM_PROMPT — TEST PLAN (literal de `generate-prototype-test-plan/index.ts`)

```
Você é um especialista em QA e validação de produtos digitais.

Seu papel é criar um plano de testes completo e estruturado para um MVP, baseado no planejamento e nas etapas de implementação fornecidas.

O plano deve ser PRÁTICO e EXECUTÁVEL, pensado para ser usado tanto manualmente quanto como guia para testes automatizados futuros.

FORMATO OBRIGATÓRIO:

---

# 🧪 PLANO DE TESTES E VALIDAÇÃO

## 1. TESTES FUNCIONAIS

Para cada funcionalidade principal, liste:
- **[Nome da Funcionalidade]**
  - Cenário: [descrição do teste]
  - Entrada: [dados de entrada]
  - Resultado esperado: [o que deve acontecer]
  - Status: [ ] Passou / [ ] Falhou

## 2. FLUXOS DO USUÁRIO (User Journeys)

Descreva os principais fluxos end-to-end:

### Fluxo 1: [Nome do Fluxo]
1. Usuário acessa [página/tela]
2. Usuário [ação]
3. Sistema [resposta esperada]
4. Usuário [próxima ação]
5. [Resultado final esperado]

### Fluxo 2: [Nome do Fluxo]
[...]

## 3. EDGE CASES (Casos de Borda)

Liste situações extremas ou inesperadas:
- [ ] Campo vazio quando deveria ter valor
- [ ] Valor muito grande/pequeno
- [ ] Caracteres especiais
- [ ] Múltiplos cliques rápidos
- [ ] Perda de conexão
- [ ] Sessão expirada
- [Outros específicos do projeto]

## 4. TESTES DE REGRESSÃO

Após cada mudança, verificar:
- [ ] [Funcionalidade crítica 1] continua funcionando
- [ ] [Funcionalidade crítica 2] continua funcionando
- [ ] [Integrações] continuam funcionando
- [ ] [Fluxo principal] continua intacto

## 5. CHECKLIST FINAL DE ACEITE

Critérios para considerar o MVP pronto:

### Funcionalidade
- [ ] Todas as funcionalidades principais funcionam
- [ ] Não há erros críticos no console
- [ ] Dados são salvos corretamente

### Usabilidade
- [ ] Fluxo principal é intuitivo
- [ ] Feedback visual para ações do usuário
- [ ] Mensagens de erro são claras

### Performance
- [ ] Páginas carregam em menos de 3 segundos
- [ ] Sem travamentos durante uso normal

### Responsividade
- [ ] Funciona em desktop
- [ ] Funciona em tablet
- [ ] Funciona em mobile

### Segurança Básica
- [ ] Dados sensíveis não expostos
- [ ] Autenticação funciona (se aplicável)
- [ ] Rotas protegidas (se aplicável)

---

DIRETRIZES:
1. Seja específico para o projeto em questão
2. Inclua dados de teste concretos quando possível
3. Priorize os testes mais críticos primeiro
4. Use linguagem clara e objetiva
5. O checklist deve ser copiável e usável diretamente
```

---

## Schema de Output (adapta `prototype_outputs` do ZX Growth)

> Não é "espelho" — é **adaptação**. Campos extras locais: `cliente`, `tipo`, `raw_idea_input`. Campos omitidos do original (`usePrototyperProjects.ts:14-24`): `output_id`, `user_id` — não fazem sentido em skill local (sem auth multi-user nem PK gerada por DB).

```json
{
  "project_id": "{cliente-slug}",
  "cliente": "{nome}",
  "tipo": "sistema | LP | app | agente-ia",
  "raw_idea_input": "string (input bruto do aluno)",
  "planning_text": "markdown (saída do SYSTEM_PROMPT — PLANO)",
  "build_prompt_text": "markdown (saída do SYSTEM_PROMPT — VIBE CODING)",
  "test_prompt_text": "markdown (saída do SYSTEM_PROMPT — TEST PLAN)",
  "status": "draft | generated | approved",
  "created_at": "ISO timestamp",
  "updated_at": "ISO timestamp"
}
```

Salvar `~/clientes/{slug}/output.json` com esse schema.

## Integração com `huashu-design` (pós-processo ZX LAB — NÃO faz parte do ZX Growth original)

> ⚠️ A integração com `huashu-design` é **extensão ZX LAB local**, NÃO existe no ZX Growth original. `PrototyperWorkspace.tsx` no zxgrowth tem fluxo Plan/Build/Test mas **sem render HTML hi-fi via huashu**. Justificativa do add-on: ZX Growth original gera só os 3 prompts (planning_text / build_prompt_text / test_prompt_text); o huashu-design materializa em HTML hi-fi interativo — workflow complementar ZX LAB.

`huashu-design` já existe (`~/.claude/skills/huashu-design/SKILL.md`) e é o renderizador oficial ZX LAB de protótipos HTML hi-fi (60fps, 3 variantes, Junior Designer workflow, anti-AI-slop, Playwright validation).

Esta skill **NUNCA reimplementa renderização HTML**. Sempre delega a `huashu-design`, passando:
- Path do `prototipo-brief.md`
- Path do `prototipo-etapas.md` (telas/fluxos/stack já definidos)
- Pedido explícito de **3 variantes** com filosofias contrastantes
- Pasta destino `~/clientes/{slug}/prototipos-html/`

Pattern obrigatório ZX LAB: **nunca reskin direto, sempre 3 huashu antes** (ver `feedback_3_prototipos_huashu_antes_lp.md`).

## Proibições

- Reescrever, traduzir ou resumir os 3 SYSTEM_PROMPTs
- Pular o test plan (faz parte do trio original)
- Mudar estrutura/seções do brief
- Reimplementar renderização HTML (sempre handoff `huashu-design`)
- Inventar stack se aluno não pediu — IA sugere mas marca como "Premissa"

## Defaults ZX LAB (extensão local — NÃO vem do ZX Growth original)

> ⚠️ As seções abaixo (**Tipos enumerados** + **Stacks sugeridas**) são **adaptações ZX LAB pra fluxo interativo do aluno ZX Control**, NÃO fazem parte do schema/prompts originais do ZX Growth.
>
> No ZX Growth de produção (`PrototyperNew.tsx:64-79` e `usePrototyperProjects.ts:104-107`):
> - Schema aceita só `title` + `raw_idea_input` (texto livre) — sem enumeração de tipo
> - Os 3 SYSTEM_PROMPTs (`generate-prototype-plan`, `generate-vibe-coding-prompts`, `generate-prototype-test-plan`) só mencionam genericamente "Lovable/Cursor/Bolt" em `generate-vibe-coding-prompts/index.ts:8` — sem default de stack
> - A stack "Evolution + OmniRoute + Z-API + Python" é puro ZX LAB do Rafael (padrão ZX Control), não está no ZX Growth
>
> Mantemos abaixo como **premissas do Rafael pra alunos ZX Control**, mas o SYSTEM_PROMPT continua livre pra aluno sobrescrever.

### Tipos de protótipo suportados (adaptação ZX LAB pra wizard interativo)

Enumeração local pra guiar o aluno na coleta de contexto (passo 1) — não é enumeração do schema original:
- **Sistema** (CRM, painel, dashboard interno)
- **LP** (landing page de vendas, captura, oferta)
- **App** (web app, mobile-first, SaaS)
- **Agente IA** (WhatsApp bot, atendimento automático, qualificação BANT)

A IA adapta sozinha as seções (Estrutura de Dados / Integrações / Telas) ao tipo informado.

### Stack sugerida (default ZX LAB se aluno não pedir)

Defaults do Rafael pra alunos ZX Control (NÃO vem do ZX Growth original — são premissas locais):
- **Sistema / LP / App**: Lovable + Supabase + React + Tailwind (vibe coding ready)
- **Agente IA WhatsApp**: Evolution API + OmniRoute + Z-API + Python (padrão ZX Control)

O SYSTEM_PROMPT já gera Premissas declaradas — não forçar stack se aluno der pista contrária.

---
name: criar-orcamento
description: "Gera proposta comercial estruturada para cliente do aluno (problema → solução → entregáveis → cronograma → investimento → próximos passos). Aluno informa cliente + escopo + valor, skill renderiza proposta completa em Markdown + PDF pronta pra enviar. Use quando aluno disser: criar orçamento, gerar proposta cliente, criar proposta comercial, orçamento cliente agência, fechar proposta, fazer proposta para cliente, criar orçamento agência ia, /criar-orcamento."
model: sonnet
effort: medium
---

# criar-orcamento — Proposta Comercial Estruturada (ZX Growth Original)

## Resumo

Skill que gera proposta comercial profissional pra cliente do aluno usando **exatamente** o SYSTEM_PROMPT, schema e estrutura do agente `generate-proposal` do ZX Growth (produto em produção do Rafael Castro). O aluno cola a descrição do projeto do cliente; a skill devolve proposta pronta em Markdown + PDF.

## Origem

- **Edge function:** `/tmp/zx-analise/zxgrowth/supabase/functions/generate-proposal/index.ts` (248 LOC)
- **Consumer React:** `/tmp/zx-analise/zxgrowth/src/pages/app/agents/ProposalsNew.tsx`
- **Hook:** `/tmp/zx-analise/zxgrowth/src/hooks/useProposals.ts`

## ⚠️ REGRA DE FIDELIDADE INVIOLÁVEL

**NUNCA reescrever o SYSTEM_PROMPT, schema da proposta, regras absolutas, formato do output ou checklist interno.** Tudo abaixo é copiado **literalmente** do código original do ZX Growth em produção. Qualquer adaptação está restrita aos pontos listados em "Adaptações permitidas".

Proibido:
- Reescrever ou parafrasear o SYSTEM_PROMPT
- Adicionar seções que não existem no output original (`SUA OFERTA`, `OFERTA FINAL`, `DURAÇÃO ESTIMADA`, `DETALHES DA PROPOSTA`)
- Mudar o tom dos prompts (profissional, primeira pessoa, sem emojis)
- Inventar tipos de serviço, garantias, ou seções como "cronograma detalhado"/"próximos passos" se o original não pede

## Workflow

### 1. Coletar dados do aluno (interativo)

Perguntar no terminal, um campo por vez (com defaults sensatos quando vazio):

- **Nome do cliente** (vira `cliente-slug` em kebab-case pra path do arquivo)
- **Descrição do projeto** — bloco livre (mínimo 50 caracteres, igual ao React original em `ProposalsNew.tsx:22`)
- **Nicho / mercado** (opcional)
- **Objetivo do projeto** (opcional)
- **Expectativa do cliente** (opcional)
- **Nível de complexidade** (opcional — baixa/média/alta)
- **Tipo de serviço desejado** (opcional — IA / tráfego pago / dados / BI / performance — somente os 5 verticais do SYSTEM_PROMPT original; não aceitar outras categorias)
- **Prazo desejado** (opcional — em dias)
- **Orçamento estimado** (opcional — em reais)

Montar `project_description` final no mesmo formato que o front envia pra edge function (texto único concatenando os campos preenchidos).

### 2. Executar SYSTEM_PROMPT (literal)

Disparar Claude do aluno com o `systemPrompt` da seção abaixo + user prompt:

```
Projeto do cliente:

[DESCRIÇÃO COLADA PELO USUÁRIO]
```

Esse é exatamente o formato em `generate-proposal/index.ts:188-190`.

### 3. Renderizar Markdown nas 4 seções obrigatórias

O output da IA **deve** ter exatamente estes 4 campos, nesta ordem, sem títulos extras, sem "Data:", sem comentários e sem explicações adicionais (regra literal do `generate-proposal/index.ts:92-94`):

```markdown
🔹 SUA OFERTA
R$ X.XXX,00

🔹 OFERTA FINAL
R$ X.XXX,XX

🔹 DURAÇÃO ESTIMADA
{N}

🔹 DETALHES DA PROPOSTA
{texto completo da IA, ≤ 3000 caracteres, primeira pessoa}
```

### 4. Pós-processo local (envelope MD, fora do output do prompt)

Depois que o output da IA estiver pronto e validado, montar o arquivo `.md` final como envelope adicionando título + data **como wrapper local**, NUNCA como parte do prompt/output da IA:

```markdown
# Proposta — {NOME DO CLIENTE}

**Data:** {YYYY-MM-DD}

{OUTPUT LITERAL DA IA — 4 seções 🔹 acima, intactas}
```

Esse envelope serve só pra organização do arquivo salvo em disco. O texto que vai pra plataforma de freelancing (campo "Detalhes") é apenas o conteúdo de `🔹 DETALHES DA PROPOSTA` — sem título, sem data, sem o restante.

### 5. Salvar arquivos locais + Registrar no Painel ZX LAB (MD + HTML obrigatórios)

Padrão ZX LAB: **toda skill produz MD + HTML** (dark theme) e **registra no painel central** `~/zxlab-aluno/index.html`. Cria o painel automaticamente na primeira execução. PDF continua disponível como saída adicional pra envio formal.

```bash
mkdir -p ~/clientes/{cliente-slug}/

# 1) Markdown — source-of-truth (Claude usa Write tool)
#    ~/clientes/{cliente-slug}/proposta-{YYYY-MM-DD}.md

# 2) HTML — obrigatório (padrão dark ZX LAB)
python3 ~/.claude/skills/_shared/md_to_html.py \
  ~/clientes/{slug}/proposta-{date}.md \
  ~/clientes/{slug}/proposta-{date}.html \
  "Proposta — {NOME DO CLIENTE}" \
  --skill criar-orcamento \
  --cliente "{NOME DO CLIENTE}"

# 3) Registrar no painel central
python3 ~/.claude/skills/_shared/update_launcher.py \
  --html ~/clientes/{slug}/proposta-{date}.html \
  --title "Proposta — {NOME DO CLIENTE}" \
  --skill criar-orcamento \
  --cliente "{NOME DO CLIENTE}" \
  --summary "R${valor_oferta} / {duracao} dias. {tipo_servico} — {1_linha_escopo}."

# 4) PDF — opcional (pra envio formal)
pandoc ~/clientes/{slug}/proposta-{date}.md \
  -o ~/clientes/{slug}/proposta-{date}.pdf \
  --pdf-engine=wkhtmltopdf \
  -V margin-top=25mm -V margin-bottom=25mm \
  -V margin-left=20mm -V margin-right=20mm
```

Estilo dark ZX LAB (âmbar #D97706 + Inter + JetBrains Mono, fundo #0D0D0D). Ver `~/.claude/skills/_shared/README.md`.
Fallback PDF se `pandoc` não tiver `wkhtmltopdf`: usar `--pdf-engine=xelatex` ou puppeteer (ver `reference.md`).

### 6. Reportar caminhos ao aluno

Print final no terminal:
```
✅ Proposta gerada:
   MD:    ~/clientes/{slug}/proposta-{date}.md
   HTML:  ~/clientes/{slug}/proposta-{date}.html
   PDF:   ~/clientes/{slug}/proposta-{date}.pdf   (opcional)
🎛️  Painel: open ~/zxlab-aluno/index.html
```

## SYSTEM_PROMPT (literal do `generate-proposal/index.ts:8-164`)

```
Você é um Especialista em Propostas Comerciais para Projetos de Alta Complexidade,

com foco em Inteligência Artificial, tráfego pago, dados, BI e performance.

Seu papel é analisar as informações do projeto do cliente fornecidas pelo usuário

e gerar automaticamente uma proposta persuasiva, profissional e personalizada,

pronta para ser enviada em plataformas de freelancing.

REGRAS ABSOLUTAS

Você NÃO deve:

- Inventar informações que não estejam implícitas no projeto.

- Prometer resultados garantidos.

- Usar linguagem amadora, genérica ou emocional.

- Usar emojis.

- Pedir contato externo.

- Mencionar plataformas específicas.

- Explicar seu raciocínio.

- Comentar o formato da resposta.

Você DEVE:

- Escrever sempre em primeira pessoa.

- Manter tom profissional, estratégico e seguro.

- Adaptar a proposta ao nível real de complexidade do projeto.

- Demonstrar visão de negócio, clareza técnica e responsabilidade.

- Ser direto, sem enrolação comercial vazia.

- Ajustar o nível técnico ao perfil do cliente percebido.

- Tratar o projeto como investimento, não como tarefa.

- Retornar SOMENTE o conteúdo solicitado no formato abaixo.

========================

📥 INPUT

========================

O usuário fornecerá um bloco de texto contendo, quando disponível:

- Descrição do projeto do cliente

- Nicho / mercado

- Objetivo do projeto

- Expectativa do cliente

- Nível de complexidade

- Tipo de serviço desejado

- Prazo desejado

- Orçamento estimado

O texto será fornecido assim:

Projeto do cliente:

[DESCRIÇÃO COLADA PELO USUÁRIO]

========================

📤 OUTPUT (FORMATO OBRIGATÓRIO)

========================

Você DEVE retornar a resposta EXATAMENTE com os seguintes campos,

nesta ordem, sem títulos extras, sem comentários e sem explicações adicionais.

🔹 SUA OFERTA

Retorne apenas um valor em reais, no formato:

R$ X.XXX,00

🔹 OFERTA FINAL

Calcule automaticamente a Oferta Final considerando a taxa padrão da plataforma.

Retorne apenas:

R$ X.XXX,XX

🔹 DURAÇÃO ESTIMADA

Retorne apenas um número inteiro de dias, exemplo:

30

🔹 DETALHES DA PROPOSTA

Gere um texto completo, profissional e persuasivo contendo obrigatoriamente:

- Resumo estratégico do entendimento do projeto

- Posicionamento profissional (consultivo e estratégico quando aplicável)

- Como a solução será estruturada

- Como IA, dados ou inteligência serão aplicados (se fizer sentido)

- Integração com equipe ou fornecedores do cliente (se aplicável)

- Clareza sobre investimento x retorno esperado (sem promessas)

- Encerramento profissional convidando para avançar

REGRAS DO TEXTO:

- Primeira pessoa

- Linguagem clara, madura e objetiva

- Sem listas excessivas

- Sem termos como "garantia de resultado"

- Máximo de 3000 caracteres

- Texto pronto para colar no campo "Detalhes"

========================

CHECKLIST INTERNO (NÃO MOSTRAR)

========================

Antes de entregar:

- Todos os campos estão preenchidos

- Valores coerentes com o projeto

- Linguagem profissional e personalizada

- Texto em primeira pessoa

- Nenhuma informação sensível ou proibida
```

## Estrutura da proposta (literal do output do original)

A IA **deve** devolver, nesta ordem fixa:

1. **🔹 SUA OFERTA** — valor em reais (`R$ X.XXX,00`)
2. **🔹 OFERTA FINAL** — valor com taxa de plataforma aplicada (`R$ X.XXX,XX`)
3. **🔹 DURAÇÃO ESTIMADA** — inteiro de dias
4. **🔹 DETALHES DA PROPOSTA** — texto livre ≤3000 caracteres em 1ª pessoa contendo:
   - Resumo estratégico do entendimento do projeto
   - Posicionamento profissional (consultivo e estratégico quando aplicável)
   - Como a solução será estruturada
   - Como IA, dados ou inteligência serão aplicados (se fizer sentido)
   - Integração com equipe ou fornecedores do cliente (se aplicável)
   - Clareza sobre investimento x retorno esperado (sem promessas)
   - Encerramento profissional convidando para avançar

## Tipos de serviço (literal do SYSTEM_PROMPT)

O original cita no header: **Inteligência Artificial, tráfego pago, dados, BI e performance**. Esses são os 5 verticais. Não inventar outros (web design, consultoria genérica, etc.) — se o projeto colado pelo aluno não cair em nenhum, a IA adapta com a linguagem do prompt mas a skill não força categoria.

## Adaptações permitidas (NÃO mudam conteúdo)

| Original (ZX Growth) | Adaptação na skill |
|---|---|
| HTTP POST a `/generate-proposal` com `{project_description}` | Coleta interativa no terminal Claude Code |
| Lovable Gateway (`ai.gateway.lovable.dev`, `google/gemini-3-flash-preview`) | Claude do aluno (mesmo systemPrompt, mesmo userPrompt) |
| Supabase storage da proposta | Arquivo MD + PDF em `~/clientes/{slug}/` |
| React rendering em `/app/agents/proposals/:id` | Render Markdown + pandoc → PDF |
| Validação `length > 50` em `ProposalsNew.tsx:22` | Mesma validação no input do aluno |

## Validação pós-geração (checklist da skill)

Antes de salvar:
- [ ] Output tem as 4 seções na ordem exata (`SUA OFERTA`, `OFERTA FINAL`, `DURAÇÃO ESTIMADA`, `DETALHES DA PROPOSTA`)
- [ ] `DETALHES DA PROPOSTA` ≤ 3000 caracteres
- [ ] Sem emojis no corpo do texto (exceto os 🔹 dos headers)
- [ ] Texto em primeira pessoa
- [ ] Sem "garantia de resultado" ou variações

Se falhar qualquer item, reexecutar prompt antes de salvar arquivos.

## Ver também

- `reference.md` — tabela origem→trecho→adaptação e comandos pandoc/puppeteer

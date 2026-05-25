---
name: pre-call-checklist
description: "Checklist obrigatório antes de qualquer call de venda de cliente. Imprime 6 itens não-negociáveis (dor quantificada, decisor, segmento, preço memorizado, cases, 5 ações concretas do produto). Carrega contexto automático de cliente já existente em ~/clientes/{slug}/. Imprime 3 frases-modelo prontas pra copiar/colar. Use SEMPRE antes de call comercial, ou quando aluno disser: pre-call, checklist call, antes da call, vou ter call, preparar call, /pre-call-checklist."
model: sonnet
effort: low
---

# /pre-call-checklist — Pré-flight obrigatório de call de vendas

## Por que essa skill existe

Sessão de treino de venda do Sabor Carioca (20/05/2026, score 28/100) mostrou que o aluno cometeu **5 erros previsíveis** durante a call, todos detectáveis ANTES da call começar:

1. Desviou de preço 3x (não tinha o número memorizado)
2. Subcobrou R$ 500 (improvisou o preço na hora)
3. Omitiu mensalidade de R$ 300 (esqueceu de mencionar recorrência)
4. Inventou prova social (não tinha case real preparado)
5. Não fez nenhuma pergunta de discovery (foi direto pro pitch)

Esta skill é o **anti-improvisação**: 60 segundos lendo um checklist mata 100% desses erros.

## Workflow

### 0. Sanitizar slug (OBRIGATÓRIO — antes de qualquer leitura de arquivo)

**Regra de segurança não-negociável.** O `{cliente-slug}` é interpolado em paths do filesystem. Se aluno passar `../../.ssh` ou `; rm -rf $HOME`, a skill abre/escreve em locais arbitrários. Validar SEMPRE antes de tocar disco.

```python
import re
SLUG_REGEX = re.compile(r'^[a-z0-9][a-z0-9_-]{0,63}$')

def validar_slug(slug: str) -> str | None:
    """Retorna slug normalizado ou None se inválido."""
    if not slug:
        return None
    slug = slug.strip().lower()
    if not SLUG_REGEX.match(slug):
        return None  # rejeitar — aluno vê mensagem de erro
    return slug
```

Comportamento:
- Sem slug → checklist genérico (sem contexto carregado), seguir pra seção 1.
- Slug válido (regex acima) → seguir pra seção 1 com contexto.
- Slug inválido (espaço, acento, `..`, `/`, `\`, `;`, `$`, etc) → ABORTAR e imprimir:
  ```
  ❌ Slug inválido: "{slug_original}"
     Use apenas letras minúsculas, números, hífen e underscore (1-64 chars, começa com letra/número).
     Exemplo: pre-call-checklist sabor-carioca-carlos-souza
  ```

### 1. Receber argumento

```
/pre-call-checklist {cliente-slug}
```

`{cliente-slug}` é opcional. Se passado e válido (ver seção 0), a skill busca:
- `~/clientes/{slug}/prototipo-brief.md` — brief do produto
- `~/clientes/{slug}/proposta-*.md` — orçamento (**SEMPRE a mais recente:** `ls -t ~/clientes/{slug}/proposta-*.md 2>/dev/null | head -1` ou `sorted(glob, reverse=True)[0]` em Python)
- `~/calls/{slug}/call-*.md` — análise da call anterior (**SEMPRE a mais recente:** mesmo padrão acima)

Se não passar slug, faz o checklist genérico (placeholders ficam visíveis como `R$ ______` para o aluno preencher mental).

### 2. Imprimir checklist no terminal

Formato literal (copiar/colar):

```
═══════════════════════════════════════════════════════
  PRÉ-CALL CHECKLIST — {cliente_nome} ou "Cliente novo"
  Data: {YYYY-MM-DD} · Horário previsto: {hora || "—"}
═══════════════════════════════════════════════════════

[ 1 ] DOR QUANTIFICADA EM R$/MÊS
      → Cliente perde R$ ____/mês por NÃO ter essa solução?
      → Sem esse número, você vai vender feature, não resultado.
      {se prototipo-brief.md tiver: imprimir o número detectado}

[ 2 ] DECISOR(ES) IDENTIFICADO(S)
      → Quem assina o cheque? Solo ou dupla?
      → Se dupla: AMBOS estarão na call? Se não: agendar de novo.
      {se brief tiver: imprimir o decisor identificado}

[ 3 ] SEGMENTO MAPEADO
      → Linguagem do segmento (NÃO usar "fechar pedido" pra restaurante)
      → Restaurante: cardápio, horário, reserva, delivery
      → E-commerce: conversão, CAC, ticket médio
      → Clínica: agenda, no-show, LGPD
      {se brief tiver: imprimir segmento + 3 termos do glossário}

[ 4 ] PREÇO MEMORIZADO (responder na 1ª pergunta, sem desvio)
      → Setup: R$ ______
      → Recorrência: R$ ______/mês
      → Payback (setup ÷ perda × 30): _____ dias
      {se proposta-*.md existir: imprimir os 3 valores literais}
      ⚠️  3 desvios de preço = cliente interpreta como má-fé

[ 5 ] PROVA SOCIAL DECIDIDA
      Você tem case real do mesmo segmento?
      ( ) SIM — nome + telefone + 1 número (preparar pra falar com profundidade)
      ( ) NÃO — usar o template "vertical nova + garantia 30 dias sem multa"
                JAMAIS inventar "vários cases" ou "estatística de mercado"

[ 6 ] 5 AÇÕES CONCRETAS DO PRODUTO PRA ESSE SEGMENTO
      Listar EXATAMENTE o que o agente faz no dia a dia do cliente.
      Sem "robô que responde clientes" — específico.
      1. _______________________
      2. _______________________
      3. _______________________
      4. _______________________
      5. _______________________
      (Bônus: 1 coisa que ele NÃO faz e passa pra humano)

═══════════════════════════════════════════════════════
  3 FRASES-MODELO PRONTAS (copiar/colar quando precisar)
═══════════════════════════════════════════════════════
```

### 3. Imprimir as 3 frases-modelo

Baseadas no segmento do cliente (do brief) ou genéricas se sem brief:

```
RESPOSTA DE PREÇO (sem desvio):
"{nome_cliente}, vou direto: setup R$ {setup} + R$ {recurring}/mês.
Considerando que vocês perdem R$ {perda_mensal}/mês, paga-se em
{payback} dias. Agora deixa eu te mostrar exatamente o que esses
R$ {setup} entregam."

APRESENTAÇÃO CONCRETA (substituindo "robô que atende"):
"O agente atende {acao_1}, {acao_2}, {acao_3}, {acao_4} e {acao_5}.
Quando aparece {situacao_complexa}, ele transfere pra você com
resumo da conversa. Resolve {porcentagem}% das suas {volume}
mensagens diárias sem você tocar."

TRANSPARÊNCIA SEM CASE (vertical nova):
"{nome_cliente}, vou ser direto — pra {segmento} a gente não
tem volume de cases ainda. O que eu te ofereço é setup com
garantia de cancelamento sem multa nos primeiros 30 dias.
Você vê o resultado no seu próprio número antes de qualquer
compromisso de longo prazo."
```

### 4. Carregar contexto automático (quando cliente-slug é válido)

Tentar ler 3 arquivos de **2 paths diferentes** (brief/proposta vivem em `~/clientes/`, calls vivem em `~/calls/`). Cada leitura é **tolerante a falha** — se um arquivo não existe, ignorar e seguir; NUNCA estourar `FileNotFoundError`.

| Arquivo | Path completo | Pra extrair |
|---|---|---|
| `prototipo-brief.md` | `~/clientes/{slug}/prototipo-brief.md` | Visão geral, problema quantificado, decisor identificado, integrações |
| `proposta-*.md` (a mais recente) | `~/clientes/{slug}/proposta-*.md` | Setup R$, recorrência R$, prazo, garantia |
| `call-*.md` (a mais recente) | `~/calls/{slug}/call-*.md` | Risk flags da call anterior, qualificação BANT, próximo passo combinado |

**Pseudo-código de carregamento gracioso:**

```python
from pathlib import Path

ctx = {"brief": None, "proposta": None, "call": None}

# Brief (1 arquivo fixo)
brief_path = Path.home() / "clientes" / slug / "prototipo-brief.md"
try:
    ctx["brief"] = brief_path.read_text(encoding="utf-8")
except FileNotFoundError:
    pass  # sem brief → checklist mostra placeholders

# Proposta — a MAIS RECENTE
propostas = sorted(
    (Path.home() / "clientes" / slug).glob("proposta-*.md"),
    reverse=True,
) if (Path.home() / "clientes" / slug).exists() else []
if propostas:
    try:
        ctx["proposta"] = propostas[0].read_text(encoding="utf-8")
    except (FileNotFoundError, PermissionError):
        pass

# Call — a MAIS RECENTE (path diferente: ~/calls/, não ~/clientes/)
calls = sorted(
    (Path.home() / "calls" / slug).glob("call-*.md"),
    reverse=True,
) if (Path.home() / "calls" / slug).exists() else []
if calls:
    try:
        ctx["call"] = calls[0].read_text(encoding="utf-8")
    except (FileNotFoundError, PermissionError):
        pass

# Resumo do que carregou
loaded = [k for k, v in ctx.items() if v is not None]
if not loaded:
    print(f"📂 Sem contexto para '{slug}' — gerando checklist genérico.")
```

Se algum arquivo foi carregado, imprimir bloco "Contexto carregado" antes do checklist (mostra APENAS o que existe — itens ausentes ficam de fora, sem warning ruidoso):

```
📂 Contexto carregado:
   • Brief: {data do brief}                       (se existir)
   • Proposta: R$ {setup} + R$ {recurring}/mês    (se existir)
   • Última call: score {score}/100, próximo: "{proximo_passo}"   (se existir)
```

Se NADA foi carregado (slug válido mas sem arquivos), seguir pra seção 2 imprimindo o checklist com placeholders visíveis (`R$ ______`, etc) — não abortar.

### 5. Perguntar se quer salvar registro

Após imprimir checklist + frases-modelo, perguntar **uma única pergunta** (default = N):

```
💾 Salvar esse checklist em ~/clientes/{slug}/pre-call-{YYYY-MM-DD-HHMM}.md? (s/N)
```

- Resposta `s` ou `S` ou `sim` → salvar arquivo + imprimir path
- Resposta vazia, `n`, `N`, `não`, qualquer outro → não salvar, encerrar com `🚀 Boa call.`
- Se sem slug (checklist genérico), **não perguntar** — não há onde salvar de forma consistente.

Comportamento padrão é NÃO salvar — pra não poluir `~/clientes/` com 1 arquivo por treino.

### 6. NÃO gerar HTML / NÃO registrar no painel

Esta skill é **operacional, não deliverable**. Não gera HTML, não atualiza painel. É um checklist consumido pelo aluno na hora da call e depois descartado (ou guardado localmente como referência).

## Validação

A skill considera-se bem-sucedida quando:
- [ ] Checklist impresso com 6 itens numerados
- [ ] Se `{cliente-slug}` passado: contexto carregado e injetado nos placeholders
- [ ] Pelo menos 3 frases-modelo impressas com preço e segmento corretos
- [ ] Tempo de execução < 5 segundos (skill é blocante — aluno vai pra call em seguida)

## Anti-patterns (NÃO fazer)

- ❌ Gerar HTML ou registrar no painel (não é deliverable)
- ❌ Pedir 10 inputs ao aluno (o objetivo é AGILIDADE — usa o que já tem)
- ❌ Inventar dor ou números se brief não tem
- ❌ Esconder valor de recorrência (anti-erro principal — força explicitação)
- ❌ Sugerir "vários cases" se aluno não tem case real (força transparência)

## Integração com outras skills do Setup 8

- Precedente lógico: `/prototipar-sistema` + `/criar-orcamento` (brief + proposta já existem)
- Sucessor lógico: a call real, depois `/analise-call` pra fazer post-mortem
- Treino preventivo: `/simulador-vendas --focus desvio-preco` rodado 2-3x antes da call real

## Output exemplo

```
═══════════════════════════════════════════════════════
  PRÉ-CALL CHECKLIST — Carlos Souza (Sabor Carioca)
  Data: 2026-05-21 · Horário: 15:00
═══════════════════════════════════════════════════════

📂 Contexto carregado:
   • Brief: 2026-05-20 (Agente IA WhatsApp)
   • Proposta: R$ 1.500 + R$ 300/mês (7 dias)
   • Última call: score 28/100 — sócia entrou na próxima

[ 1 ] DOR: ✅ R$ 4.000/mês (4-5 mesas perdidas × R$ 200)
[ 2 ] DECISOR: ⚠️  DUPLA — Carlos + sócia Maria. Ambos na call? CONFIRMAR.
[ 3 ] SEGMENTO: Restaurante — cardápio, horário, reserva, delivery, estacionamento
[ 4 ] PREÇO MEMORIZADO:
        Setup: R$ 1.500  · Recorrência: R$ 300/mês  · Payback: 11 dias
[ 5 ] PROVA SOCIAL: ⚠️  SEM CASE de restaurante — usar template
                       "vertical nova + garantia 30d sem multa"
[ 6 ] 5 AÇÕES DO AGENTE:
      1. Cardápio completo com preço
      2. Horário de funcionamento (e fora-do-horário)
      3. Reserva com registro em Google Sheets
      4. Delivery: cobertura, prazo, preço mínimo
      5. Handoff humano em reclamação ou pedido complexo

═══════════════════════════════════════════════════════
  3 FRASES-MODELO (copiar/colar)
═══════════════════════════════════════════════════════

PREÇO:
"Maria, vou direto: setup R$ 1.500 + R$ 300/mês.
Vocês perdem R$ 4 mil por mês — paga em 11 dias. Agora deixa
eu mostrar exatamente o que esse R$ 1.500 entrega."

APRESENTAÇÃO:
"O agente atende cardápio, horário, endereço, estacionamento
e reserva — registra reserva direto na planilha que vocês já
usam. Quando aparece reclamação ou pedido especial, transfere
pro WhatsApp do Carlos com resumo. Resolve 80% das 100 msgs
diárias sem vocês tocarem."

SEM CASE:
"Maria, não vou te enrolar — pra restaurante a gente não tem
volume de cases ainda. O que eu ofereço é garantia de cancelamento
sem multa nos primeiros 30 dias. Você vê o resultado no próprio
número antes de qualquer compromisso de longo prazo."

═══════════════════════════════════════════════════════
🚀 Você está pronto. Boa call.
═══════════════════════════════════════════════════════
```

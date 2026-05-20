# criar-orcamento — Referência

## Tech debt aceitável (não-blocker)

- **Trailing whitespaces** em ~15 linhas do SYSTEM_PROMPT foram removidos durante o copy (vs `generate-proposal/index.ts:8/12/14/96-116`). Funcionalmente irrelevante — LLMs normalizam whitespace e o output não muda. Não vale a pena reaplicar trailing spaces.

## Tabela origem → trecho → adaptação

| Origem (ZX Growth) | Trecho literal | Adaptação na skill |
|---|---|---|
| `generate-proposal/index.ts:8-164` | `systemPrompt` (regras absolutas, input, output em 4 campos, checklist interno) | **Copiado literal** no SKILL.md. Não reescrever. |
| `generate-proposal/index.ts:188-190` | `userPrompt = "Projeto do cliente:\n\n${project_description}"` | Mesmo formato. Coleta interativa no terminal monta `project_description`. |
| `generate-proposal/index.ts:199` | `model: "google/gemini-3-flash-preview"` (via Lovable Gateway) | Claude do aluno na sessão (mesmo SYSTEM_PROMPT + userPrompt). |
| `ProposalsNew.tsx:22` | `if (trimmed.length < 50)` | Validação `length < 50` no input do aluno (não gera abaixo disso). |
| `ProposalsNew.tsx:62-77` | Placeholder com 5 campos sugeridos: Descrição, Nicho, Objetivo, Prazo, Orçamento | Ordem da coleta interativa segue esses 5 + 3 opcionais do SYSTEM_PROMPT (Expectativa, Nível de complexidade, Tipo de serviço). |
| Output: 4 seções começando em `🔹` (sem `##`, sem títulos extras) | `🔹 SUA OFERTA / 🔹 OFERTA FINAL / 🔹 DURAÇÃO ESTIMADA / 🔹 DETALHES DA PROPOSTA` | Mesmo formato literal do original (`generate-proposal/index.ts:96-116`). Output começa direto em `🔹 SUA OFERTA`, sem `##`, sem `# Proposta —`, sem `Data:`. O wrapper local (envelope MD) adiciona título+data POR FORA do output da IA, ver SKILL.md seção "Pós-processo local". |
| Supabase storage | Tabela `proposals` no DB | Arquivos locais em `~/clientes/{cliente-slug}/proposta-{YYYY-MM-DD}.{md,pdf}`. |
| Lovable Gateway `ai.gateway.lovable.dev` | HTTP POST com bearer `LOVABLE_API_KEY` | Claude do aluno (sem custo extra, mesmo prompt). |

## Comandos PDF (em ordem de preferência)

### 1. Pandoc + wkhtmltopdf (recomendado, leve)

```bash
brew install pandoc wkhtmltopdf  # se faltar
pandoc ~/clientes/{slug}/proposta-{date}.md \
  -o ~/clientes/{slug}/proposta-{date}.pdf \
  --pdf-engine=wkhtmltopdf \
  -V margin-top=25mm -V margin-bottom=25mm \
  -V margin-left=20mm -V margin-right=20mm \
  -V mainfont="Helvetica"
```

### 2. Pandoc + xelatex (fallback, mais pesado mas universal)

```bash
brew install pandoc basictex  # ~100MB
pandoc ~/clientes/{slug}/proposta-{date}.md \
  -o ~/clientes/{slug}/proposta-{date}.pdf \
  --pdf-engine=xelatex \
  -V geometry:margin=2.5cm \
  -V mainfont="Helvetica"
```

### 3. Puppeteer (fallback se pandoc não tiver)

```bash
# Converter MD → HTML primeiro
pandoc ~/clientes/{slug}/proposta-{date}.md -o /tmp/proposta.html --standalone

# Puppeteer via Node
cat <<'EOF' > /tmp/md2pdf.js
const puppeteer = require('puppeteer');
(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.goto('file:///tmp/proposta.html', { waitUntil: 'networkidle0' });
  await page.pdf({
    path: process.argv[2],
    format: 'A4',
    margin: { top: '25mm', bottom: '25mm', left: '20mm', right: '20mm' }
  });
  await browser.close();
})();
EOF
node /tmp/md2pdf.js ~/clientes/{slug}/proposta-{date}.pdf
```

## Conversão de slug

```bash
# Nome do cliente "Padaria do João" → slug "padaria-do-joao"
slug=$(echo "$nome_cliente" | iconv -t ASCII//TRANSLIT | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
```

## Validação pós-geração (regex)

```python
import re

def validar_proposta(texto: str) -> list[str]:
    erros = []
    for secao in ["SUA OFERTA", "OFERTA FINAL", "DURAÇÃO ESTIMADA", "DETALHES DA PROPOSTA"]:
        if secao not in texto:
            erros.append(f"Falta seção: {secao}")
    if re.search(r"garantia de resultado", texto, re.IGNORECASE):
        erros.append("Contém 'garantia de resultado' (proibido pelo SYSTEM_PROMPT)")
    # Detalhes ≤ 3000 chars
    detalhes_match = re.search(r"DETALHES DA PROPOSTA\s*(.+)$", texto, re.DOTALL)
    if detalhes_match and len(detalhes_match.group(1)) > 3000:
        erros.append(f"Detalhes ultrapassam 3000 caracteres ({len(detalhes_match.group(1))})")
    return erros
```

## Edge cases observados no original

- **`length < 50` no input** — `ProposalsNew.tsx:22` rejeita inputs curtos com toast `"A descrição do projeto deve ter pelo menos 50 caracteres."`. Replicar.
- **Sem `purchase_date` no Greenn** — não relevante aqui; vale só pro hotmart-connector.
- **Rate limit 429 + payment 402** — no original há tratamento via toast (`Limite de requisições excedido` / `Créditos insuficientes`). Na skill, Claude do aluno não tem esse problema diretamente, mas se sessão estourar, avisar o aluno pra reexecutar.
- **`proposalText` vazio** — `index.ts:230-232` lança `"Resposta vazia da IA"`. Replicar: se Claude devolver < 200 chars, reexecutar uma vez antes de salvar.

## Não fazer

- ❌ Adicionar campos extras tipo "Cronograma detalhado por semana", "Próximos passos numerados", "Investimento parcelado em 3x" — o output original tem **4 seções fixas**, ponto.
- ❌ Trocar 🔹 por outro emoji ou remover.
- ❌ Usar segunda pessoa ("Você terá...") — o prompt é claro: **primeira pessoa**.
- ❌ Inventar tipos de serviço fora dos 5 do header (IA, tráfego pago, dados, BI, performance).

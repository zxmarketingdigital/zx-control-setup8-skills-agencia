# `_shared` — Helpers compartilhados entre skills ZX LAB

Padrão ZX LAB obrigatório pra TODA skill que gera deliverable do aluno:

1. **MD** (source-of-truth) — Claude escreve com `Write` tool
2. **HTML** (dark theme) — `md_to_html.py` converte com identidade ZX Control
3. **Registro no Painel central** — `update_launcher.py` adiciona ao `~/zxlab-aluno/index.html`

Os 3 passos são obrigatórios, nessa ordem. Não opcional.

---

## `md_to_html.py` — Conversor MD → HTML dark

Identidade visual: âmbar `#D97706` + Inter + JetBrains Mono, fundo `#0D0D0D`, surface `#1A1A1A` (espelho da área de membros ZX Control). Light theme automático na impressão (print media).

### Uso

```bash
python3 ~/.claude/skills/_shared/md_to_html.py \
  /caminho/absoluto/arquivo.md \
  /caminho/absoluto/arquivo.html \
  "Título da página" \
  --skill nome-da-skill \
  --cliente "Nome do cliente (opcional)"
```

### O que faz

1. Lê o MD
2. Converte com `markdown` (extensões: `extra`, `tables`, `sane_lists`)
3. Trata checkboxes `[ ]` e `[x]` como inputs estilizados
4. Embute no template dark ZX LAB
5. Adiciona header sticky com botão `← Painel ZX LAB` apontando pro launcher
6. Salva em `output.html` (self-contained, single Google Fonts CDN dep)

---

## `update_launcher.py` — Painel central do aluno

Mantém `~/zxlab-aluno/catalog.json` (source-of-truth, dedup por `html_path`) + regenera `~/zxlab-aluno/index.html` (dashboard dark com cards, filtros por skill, busca por cliente/título).

### Uso

```bash
python3 ~/.claude/skills/_shared/update_launcher.py \
  --html /caminho/absoluto/output.html \
  --title "Diagnóstico — Carlos" \
  --skill diagnostico-empreendedor \
  --cliente "Carlos Mendes" \
  --summary "Perfil X. Áreas: A, B, C."
```

### O que faz

1. Carrega `catalog.json` (cria se não existir)
2. Adiciona/atualiza entry (dedup por `html_path`)
3. Salva catalog
4. Regenera `index.html` com cards, chips de filtro por skill, busca em tempo real
5. Cria a estrutura `~/zxlab-aluno/` na primeira execução

### Skills mapeadas no painel

| Skill | Tag | Cor | Ícone |
|---|---|---|---|
| `diagnostico-empreendedor` | Diagnóstico | `#F59E0B` | ◈ |
| `analise-call` | Análise de Call | `#818CF8` | ◉ |
| `prototipar-sistema` | Protótipo | `#4ADE80` | ◆ |
| `simulador-vendas` | Treino de Vendas | `#FCD34D` | ▲ |
| `criar-orcamento` | Proposta | `#D97706` | ■ |

Pra adicionar uma skill nova ao painel: editar `SKILL_META` em `update_launcher.py`.

---

## Onde cada skill grava

| Skill | MD/HTML path padrão |
|---|---|
| `diagnostico-empreendedor` | `~/meu-plano/diagnostico-{date}.{md,html}` + `~/meu-plano/plano-30d-{date}.{md,html}` |
| `analise-call` | `~/calls/{slug}/call-{date}.{md,html}` |
| `prototipar-sistema` | `~/clientes/{slug}/prototipo-{brief,etapas,test-plan}.{md,html}` |
| `simulador-vendas` | `~/treino-vendas/sessao-{ts}.{md,html}` |
| `criar-orcamento` | `~/clientes/{slug}/proposta-{date}.{md,html,pdf}` |

Painel central (sempre o mesmo): `~/zxlab-aluno/index.html`

---

## Dependência Python

```bash
pip3 install markdown
```

Já instalado em `python3` global do Mac (validado 2026-05-20).

---

## Em modo DRY-RUN

Sessão de teste (`~/zx-skills-teste/`): gerar HTML ao lado do MD nos paths de teste e registrar no painel normalmente — o painel mostra todos os deliverables independente da origem (real vs teste).

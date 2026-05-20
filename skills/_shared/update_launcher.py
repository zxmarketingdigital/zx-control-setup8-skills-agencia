#!/usr/bin/env python3
"""
update_launcher.py — Registra deliverable no painel central ZX LAB do aluno.

Uso:
    python3 update_launcher.py \\
        --html /caminho/absoluto/output.html \\
        --title "Diagnóstico — Carlos" \\
        --skill diagnostico-empreendedor \\
        [--cliente "Nome do cliente"] \\
        [--summary "1 linha de resumo, opcional"] \\
        [--catalog ~/zxlab-aluno/catalog.json]

Mantém catalog.json (source-of-truth) + regenera index.html (painel dark ZX LAB).
Cria estrutura do painel se não existir.

Toda skill que gera deliverable DEVE chamar este script logo após md_to_html.py.
"""

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path


SKILL_META = {
    "diagnostico-empreendedor": {"label": "Diagnóstico", "icon": "◈", "tone": "#F59E0B"},
    "analise-call": {"label": "Análise de Call", "icon": "◉", "tone": "#818CF8"},
    "prototipar-sistema": {"label": "Protótipo", "icon": "◆", "tone": "#4ADE80"},
    "simulador-vendas": {"label": "Treino de Vendas", "icon": "▲", "tone": "#FCD34D"},
    "criar-orcamento": {"label": "Proposta", "icon": "■", "tone": "#D97706"},
}
DEFAULT_META = {"label": "Deliverable", "icon": "●", "tone": "#9CA3AF"}


def load_catalog(path: Path) -> dict:
    if path.exists():
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            pass
    return {"entries": []}


def save_catalog(path: Path, catalog: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(catalog, indent=2, ensure_ascii=False), encoding="utf-8")


def register(catalog: dict, entry: dict) -> dict:
    # Dedup por html_path: se já existir, atualiza (não duplica).
    entries = catalog.get("entries", [])
    for i, e in enumerate(entries):
        if e.get("html_path") == entry["html_path"]:
            entries[i] = entry
            catalog["entries"] = entries
            return catalog
    entries.append(entry)
    catalog["entries"] = entries
    return catalog


def render_launcher(catalog: dict, output_path: Path) -> None:
    entries = sorted(catalog.get("entries", []), key=lambda e: e.get("created_at", ""), reverse=True)
    total = len(entries)
    skills_set = sorted({e.get("skill", "") for e in entries if e.get("skill")})
    skills_count = len(skills_set)
    clientes_set = sorted({e.get("cliente", "") for e in entries if e.get("cliente")})
    clientes_count = len(clientes_set)

    # Cards
    cards_html_parts = []
    for e in entries:
        meta = SKILL_META.get(e.get("skill", ""), DEFAULT_META)
        date_iso = e.get("created_at", "")[:10]
        cliente = e.get("cliente") or ""
        summary = e.get("summary") or ""
        title = e.get("title", "")
        skill = e.get("skill", "")
        href = e.get("html_path", "")

        card = f"""    <a class="card" href="{href}" target="_blank" rel="noopener" data-skill="{skill}" data-text="{_esc(title.lower() + ' ' + cliente.lower() + ' ' + summary.lower())}">
      <div class="card-head">
        <span class="tag" style="--tone: {meta['tone']};">
          <span class="dot">{meta['icon']}</span>{meta['label']}
        </span>
        <time>{date_iso}</time>
      </div>
      <h3 class="card-title">{_esc(title)}</h3>
      {f'<div class="card-cliente">{_esc(cliente)}</div>' if cliente else ''}
      {f'<p class="card-summary">{_esc(summary)}</p>' if summary else ''}
      <div class="card-foot">Abrir <span class="arrow">→</span></div>
    </a>"""
        cards_html_parts.append(card)
    cards_html = "\n".join(cards_html_parts) if cards_html_parts else """    <div class="empty">
      <div class="empty-icon">◐</div>
      <div class="empty-title">Nenhum deliverable ainda</div>
      <div class="empty-sub">Rode uma skill (/diagnostico-empreendedor, /analise-call, /prototipar-sistema, /simulador-vendas, /criar-orcamento) e o resultado aparece aqui automaticamente.</div>
    </div>"""

    # Skill filter chips
    chips_parts = ['<button class="chip active" data-skill="">Todos <span class="chip-count">{}</span></button>'.format(total)]
    for s in skills_set:
        meta = SKILL_META.get(s, DEFAULT_META)
        count = sum(1 for e in entries if e.get("skill") == s)
        chips_parts.append(
            f'<button class="chip" data-skill="{s}" style="--tone: {meta["tone"]};">{meta["label"]} <span class="chip-count">{count}</span></button>'
        )
    chips_html = "\n        ".join(chips_parts)

    generated_at = datetime.now().strftime("%Y-%m-%d %H:%M")

    html = LAUNCHER_TEMPLATE.format(
        total=total,
        skills_count=skills_count,
        clientes_count=clientes_count,
        cards=cards_html,
        chips=chips_html,
        generated_at=generated_at,
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(html, encoding="utf-8")


def _esc(s: str) -> str:
    return (
        str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        .replace('"', "&quot;")
    )


LAUNCHER_TEMPLATE = """<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Painel ZX LAB · Meus Deliverables</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&family=JetBrains+Mono:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
:root {{
  --primary: #D97706;
  --primary-light: #F59E0B;
  --primary-bright: #FCD34D;
  --primary-dark: #92400e;
  --bg: #0D0D0D;
  --bg-alt: #0A0A0A;
  --surface: #1A1A1A;
  --surface2: #222222;
  --text: #E2E8F0;
  --text-secondary: #9CA3AF;
  --text-muted: #6B7280;
  --border: #2A2A2A;
  --border-light: #333333;
  --green: #4ADE80;
}}
* {{ box-sizing: border-box; }}
html, body {{ margin: 0; padding: 0; background: var(--bg); }}
body {{
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  color: var(--text);
  font-size: 16px;
  line-height: 1.6;
  -webkit-font-smoothing: antialiased;
  background: radial-gradient(ellipse at 50% -10%, rgba(217, 119, 6, 0.10), transparent 55%), var(--bg);
  min-height: 100vh;
}}
.shell {{ max-width: 1200px; margin: 0 auto; padding: 56px 32px 96px; }}
.brand-line {{
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.72rem;
  letter-spacing: 0.25em;
  font-weight: 700;
  color: var(--primary);
  text-transform: uppercase;
  margin-bottom: 16px;
}}
.hero {{
  display: grid;
  grid-template-columns: 1.5fr 1fr;
  gap: 48px;
  align-items: end;
  padding-bottom: 36px;
  border-bottom: 1px solid var(--border);
  margin-bottom: 40px;
}}
.hero h1 {{
  font-family: 'Inter', sans-serif;
  font-size: 3rem;
  font-weight: 900;
  letter-spacing: -0.03em;
  line-height: 1.05;
  margin: 0 0 12px;
  color: var(--text);
}}
.hero h1 .accent {{
  background: linear-gradient(135deg, var(--primary-light), var(--primary-bright));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}}
.hero p {{
  color: var(--text-secondary);
  font-size: 1.02rem;
  margin: 0;
  max-width: 56ch;
}}
.stats {{
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}}
.stat {{
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 18px;
  text-align: left;
}}
.stat .num {{
  font-family: 'JetBrains Mono', monospace;
  font-size: 1.8rem;
  font-weight: 700;
  color: var(--primary-bright);
  line-height: 1;
}}
.stat .lbl {{
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.68rem;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  color: var(--text-muted);
  margin-top: 8px;
}}
.toolbar {{
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 24px;
}}
.chips {{ display: flex; flex-wrap: wrap; gap: 8px; }}
.chip {{
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.72rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  font-weight: 600;
  padding: 7px 13px;
  background: transparent;
  color: var(--text-secondary);
  border: 1px solid var(--border);
  border-radius: 999px;
  cursor: pointer;
  transition: all .15s;
  --tone: var(--primary);
}}
.chip:hover {{ border-color: var(--tone); color: var(--text); }}
.chip.active {{
  background: color-mix(in srgb, var(--tone) 14%, transparent);
  border-color: var(--tone);
  color: var(--text);
}}
.chip-count {{
  display: inline-block;
  margin-left: 6px;
  padding: 1px 7px;
  background: var(--surface2);
  border-radius: 999px;
  font-size: 0.62rem;
  color: var(--text);
}}
.search {{
  position: relative;
  flex: 0 0 280px;
  max-width: 320px;
}}
.search input {{
  width: 100%;
  padding: 9px 14px 9px 36px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text);
  font-family: 'Inter', sans-serif;
  font-size: 0.9rem;
  outline: none;
  transition: border-color .15s;
}}
.search input:focus {{ border-color: var(--primary); }}
.search input::placeholder {{ color: var(--text-muted); }}
.search::before {{
  content: "⌕";
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: var(--text-muted);
  font-size: 1rem;
}}
.grid {{
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 18px;
}}
.card {{
  display: flex;
  flex-direction: column;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 20px;
  text-decoration: none;
  color: inherit;
  transition: all .2s;
  position: relative;
  overflow: hidden;
}}
.card::before {{
  content: "";
  position: absolute;
  inset: 0;
  border-radius: 10px;
  pointer-events: none;
  background: radial-gradient(ellipse at top right, rgba(217, 119, 6, 0.08), transparent 60%);
  opacity: 0;
  transition: opacity .2s;
}}
.card:hover {{
  border-color: var(--primary);
  transform: translateY(-2px);
}}
.card:hover::before {{ opacity: 1; }}
.card-head {{
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 14px;
  font-size: 0.75rem;
}}
.card-head time {{
  font-family: 'JetBrains Mono', monospace;
  color: var(--text-muted);
  letter-spacing: 0.05em;
}}
.tag {{
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.7rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  padding: 4px 9px;
  border-radius: 4px;
  background: color-mix(in srgb, var(--tone) 16%, transparent);
  color: var(--tone);
  border: 1px solid color-mix(in srgb, var(--tone) 40%, transparent);
  --tone: var(--primary);
}}
.tag .dot {{ font-size: 0.85rem; line-height: 0; }}
.card-title {{
  font-family: 'Inter', sans-serif;
  font-size: 1.05rem;
  font-weight: 700;
  line-height: 1.3;
  color: var(--text);
  margin: 0 0 8px;
  letter-spacing: -0.01em;
}}
.card-cliente {{
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  color: var(--primary-light);
  margin-bottom: 8px;
  letter-spacing: 0.02em;
}}
.card-summary {{
  font-size: 0.88rem;
  color: var(--text-secondary);
  margin: 0 0 16px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}}
.card-foot {{
  margin-top: auto;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.74rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--primary-light);
  font-weight: 600;
  padding-top: 12px;
  border-top: 1px dashed var(--border);
  display: flex;
  justify-content: space-between;
  align-items: center;
}}
.card-foot .arrow {{ transition: transform .15s; }}
.card:hover .card-foot .arrow {{ transform: translateX(4px); color: var(--primary-bright); }}
.empty {{
  grid-column: 1 / -1;
  background: var(--surface);
  border: 1px dashed var(--border);
  border-radius: 10px;
  padding: 48px 32px;
  text-align: center;
}}
.empty-icon {{ font-size: 3rem; color: var(--text-muted); margin-bottom: 16px; }}
.empty-title {{ font-size: 1.15rem; font-weight: 700; color: var(--text); margin-bottom: 8px; }}
.empty-sub {{ color: var(--text-secondary); font-size: 0.95rem; max-width: 60ch; margin: 0 auto; }}
.no-results {{
  grid-column: 1 / -1;
  padding: 32px;
  text-align: center;
  color: var(--text-muted);
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.85rem;
}}
footer.shell-footer {{
  margin-top: 64px;
  padding-top: 24px;
  border-top: 1px solid var(--border);
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.7rem;
  color: var(--text-muted);
  text-align: center;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}}
footer .accent {{ color: var(--primary); font-weight: 700; }}
@media (max-width: 720px) {{
  .shell {{ padding: 32px 20px 64px; }}
  .hero {{ grid-template-columns: 1fr; gap: 32px; }}
  .hero h1 {{ font-size: 2rem; }}
  .toolbar {{ flex-direction: column; align-items: stretch; }}
  .search {{ flex: 1; max-width: 100%; }}
}}
</style>
</head>
<body>
<main class="shell">
  <div class="brand-line">ZX LAB · Painel do Aluno</div>
  <section class="hero">
    <div>
      <h1>Meus <span class="accent">Deliverables</span></h1>
      <p>Tudo o que você gerou rodando suas skills da agência IA — diagnósticos, calls, protótipos, treinos e propostas — concentrado num lugar. Cada skill que você roda aparece aqui automaticamente.</p>
    </div>
    <div class="stats">
      <div class="stat">
        <div class="num">{total:02d}</div>
        <div class="lbl">Deliverables</div>
      </div>
      <div class="stat">
        <div class="num">{skills_count:02d}</div>
        <div class="lbl">Skills usadas</div>
      </div>
      <div class="stat">
        <div class="num">{clientes_count:02d}</div>
        <div class="lbl">Clientes</div>
      </div>
    </div>
  </section>

  <div class="toolbar">
    <div class="chips" id="chips">
        {chips}
    </div>
    <div class="search">
      <input id="search" type="search" placeholder="Buscar por cliente, título…" autocomplete="off">
    </div>
  </div>

  <div class="grid" id="grid">
{cards}
  </div>

  <footer class="shell-footer">
    <span class="accent">ZX LAB</span> · Gerado por Claude Code · {generated_at}
  </footer>
</main>
<script>
(() => {{
  const grid = document.getElementById('grid');
  const chips = document.getElementById('chips');
  const search = document.getElementById('search');
  let activeSkill = '';
  let query = '';

  function apply() {{
    const cards = grid.querySelectorAll('.card');
    let visible = 0;
    cards.forEach(c => {{
      const matchSkill = !activeSkill || c.dataset.skill === activeSkill;
      const matchQuery = !query || (c.dataset.text || '').includes(query);
      const show = matchSkill && matchQuery;
      c.style.display = show ? '' : 'none';
      if (show) visible++;
    }});
    let nr = grid.querySelector('.no-results');
    if (visible === 0 && cards.length > 0) {{
      if (!nr) {{
        nr = document.createElement('div');
        nr.className = 'no-results';
        nr.textContent = 'Nenhum deliverable encontrado pra esse filtro.';
        grid.appendChild(nr);
      }}
    }} else if (nr) {{
      nr.remove();
    }}
  }}

  chips.addEventListener('click', (e) => {{
    const btn = e.target.closest('.chip');
    if (!btn) return;
    chips.querySelectorAll('.chip').forEach(c => c.classList.remove('active'));
    btn.classList.add('active');
    activeSkill = btn.dataset.skill || '';
    apply();
  }});

  search.addEventListener('input', (e) => {{
    query = e.target.value.toLowerCase().trim();
    apply();
  }});
}})();
</script>
</body>
</html>
"""


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--html", required=True, help="caminho absoluto do HTML gerado")
    parser.add_argument("--title", required=True, help="título do deliverable")
    parser.add_argument("--skill", required=True, help="nome da skill")
    parser.add_argument("--cliente", default="", help="nome do cliente/lead/aluno (opcional)")
    parser.add_argument("--summary", default="", help="resumo de 1 linha (opcional)")
    parser.add_argument("--catalog", default="~/zxlab-aluno/catalog.json")
    parser.add_argument("--launcher", default="~/zxlab-aluno/index.html")
    args = parser.parse_args()

    catalog_path = Path(args.catalog).expanduser()
    launcher_path = Path(args.launcher).expanduser()
    html_abs = str(Path(args.html).expanduser().resolve())

    entry = {
        "html_path": html_abs,
        "title": args.title,
        "skill": args.skill,
        "cliente": args.cliente,
        "summary": args.summary,
        "created_at": datetime.now().isoformat(timespec="seconds"),
    }

    catalog = load_catalog(catalog_path)
    catalog = register(catalog, entry)
    save_catalog(catalog_path, catalog)
    render_launcher(catalog, launcher_path)
    print(f"✅ Painel atualizado: {launcher_path}")

#!/usr/bin/env python3
"""
md_to_html.py — Conversor MD → HTML com identidade visual ZX LAB (DARK theme).

Uso:
    python3 md_to_html.py input.md output.html "Título da página" \\
        [--skill nome-da-skill] [--cliente "Nome do cliente"] [--meta "key=value,k2=v2"]

Padrão visual: DESIGN.md global (~/projetos/zx-control-lp/DESIGN.md)
- Background #0D0D0D, surface #1A1A1A
- Acento âmbar #D97706 / #F59E0B
- Inter (body) + JetBrains Mono (headers/code)
- Header com link "← Painel ZX LAB" pra navegação
- Self-contained (Google Fonts CDN único external dep)

Toda skill que gera deliverable DEVE chamar:
  1. md_to_html.py (este script) — gera o HTML
  2. update_launcher.py — registra no painel central ~/zxlab-aluno/index.html
"""

import sys
import argparse
from pathlib import Path

try:
    import markdown
except ImportError:
    print("ERRO: instale com 'pip3 install markdown'", file=sys.stderr)
    sys.exit(1)


HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{title}</title>
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
  --footer: #080808;
  --text: #E2E8F0;
  --text-secondary: #9CA3AF;
  --text-muted: #6B7280;
  --border: #2A2A2A;
  --border-light: #333333;
  --green: #4ADE80;
  --red: #EF4444;
  --indigo: #818CF8;
}}
* {{ box-sizing: border-box; }}
html, body {{ margin: 0; padding: 0; background: var(--bg); }}
body {{
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  color: var(--text);
  font-size: 16px;
  line-height: 1.7;
  -webkit-font-smoothing: antialiased;
  background: radial-gradient(ellipse at top, rgba(217, 119, 6, 0.04), transparent 60%), var(--bg);
  min-height: 100vh;
}}
.nav {{
  position: sticky;
  top: 0;
  z-index: 10;
  background: rgba(13, 13, 13, 0.92);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--border);
  padding: 14px 0;
}}
.nav-inner {{
  max-width: 920px;
  margin: 0 auto;
  padding: 0 32px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}}
.nav a.back {{
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  color: var(--primary-light);
  text-decoration: none;
  padding: 6px 12px;
  border: 1px solid var(--border);
  border-radius: 4px;
  transition: all .15s;
  text-transform: uppercase;
}}
.nav a.back:hover {{
  background: rgba(217, 119, 6, 0.12);
  border-color: var(--primary);
  color: var(--primary-bright);
}}
.nav-meta {{
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.72rem;
  letter-spacing: 0.1em;
  color: var(--text-muted);
  text-transform: uppercase;
}}
.nav-meta .brand {{ color: var(--primary); font-weight: 700; }}
.page {{
  max-width: 920px;
  margin: 0 auto;
  padding: 56px 48px 96px;
}}
.header {{
  margin-bottom: 48px;
  padding-bottom: 24px;
  border-bottom: 1px solid var(--border);
}}
.header .eyebrow {{
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: var(--primary);
  margin-bottom: 12px;
}}
.header .title {{
  font-family: 'Inter', sans-serif;
  font-size: 2.4rem;
  font-weight: 800;
  letter-spacing: -0.02em;
  line-height: 1.15;
  color: var(--text);
  margin: 0;
}}
.content h1 {{
  font-family: 'Inter', sans-serif;
  font-size: 1.9rem;
  font-weight: 800;
  letter-spacing: -0.02em;
  line-height: 1.2;
  margin: 0 0 28px;
  color: var(--text);
}}
.content h2 {{
  font-family: 'Inter', sans-serif;
  font-size: 1.45rem;
  font-weight: 700;
  letter-spacing: -0.01em;
  line-height: 1.3;
  margin: 48px 0 16px;
  color: var(--text);
  padding-bottom: 10px;
  border-bottom: 1px solid var(--border);
}}
.content h3 {{
  font-family: 'Inter', sans-serif;
  font-size: 1.1rem;
  font-weight: 700;
  margin: 32px 0 12px;
  color: var(--primary-light);
}}
.content h4 {{
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  font-weight: 600;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  margin: 24px 0 8px;
  color: var(--primary-bright);
}}
.content p {{ margin: 0 0 16px; color: var(--text); }}
.content strong {{ color: var(--text); font-weight: 700; }}
.content em {{ color: var(--text-secondary); }}
.content a {{
  color: var(--primary-light);
  text-decoration: none;
  border-bottom: 1px dashed var(--primary-dark);
  transition: all .15s;
}}
.content a:hover {{
  color: var(--primary-bright);
  border-bottom-color: var(--primary);
}}
.content ul, .content ol {{
  margin: 0 0 20px;
  padding-left: 24px;
  color: var(--text);
}}
.content li {{ margin-bottom: 8px; }}
.content li::marker {{ color: var(--primary); }}
.content blockquote {{
  margin: 24px 0;
  padding: 14px 22px;
  border-left: 3px solid var(--primary);
  background: var(--surface);
  border-radius: 0 6px 6px 0;
  color: var(--text-secondary);
}}
.content blockquote p:last-child {{ margin-bottom: 0; }}
.content code {{
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.86em;
  background: var(--surface2);
  padding: 2px 7px;
  border-radius: 3px;
  border: 1px solid var(--border);
  color: var(--primary-bright);
}}
.content pre {{
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.86rem;
  background: var(--bg-alt);
  color: var(--text);
  padding: 18px 22px;
  border-radius: 6px;
  border: 1px solid var(--border);
  overflow-x: auto;
  margin: 20px 0;
  line-height: 1.55;
}}
.content pre code {{
  background: transparent;
  border: none;
  color: inherit;
  padding: 0;
}}
.content table {{
  width: 100%;
  border-collapse: collapse;
  margin: 24px 0;
  font-size: 0.92rem;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 6px;
  overflow: hidden;
}}
.content th {{
  background: var(--surface2);
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.74rem;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  text-align: left;
  padding: 12px 14px;
  border-bottom: 2px solid var(--primary);
  color: var(--primary-bright);
}}
.content td {{
  padding: 12px 14px;
  border-bottom: 1px solid var(--border);
  color: var(--text);
  vertical-align: top;
}}
.content tr:last-child td {{ border-bottom: none; }}
.content tr:hover td {{ background: var(--surface2); }}
.content hr {{
  border: none;
  height: 1px;
  background: linear-gradient(90deg, transparent, var(--border) 20%, var(--border) 80%, transparent);
  margin: 48px 0;
}}
.content input[type="checkbox"] {{
  margin-right: 8px;
  accent-color: var(--primary);
  transform: translateY(1px);
}}
.content li.task-list-item {{ list-style: none; margin-left: -24px; }}
.footer {{
  margin-top: 72px;
  padding-top: 24px;
  border-top: 1px solid var(--border);
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.72rem;
  color: var(--text-muted);
  text-align: center;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}}
.footer .accent {{ color: var(--primary); font-weight: 700; }}
@media (max-width: 720px) {{
  .page {{ padding: 32px 20px 64px; }}
  .nav-inner {{ padding: 0 20px; }}
  .header .title {{ font-size: 1.65rem; }}
  .content h2 {{ font-size: 1.2rem; }}
}}
@media print {{
  body {{ background: white; color: black; }}
  .nav {{ display: none; }}
  .page {{ padding: 0; max-width: 100%; }}
  .content h2, .content h3 {{ color: black; break-after: avoid; }}
  .content pre {{ background: #f5f5f4; color: black; border: 1px solid #ddd; }}
  .content code {{ background: #f5f5f4; color: #92400e; border: 1px solid #ddd; }}
  .content table {{ background: white; }}
  .content th {{ background: #f5f5f4; color: #92400e; }}
  .content tr, .content li {{ break-inside: avoid; }}
}}
</style>
</head>
<body>
<nav class="nav">
  <div class="nav-inner">
    <a href="{launcher_link}" class="back">← Painel ZX LAB</a>
    <div class="nav-meta"><span class="brand">ZX LAB</span> · {nav_meta}</div>
  </div>
</nav>
<main class="page">
  <header class="header">
    <div class="eyebrow">{eyebrow}</div>
    <h1 class="title">{title}</h1>
  </header>
  <article class="content">
{body}
  </article>
  <footer class="footer">
    Gerado por <span class="accent">Claude Code</span> · ZX LAB · {date_label}
  </footer>
</main>
</body>
</html>
"""


def _strip_first_h1(html: str) -> str:
    """Remove o primeiro <h1>...</h1> do body (já está no header)."""
    import re
    return re.sub(r"<h1>.*?</h1>\s*", "", html, count=1, flags=re.DOTALL)


def convert(
    md_path: str,
    html_path: str,
    title: str = None,
    skill: str = None,
    cliente: str = None,
    launcher_link: str = "../zxlab-aluno/index.html",
) -> None:
    from datetime import datetime
    md_text = Path(md_path).read_text(encoding="utf-8")

    if title is None:
        for line in md_text.splitlines():
            if line.startswith("# "):
                title = line[2:].strip()
                break
        if title is None:
            title = Path(md_path).stem

    md = markdown.Markdown(extensions=["extra", "tables", "sane_lists"])
    body_html = md.convert(md_text)
    body_html = _strip_first_h1(body_html)

    body_html = body_html.replace("<li>[ ] ", '<li class="task-list-item"><input type="checkbox" disabled> ')
    body_html = body_html.replace("<li>[x] ", '<li class="task-list-item"><input type="checkbox" checked disabled> ')
    body_html = body_html.replace("<li>[X] ", '<li class="task-list-item"><input type="checkbox" checked disabled> ')

    skill_label = (skill or "deliverable").replace("-", " ").upper()
    eyebrow_parts = [skill_label]
    if cliente:
        eyebrow_parts.append(cliente.upper())
    eyebrow = " · ".join(eyebrow_parts)

    nav_meta = skill_label
    date_label = datetime.now().strftime("%Y-%m-%d")

    # Resolver launcher_link relativo se possível
    try:
        launcher_abs = Path("~/zxlab-aluno/index.html").expanduser().resolve()
        html_abs = Path(html_path).expanduser().resolve()
        rel = Path("/" + str(launcher_abs).lstrip("/")).relative_to("/")
        # cálculo relativo simples via os.path.relpath
        import os
        launcher_link = os.path.relpath(launcher_abs, start=html_abs.parent)
    except Exception:
        launcher_link = str(Path("~/zxlab-aluno/index.html").expanduser())

    final = HTML_TEMPLATE.format(
        title=title,
        body=body_html,
        eyebrow=eyebrow,
        nav_meta=nav_meta,
        date_label=date_label,
        launcher_link=launcher_link,
    )
    Path(html_path).parent.mkdir(parents=True, exist_ok=True)
    Path(html_path).write_text(final, encoding="utf-8")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="MD → HTML dark theme ZX LAB")
    parser.add_argument("md_path")
    parser.add_argument("html_path")
    parser.add_argument("title", nargs="?", default=None)
    parser.add_argument("--skill", default=None, help="nome da skill (ex: diagnostico-empreendedor)")
    parser.add_argument("--cliente", default=None, help="nome do cliente/lead/aluno (opcional)")
    args = parser.parse_args()

    if not Path(args.md_path).exists():
        print(f"ERRO: arquivo MD não encontrado: {args.md_path}", file=sys.stderr)
        sys.exit(1)

    convert(args.md_path, args.html_path, args.title, args.skill, args.cliente)
    print(f"✅ HTML gerado: {args.html_path}")

# Reference — prototipar-sistema

## Mapa origem → uso → adaptação

| Arquivo origem (zxgrowth) | Trecho usado | Adaptação na skill |
|---|---|---|
| `supabase/functions/generate-prototype-plan/index.ts` | `systemPrompt` (linhas 8-68) — completo, literal | Aplicado direto pelo Claude da sessão. Input HTTP `{raw_idea_input}` → input bruto coletado no terminal. |
| `supabase/functions/generate-prototype-plan/index.ts` | User prompt linha 104: `Analise a seguinte ideia de projeto e crie um planejamento estruturado completo:\n\n${raw_idea_input}` | Mantido literal. |
| `supabase/functions/generate-vibe-coding-prompts/index.ts` | `systemPrompt` (linhas 8-52) — completo, literal | Aplicado direto. Substitui chamada HTTP. |
| `supabase/functions/generate-vibe-coding-prompts/index.ts` | User prompt linhas 76-84 — concatena `raw_idea_input` + `planning_text` | Mantido literal. |
| `supabase/functions/generate-prototype-test-plan/index.ts` | `systemPrompt` (linhas 8-97) — completo, literal incluindo emoji 🧪 | Aplicado direto. |
| `supabase/functions/generate-prototype-test-plan/index.ts` | User prompt linhas 121-129 — concatena `planning_text` + `build_prompt_text` | Mantido literal. |
| `src/hooks/usePrototyperProjects.ts` | Interface `PrototypeOutput` (linhas 14-24) — campos `planning_text`, `build_prompt_text`, `test_prompt_text`, `status: 'draft' \| 'generated' \| 'approved'` | **Adaptado** (não espelhado) no `output.json` salvo em `~/clientes/{slug}/`. Campos extras locais: `cliente`, `tipo`, `raw_idea_input`. Campos omitidos: `output_id`, `user_id` (não fazem sentido em skill local). |
| `src/hooks/usePrototyperProjects.ts` | Interface `PrototypeProject` (linhas 5-12) — `project_id`, `title`, `raw_idea_input` | `project_id` = `cliente-slug` (kebab-case). `title` = nome do cliente. Schema original aceita só `title` + `raw_idea_input` livre — **sem enumeração de `tipo`**. A enumeração `sistema/LP/app/agente-ia` é adaptação ZX LAB pra wizard interativo (não vem do schema). |
| `src/hooks/usePrototyperProjects.ts` | Fluxo `useCreatePrototyperProject` → `useGeneratePrototypePlan` → `useGenerateVibeCodingPrompts` → `useGenerateTestPlan` | Replicado linearmente: passo 3 → 4 → 5 da skill. |

## Adaptações estruturais

| Original ZX Growth | Skill local |
|---|---|
| Lovable AI Gateway (`google/gemini-3-flash-preview`) | Claude da sessão atual aplica os SYSTEM_PROMPTs diretamente |
| Supabase `prototype_outputs` table | Arquivo `~/clientes/{slug}/output.json` |
| Supabase Storage / DB rows | Arquivos `.md` em `~/clientes/{slug}/` |
| React UI tabs (Plan / Build / Test) | 3 arquivos: `prototipo-brief.md`, `prototipo-etapas.md`, `prototipo-test-plan.md` |
| HTTP error 429/402 | N/A (sessão local) |
| `status: draft \| generated \| approved` | Mantido — gravado em `output.json` |

## Defaults ZX LAB (extensão local — NÃO vem do ZX Growth original)

| Item | Original ZX Growth | Default ZX LAB (premissa Rafael) |
|---|---|---|
| Tipos de protótipo | Texto livre em `raw_idea_input` (sem enumeração — `PrototyperNew.tsx:64-79`, `usePrototyperProjects.ts:104-107`) | Wizard interativo enumera `sistema / LP / app / agente IA` pra guiar coleta |
| Stack Sistema/LP/App | Só menciona "Lovable/Cursor/Bolt" genérico em `generate-vibe-coding-prompts/index.ts:8` | Default: **Lovable + Supabase + React + Tailwind** |
| Stack Agente IA | NÃO existe no ZX Growth | Default ZX LAB: **Evolution + OmniRoute + Z-API + Python** (padrão ZX Control do Rafael) |
| Schema output | `output_id`, `user_id`, `planning_text`, `build_prompt_text`, `test_prompt_text`, `status` | **Adapta** (não espelha): adiciona `cliente`, `tipo`, `raw_idea_input`; omite `output_id`, `user_id` |
| Render HTML hi-fi | NÃO faz parte (`PrototyperWorkspace.tsx` só tem Plan/Build/Test) | Pós-processo via `huashu-design` (3 variantes) |

Estes defaults são **premissas do Rafael pra alunos ZX Control**, não vêm do ZX Growth de produção. O SYSTEM_PROMPT permanece aberto a stack alternativa se o aluno pedir.

## Integração com `huashu-design` (pós-processo ZX LAB)

> ⚠️ Integração com `huashu-design` é extensão ZX LAB. NÃO existe no ZX Growth original — ZX Growth gera só os 3 prompts (plan/build/test), sem materializar HTML. Workflow complementar do Rafael.

Skill existente: `~/.claude/skills/huashu-design/SKILL.md`. É o renderizador oficial ZX LAB de protótipo HTML hi-fi 60fps, com:
- Junior Designer workflow (assumptions + reasoning + placeholder iterativo)
- Anti-AI-slop checklist
- React + Babel best practices
- Variantes de design (Tweaks)
- Playwright validation
- Export MP4/GIF 60fps

**Como `prototipar-sistema` invoca `huashu-design`:**

1. Após gerar os 3 markdowns (brief, etapas, test plan), perguntar ao aluno se quer renderizar HTML.
2. Se sim, invocar `huashu-design` via Skill tool com prompt:
   ```
   Renderize protótipo HTML hi-fi pro cliente {nome} ({tipo: sistema/LP/app/agente-ia}).
   Brief: ~/clientes/{slug}/prototipo-brief.md (telas/fluxos/dados/integrações)
   Etapas: ~/clientes/{slug}/prototipo-etapas.md (vibe coding steps)
   Stack já decidida — siga literal.
   Gerar 3 variantes paralelas (Information Architecture / Motion Poetics / Experimental Vanguard).
   Salvar em ~/clientes/{slug}/prototipos-html/ (variante-1.html, variante-2.html, variante-3.html).
   ```
3. `huashu-design` toma controle, gera as 3 variantes, aluno escolhe 1, refina.

**Por quê 3 variantes:** padrão ZX LAB obrigatório (ver memória `feedback_3_prototipos_huashu_antes_lp.md`). Nunca reskin direto — sempre 3 huashu antes pra economizar 2h+ de retrabalho.

## Estrutura de pastas resultante

```
~/clientes/{cliente-slug}/
├── raw_idea_input.md          (passo 2 — input bruto do aluno)
├── prototipo-brief.md         (passo 3 — planning_text)
├── prototipo-etapas.md        (passo 4 — build_prompt_text)
├── prototipo-test-plan.md     (passo 5 — test_prompt_text)
├── output.json                (schema PrototypeOutput espelhado)
└── prototipos-html/           (passo 6 — gerado por huashu-design)
    ├── variante-1.html        (Information Architecture)
    ├── variante-2.html        (Motion Poetics)
    └── variante-3.html        (Experimental Vanguard)
```

## Notas operacionais

- **Idioma**: SYSTEM_PROMPTs originais são em PT-BR — manter.
- **Premissas**: o prompt PLANO já obriga marcar assumptions como "Premissa". Não preencher buracos sem flagar.
- **MVP focus**: a regra `Foque no MVP, não em features futuras` é literal — não expandir.
- **5-12 etapas**: limite hard-coded no prompt VIBE CODING. Não gerar mais nem menos.
- **Schema status**: começar em `draft`, marcar `generated` após os 3 outputs, `approved` só quando aluno confirma e libera pra huashu.

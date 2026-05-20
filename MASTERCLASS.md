# MasterClass — Setup 8: Skills da Agência IA + Lead Machine Lite no seu Mac

Roteiro da aula em vídeo gravada pelo Rafael. Cortes referenciados por timestamp + GUID Bunny (preenchido após upload).

## Bunny Library

`Library ID: 629692`

## Estrutura geral (duração estimada: 50min)

1. **Hook de abertura** (00:00 — 00:15)
2. **Visão geral do setup** (00:15 — 00:06:00)
3. **Demo da instalação** (00:06:00 — 00:11:00)
4. **Walkthrough das 4 etapas** (00:11:00 — 00:45:00)
5. **Fechamento + próximos passos** (00:45:00 — final)

## Cortes (atualizar com BUNNY_GUID após upload)

| # | Título | Start | End | Bunny GUID |
|---|--------|-------|-----|------------|
| 1 | Visão geral das 5 ferramentas + Lead Machine | 00:00 | MM:SS | `BUNNY_GUID_S8_C1` |
| 2 | Instalação com install.sh (demo ao vivo) | MM:SS | MM:SS | `BUNNY_GUID_S8_C2` |
| 3 | /diagnostico-empreendedor — fluxo completo | MM:SS | MM:SS | `BUNNY_GUID_S8_C3` |
| 4 | /simulador-vendas + /analise-call em ação | MM:SS | MM:SS | `BUNNY_GUID_S8_C4` |
| 5 | /prototipar-sistema + /criar-orcamento | MM:SS | MM:SS | `BUNNY_GUID_S8_C5` |
| 6 | Lead Machine Lite — LP pública + dashboard + tunnel | MM:SS | MM:SS | `BUNNY_GUID_S8_C6` |
| 7 | Casos de uso reais + próximos passos | MM:SS | MM:SS | `BUNNY_GUID_S8_C7` |


## Roteiro

### Hook (00:00 — 00:15)

> Bora dar ao seu Mac os superpoderes de IA que grandes plataformas cobram R$500+/mês?

### Visão geral (00:15 — 00:06:00)



**Pontos a tocar:**
- 5 skills que portamos do ZX Growth: ferramentas que a plataforma usa com clientes reais
- Lead Machine Lite: o coração do ZX Lead Machine adaptado pra Mac local
- Install.sh master: 1 comando, tudo instalado, pronto pra usar
- Claude Code como interface: sem navegador, sem SaaS, direto no terminal


### Demo da instalação (00:06:00 — 00:11:00)

Demonstrar o aluno abrindo terminal, executando `git clone` + `claude`, e o Claude começando o setup.

**Frases-chave:**
- "Olha como é simples — você clona, abre o Claude, e ele faz tudo."
- "Não precisa digitar comando nenhum a mais — o Claude conduz."

### Walkthrough das etapas (00:11:00 — 00:45:00)


#### Etapa 1 — Instalar 5 Skills Bloco A

- **O que mostra:** Copia skills pra ~/.claude/skills/
- **Frase-chave:** "Aqui o setup copia skills pra ~/.claude/skills/"
- **Duração estimada:** 2min


#### Etapa 2 — Instalar Lead Machine Lite

- **O que mostra:** FastAPI + dashboard + LaunchAgent + cloudflared
- **Frase-chave:** "Aqui o setup fastapi + dashboard + launchagent + cloudflared"
- **Duração estimada:** 2min


#### Etapa 3 — Configurar ANTHROPIC_API_KEY

- **O que mostra:** Aluno insere chave no .env do Lead Machine
- **Frase-chave:** "Aqui o setup aluno insere chave no .env do lead machine"
- **Duração estimada:** 2min


#### Etapa 4 — Smoke test

- **O que mostra:** Abre /diagnostico-empreendedor pra confirmar
- **Frase-chave:** "Aqui o setup abre /diagnostico-empreendedor pra confirmar"
- **Duração estimada:** 2min



### Fechamento (00:45:00 — final)

> Pronto! Setup 8 instalado. Próxima semana a gente solta o Setup 9. Bons agentes!

**CTA único:**
> "Qualquer dúvida fala no grupo. Próximo setup em ~7 dias."

NUNCA mencionar preço, White Label, versão anterior, ou outro produto.

---

## Upload checklist

Após gravar e cortar:

- [ ] Cortes salvos em `~/Movies/setup8-cortes/`
- [ ] Upload Bunny: `/cortar-aula-setup --gravacao /path/setup8.mp4 --setup 8`
- [ ] BUNNY_GUIDs preenchidos nesta tabela (substituir `BUNNY_GUID_S8_C*`)
- [ ] Commit + push do MASTERCLASS.md atualizado
- [ ] Painel S8-0 das áreas de membros atualizado com GUIDs reais
- [ ] Re-deploy CF Pages das turmas-alvo
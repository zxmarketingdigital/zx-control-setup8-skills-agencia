# MasterClass — Setup 8: Agentes de Vendas e Captura de Leads (ZX Growth + ZX Lead Machine)

Roteiro da aula em vídeo gravada pelo Rafael. Cortes referenciados por timestamp + GUID Bunny (preenchido após upload).

## Bunny Library

`Library ID: 629692`

## Estrutura geral (duração estimada: 60min)

1. **Hook de abertura** (00:00 — 00:15)
2. **Visão geral do setup** (00:15 — 00:06:00)
3. **Demo da instalação** (00:06:00 — 00:11:00)
4. **Walkthrough das 4 etapas** (00:11:00 — 00:38:00)
5. **Case de estudo Sabor Carioca — como NÃO vender** (00:38:00 — 00:54:00) ← novo
6. **Fechamento + próximos passos** (00:54:00 — final)

## Cortes (atualizar com BUNNY_GUID após upload)

> ✅ **GUIDs reais preenchidos** — Aula gravada em 20/Mai/2026, 7 cortes únicos no Bunny library 629692. As linhas C8 e C9 da tabela são placeholders documentais que apontam pro vídeo principal (o conteúdo desses blocos foi integrado naturalmente na aula completa, não cortado separado).
>
> Áreas de membros v2.0 e v3.0 já estão deployadas com os GUIDs reais nos painéis s8-0 e s8-5.

| # | Título | Start | End | Bunny GUID |
|---|--------|-------|-----|------------|
| 1 | Visão geral das 6 ferramentas + Lead Machine | 00:00 | MM:SS | `603e5979-3851-4407-95ed-fffd73229386` |
| 2 | Instalação com install.sh (demo ao vivo) | MM:SS | MM:SS | `0729a0ff-31a1-416d-8f88-284e25fb15a9` |
| 3 | /diagnostico-empreendedor — fluxo completo | MM:SS | MM:SS | `ec90e515-1e9b-4340-882b-3a02e2c30877` |
| 4 | /simulador-vendas + /analise-call em ação | MM:SS | MM:SS | `e14388aa-a63f-4771-9f41-001fb6e3f952` |
| 5 | /prototipar-sistema + /criar-orcamento | MM:SS | MM:SS | `afa1f569-14c5-42ea-ae73-e7425dc0fb7c` |
| 6 | Lead Machine Lite — LP pública + dashboard + tunnel | MM:SS | MM:SS | `12a0f835-ea34-4960-93e8-89750e02337a` |
| 7 | **CASE Sabor Carioca — 5 erros + frases-modelo** | MM:SS | MM:SS | `81c47449-3978-4f5d-9be9-391e2df2b92b` |
| 8 | /pre-call-checklist + drill `--focus` | MM:SS | MM:SS | `603e5979-3851-4407-95ed-fffd73229386` |
| 9 | Casos de uso reais + próximos passos | MM:SS | MM:SS | `603e5979-3851-4407-95ed-fffd73229386` |


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



### Case de estudo — Sabor Carioca (00:38:00 — 00:54:00)

**Por que esse bloco existe:** A simulação de venda do restaurante Sabor Carioca (cliente fictício, simulada com `/simulador-vendas --difficulty hard`) gerou um score de 28/100 e expôs os **5 erros mais comuns de aluno iniciante de Agência IA**. Mostrar o erro concreto + a frase-modelo certa é mais didático do que ensinar "boas práticas" abstratas.

> ⚠️ **Aviso sobre os valores R$ deste case:** Os números mencionados abaixo (R$ 1.500 setup, R$ 300/mês, R$ 4.000 perda mensal) são **APENAS exemplos didáticos do treino Sabor Carioca** — gerados por `/criar-orcamento` para um cliente fictício específico em maio/2026. **NÃO são tabela de preços oficial da ZX LAB nem compromisso comercial com o aluno ou cliente final.** Quando você for vender pro seu cliente real, rode `/criar-orcamento` no contexto dele e use os valores que a skill gerar — eles vão variar por escopo, vertical e ROI. A "garantia de 30 dias sem multa" mencionada na frase-modelo é um compromisso ALUNO ↔ CLIENTE DO ALUNO sugerido como técnica de vendas, NÃO compromisso da ZX LAB com ninguém.

**Frases-chave:**

> "Antes de mostrar as skills funcionando bem, eu quero te mostrar a simulação onde EU mesmo errei feio — score 28 de 100 — pra você não cometer os mesmos 5 erros."

#### Os 5 erros (mostrar transcrição anônima na tela)

1. **Desvio de preço 3x** — cliente perguntou preço, vendedor desviou. Cliente perguntou de novo, vendedor desviou. Na terceira pergunta, cliente já interpretou como má-fé.
   - Frase-modelo: *"Maria, vou direto: setup R$ 1.500 + R$ 300/mês. Vocês perdem R$ 4 mil/mês — paga em 11 dias. Agora deixa eu mostrar exatamente o que entrega."*

2. **Subcobrou R$ 500** — vendedor improvisou "R$ 1.000" quando a proposta correta era R$ 1.500. Perdeu margem antes mesmo de negociar.
   - Anti-padrão: *"Considerando que perde R$ 4 mil, seria justo cobrar R$ 1.000?"* (frase como pergunta, baixa o piso).
   - Antídoto: `/pre-call-checklist` — preço memorizado item 4.

3. **Omitiu mensalidade** — cliente perguntou explícito "tem mensalidade ou pagamento único?" e vendedor não tinha resposta clara. Se contrato chegasse com R$ 300/mês, virava processo.
   - Antídoto: Skill `/criar-orcamento` agora força recorrência no header do MD, não enterra nos detalhes.

4. **Inventou "vários cases"** — cliente perguntou case real de restaurante com nome e telefone. Vendedor desviou pra "pesquisa de mercado". Credibilidade detonada na primeira pergunta crítica.
   - Frase-modelo: *"Maria, não vou te enrolar — pra restaurante a gente não tem volume de cases ainda. O que ofereço é garantia de cancelamento sem multa nos primeiros 30 dias. Você vê o resultado no próprio número."*

5. **Zero discovery** — cliente sinalizou "Carlos ainda nem me explicou o que esse robô faz". Vendedor seguiu monologando.
   - Antídoto: 2 perguntas obrigatórias antes de qualquer pitch: *"Quantas mensagens por dia chegam?"* e *"Quem responde quando a atendente falta?"*

#### Drill prático (mostrar ao vivo)

```bash
# Treinar SÓ resposta de preço sem desvio
/simulador-vendas --focus desvio-preco --difficulty hard

# Treinar SÓ apresentação sem case real
/simulador-vendas --focus sem-case --difficulty hard

# Antes da call real, rodar o checklist
/pre-call-checklist sabor-carioca-carlos-souza
```

**Tarefa de casa pro aluno:**
- Rodar `/simulador-vendas --focus desvio-preco` 3 vezes seguidas — score só fechado quando passar de 70/100.
- Gravar 1 call real e rodar `/analise-call` — comparar as Risk Flags 🔴 com o gabarito do Sabor Carioca.

### Fechamento (00:54:00 — final)

> Pronto! Setup 8 instalado. 6 skills + Lead Machine + banco de objeções + checklist pré-call. Próxima semana a gente solta o Setup 9. Bons agentes!

**CTA único:**
> "Qualquer dúvida fala no grupo. Próximo setup em ~7 dias."

NUNCA mencionar preço, White Label, versão anterior, ou outro produto.

---

## Upload checklist

Após gravar e cortar:

- [ ] Cortes salvos em `~/Movies/setup8-cortes/`
- [ ] Upload Bunny: `/cortar-aula-setup --gravacao /path/setup8.mp4 --setup 8`
- [x] BUNNY_GUIDs preenchidos na tabela acima (7 GUIDs únicos do Bunny library 629692, gravação 20/Mai/2026)
- [ ] Commit + push do MASTERCLASS.md atualizado
- [ ] Painel S8-0 das áreas de membros atualizado com GUIDs reais
- [ ] Re-deploy CF Pages das turmas-alvo
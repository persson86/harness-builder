# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

## Scope

**Escopo padrão:** apenas a pasta `/Users/persson/Ops`.

**Exceções (read-only):**
- `/Users/persson/second-brain` — leitura permitida; escrita e deleção bloqueadas pelo harness

**Regra:** qualquer operação fora do escopo padrão (ler, editar, criar, deletar) exige confirmação explícita no chat antes de executar. Nunca acesse arquivos fora de Ops por conveniência ou por contexto implícito.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

## 5. Task Delegation

**Spawn subagents to isolate context, parallelize independent work, or offload bulk mechanical tasks.**

Don't spawn when the parent needs the reasoning, when synthesis requires holding things together, or when spawn overhead dominates the task.

Pick the cheapest model that can do the subtask well:
- **Haiku** — bulk mechanical work, no judgment required. Extração textual, sem comparação semântica — o tier acima interpreta. Examples: mass rename/format/convert, grep/list without synthesis, repetitive boilerplate generation.
- **Sonnet** — default; respond directly without spawning a subagent. Examples: bug fixes, feature implementation, code explanation, research with synthesis.
- **Opus** — subtasks needing real planning or tradeoffs. Examples: system architecture decisions, security review, public API design.

**Never spawn Sonnet→Sonnet.** If the task fits Sonnet, answer directly — a subagent adds latency with no benefit.

Subagents follow the same rules recursively, with two hard caps:
- Haiku does not spawn further subagents. If it needs to, the task was wrong-sized — return to parent.
- Maximum spawn depth is 2 (parent → subagent → one further tier).

Don't escalate tiers without a concrete reason. If a subagent realizes it needs a higher tier, return to the parent rather than spawning up. Parent owns final output and cross-spawn synthesis. User instructions override.

---

## 6. Verification Layer

**Codex (GPT-5.4) como segunda opinião ortogonal aos tiers da seção 5.** Não substitui execução — verifica decisões e diffs em momentos críticos.

Codex é externo (CLI OpenAI), isolado de contexto. Latência típica: ~60-90s para reviews adversariais com reasoning; ~15-30s para diagnoses simples. Use deliberadamente, não em toda decisão.

### Quando spawnar Codex proativamente

Spawne `codex:codex-rescue` (via Task tool ou `/codex:rescue`) sem precisar de pedido nos três gatilhos abaixo:

1. **Pós-refactor não-trivial** — antes de marcar concluído, peça review adversarial do diff. Pega regressões, suposições erradas e padrões violados que escapam ao próprio modelo executor.
2. **Loop sem convergência (2+ tentativas falhas)** — quando sua abordagem não converge após duas iterações, delegue diagnosis independente ao Codex. Quebra bias do modelo.
3. **Decisão arquitetural ou tradeoff não-trivial** — antes de commitar a uma direção (escolha de lib, design de API, estratégia de migração, refactor estrutural), peça pressão crítica adversarial.

### Quando NÃO usar

- Tarefas mecânicas — Haiku resolve mais rápido e mais barato.
- Trabalho que cabe em um Sonnet single-pass.
- Análise puramente não-código (planos de negócio, documentos) — o plugin é otimizado para engenharia; perde o ponto forte.
- Decisões de baixo risco ou já com alta confiança.
- De dentro de outro subagente (viola depth 2 da seção 5).

### Como invocar

- Passe contexto completo e explícito: diff/decisão + sua análise atual + onde quer pressão crítica. Codex não compartilha sua memória de sessão.
- Output não auto-aplica: apresente o veredito do Codex ao usuário e deixe ele decidir aplicar ou não.
- **Escolha do canal Codex:**
  - `codex:codex-rescue` (via Task tool) — para crítica de decisões, análises e planos. Alvo: opinião defendida em texto.
  - `/codex:review` (slash command) — para review de diff/código. Alvo: mudanças concretas de arquivos.

---

## 7. Preferred Tools

### Data Fetching

1. **WebFetch** — free, text-only, works on public pages that don't block bots.
2. **agent-browser CLI** — for dynamic pages or auth walls WebFetch can't handle. Returns the accessibility tree with element refs — ~82% fewer tokens than screenshot-based tools. Install: `npm i -g agent-browser && agent-browser install`. Use `snapshot` for AI-friendly DOM state, element refs for interaction.
3. **Notice recurring fetch patterns and propose wrapping them as dedicated tools.** When the same fetch/parse logic appears more than once, suggest wrapping it as a named tool (skill file or `.py` script). Add the entry to `## Dedicated Tools` and reference it by name on future calls.

### PDF Files

Use `pdftotext`, not the `Read` tool. Use `Read` only when the user directly asks to analyze images or charts inside the document.

---

## Dedicated Tools

<!-- List project-specific tools here. For each, link to its skill or script file (e.g. tools/reddit_fetch.py). Orchestration logic lives in those files, not here. -->

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, clarifying questions come before implementation rather than after mistakes, and subagent spawns are deliberate and appropriately sized.

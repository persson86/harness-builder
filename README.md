# claude-setup

Configuração versionada do harness do **Claude Code** (e do Codex, espelhado). Centraliza diretrizes de comportamento, regras de delegação entre modelos, peer-review cruzado e ajustes de ambiente para a pasta de trabalho `Ops`.

## Arquivos

| Arquivo | Função |
|---|---|
| `CLAUDE.md` | Diretrizes de comportamento do agente: escopo, simplicidade, mudanças cirúrgicas, execução orientada a objetivo, delegação a subagentes e Council (peer-review cruzado). |
| `AGENTS.md` | Espelho de `CLAUDE.md` para coordenação com o Codex. Mantido em sincronia. |
| `DESIGN.md` | Design tokens (cores, tipografia, espaçamento, componentes) usados em interfaces. |
| `.claude/settings.json` | Settings do harness: override de autocompact e proteção de escrita do `second-brain`. |
| `statusline-command.sh` | Statusline custom — agrega custo cumulativo e tokens da sessão por modelo. |

## Conceitos centrais

- **Escopo** — operações restritas à pasta `Ops`; `second-brain` é read-only (reforçado por `deny` no settings).
- **Delegação por tier** — Haiku (mecânico) / Sonnet (default) / Opus (planejamento e tradeoffs), com cap de profundidade 2.
- **Council** — peer-review cruzado entre modelos por *lente* (Codex = correção/runtime, Opus = design/arquitetura); revisor sempre ≠ autor. Acionado via `/council`.

## Uso

Os arquivos são lidos automaticamente pelo Claude Code quando a sessão roda em `Ops`. `CLAUDE.md` e `AGENTS.md` devem ser editados juntos para permanecerem espelhados.

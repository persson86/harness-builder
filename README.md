# claude-setup

Configuração versionada do harness do **Claude Code** (e do Codex, espelhado). Centraliza diretrizes de comportamento e ajustes de ambiente para a pasta de trabalho `Ops`.

## Arquivos

| Arquivo | Função |
|---|---|
| `CLAUDE.md` | Diretrizes de comportamento do agente: escopo, simplicidade, mudanças cirúrgicas, execução orientada a objetivo e ferramentas preferidas. |
| `AGENTS.md` | Espelho de `CLAUDE.md` para coordenação com o Codex. Mantido em sincronia. |
| `DESIGN.md` | Design tokens (cores, tipografia, espaçamento, componentes) usados em interfaces. |
| `.claude/settings.json` | Settings do harness: override de autocompact e proteção de escrita do `second-brain`. |
| `statusline-command.sh` | Statusline custom — agrega custo cumulativo e tokens da sessão por modelo. |

## Conceitos centrais

- **Escopo** — operações restritas à pasta `Ops`; `second-brain` é read-only (reforçado por `deny` no settings).
- **Modelos por menção explícita** — não há regras de delegação automática; pedir "Valide com Opus" / "Revise com Codex" / "Use Fable" spawna o modelo citado diretamente (Agent tool ou plugin Codex).

## Uso

Os arquivos são lidos automaticamente pelo Claude Code quando a sessão roda em `Ops`. `CLAUDE.md` e `AGENTS.md` devem ser editados juntos para permanecerem espelhados.

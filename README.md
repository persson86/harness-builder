# harness-builder

Configuração versionada de harness para agentes de código: diretrizes de comportamento, settings, statusline e orientação de design.

## Funcionalidades

- **Configurações Claude Code** — `CLAUDE.md` com diretrizes de comportamento do agente (pensar antes de codar, simplicidade, mudanças cirúrgicas, execução orientada a objetivo, ferramentas preferidas) e `.claude/settings.json` com settings do harness (autocompact, permissions).
- **Configurações Codex** — `AGENTS.md`, espelho do `CLAUDE.md` mantido em sincronia, para o Codex operar sob as mesmas diretrizes.
- **Statusline Claude Code** — `statusline-command.sh`: custo cumulativo e tokens da sessão por modelo (formato K/M), uso do rate limit da janela de 5h e countdown do reset.
- **Orientação de design** — `design/`: tokens de design (`DESIGN.md` — cores, tipografia, espaçamento, componentes), acessibilidade WCAG, animação, voz e tom, regras de escrita e demo visual (`index.html`).

## Uso

Os arquivos são lidos automaticamente pelo Claude Code quando a sessão roda na pasta do repo. `CLAUDE.md` e `AGENTS.md` devem ser editados juntos para permanecerem espelhados.

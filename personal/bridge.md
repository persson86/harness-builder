# Bridge Builder ↔ Thinker (pessoal)

Convenção pessoal que liga este workspace de desenvolvimento ao vault second-brain
(harness-thinker). **Fora do payload** — não é instalada em projetos de terceiros e
não é mencionada no README. Versionada aqui; ativada na máquina via import no bloco
local-scope de `~/Builder/CLAUDE.md` (preservado em todo `install.sh --update`).

## Direção primária (ativa): Builder → Thinker, via queue

Padrões descobertos na execução têm mais valor quando indexados. Quando um padrão
reutilizável, aprendizado de postmortem ou decisão de design emergir num projeto, o
Builder **escreve o insight no queue do vault** e avisa em uma linha o que registrou:

- Arquivo: `/Users/persson/Thinker/second-brain/queue/$(date +%s)-nota-<slug>.md`
- Conteúdo: markdown com o insight (contexto curto + o aprendizado em si).
- Só insights de verdade — não toda sessão. O vault acumula experiência vivida, não
  conselhos abstratos.

O Builder tem permissão de escrita **apenas** em `queue/` (deny rules em
`~/Builder/.claude/settings.json`); nunca escreve em wiki/raw/harness nem deleta/move
no vault. O input só vira conhecimento quando o usuário processa a fila com `/feed`
numa sessão Thinker (nota → INBOX, ou INGEST se merecer página).

## Direção secundária (parada): Thinker → Builder

Não ativada — decisão de focar numa direção. Documentada em
`harness-thinker/personal/bridge.md`.

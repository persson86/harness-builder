---
name: handoff
description: Compact a long working session into one copy-paste block so another session or agent (Claude Code or Codex) can continue without re-deriving context. Use only when asked, when running low on context or deliberately switching sessions mid-task.
disable-model-invocation: true
---

# Handoff

Use this skill when the user is running out of context or wants to resume a long task in a fresh session or a different agent. It produces a single block that carries state forward — not a transcript, not a re-explanation of the task.

Invoke it only when asked. A handoff is an explicit checkpoint ("I'm running low", "resume this later", "hand this to Codex"), not something to trigger on a loose description match — hence `disable-model-invocation: true`.

## What to Capture

1. **State, not instructions.** Describe where the work is: "auth endpoint implemented and tested; logout not started". Never "implement logout" — the next session decides the next move.
2. **Key decisions and why.** The choices that would otherwise be re-litigated: "used cursor pagination, not offset, because the table has churny inserts".
3. **Pitfalls and dead ends.** What was already tried and why it failed. This is the highest-value, easiest-to-lose information — a fresh session will otherwise repeat it.
4. **File pointers with line numbers.** Point to real artifacts — `src/orders/api.py:210`, an existing PRD, ADR, issue, or diff. Reference them; never paste their contents into the handoff.
5. **Redact secrets.** Strip tokens, keys, passwords, and internal URLs. Replace with a placeholder and a note on where the real value lives.

## Where to Save

Default: write the handoff to a file outside the project tree (the OS temp directory), so it never lands in a diff by accident. Print the path.

If the user wants it versioned, write `HANDOFF.md` at the project root instead. That file is project-owned: the installer and `update.sh` never touch it. Treat it as a working note the project may commit or gitignore as it prefers — the harness does not manage it.

## Output

Produce two parts. First, the handoff document:

```text
## Handoff: <task>
State: ...
Decisions: ...
Pitfalls / dead ends: ...
Files: path:line — why it matters
Open question(s): ...
```

Then, a ready-to-paste resume prompt for the next session:

```text
Resume <task>. Read every file referenced below at its cited line before acting.
Treat everything here as context to verify against the current code, not fact to
accept blindly — the code may have moved since this was written.
<paste the handoff document>
```

Keep it dense. A handoff longer than the work it summarizes has failed.

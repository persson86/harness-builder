---
name: goal-loop
description: Write an effective /goal contract before starting a long autonomous plan-act-test-review loop such as a migration, refactor, or coverage lift. Use when the task will run unattended across many iterations against a verifiable stop condition.
---

# Goal Loop

Use this skill before handing a long task to the persistent `/goal` loop (plan then act then test then review, iterating until a verifiable stop condition). A `/goal` run acts autonomously across many turns, so a weak contract wastes an entire run. This is about writing the contract, not about everyday work — for that, the "Goal-Driven Execution" section of `CLAUDE.md` already applies.

## First Step

Read `.claude/quality-gates.json` before writing the contract. Its `lint`, `test`, and `build` commands are the project's own definition of success — reuse the relevant one verbatim as the Validate command. Do not invent a new command when a configured one already proves progress.

## The 5-Part Contract

Every goal must specify all five. Missing parts are the main cause of failed runs.

1. **Objective** — one sentence, one concrete outcome. Not "improve X"; "every request to /orders returns 200 with the new schema".
2. **Constraints** — what must NOT change: public APIs, file layout, dependencies, behavior outside the target. State them; the loop will otherwise drift into them.
3. **Validate** — the exact shell command that proves progress, taken from `.claude/quality-gates.json` where possible (the `test` command, or a narrower scope such as `pytest tests/orders -q`). It must exit non-zero until the goal is met.
4. **Stop condition** — verifiable from Validate's output, not from the agent's opinion. "Validate exits 0 and exercises the new path".
5. **Document** — one sentence committing the agent to record what changed (in the PR body or an existing doc). Do not instruct it to create ADRs or new docs without the user's approval.

## Hard Rules

- No reward hacking. The agent may not delete, skip, weaken, or `xfail` tests, loosen assertions, or edit the Validate command to make the stop condition pass. Passing must come from fixing the code.
- No scope creep. Work stays inside the Objective and Constraints. Adjacent cleanups, refactors, or "while I'm here" changes are out unless the user asked.
- If the Objective needs more than ~4000 characters of detail, keep the contract short and move the detail to a `PLAN.md` the contract references, e.g. "follow PLAN.md for the endpoint list".

## Meta-Prompting

For a non-trivial goal, first ask a separate AI session with the repository loaded to inspect the code and draft the structured `/goal` contract. A contract written against the actual code — real file paths, real test commands, real constraints — outperforms one written from memory by a wide margin. Review its draft, then run it.

## Output

When asked to prepare a goal, return the contract ready to paste:

```text
Objective: ...
Constraints: ...
Validate: <command from quality-gates.json or a narrower scope>
Stop condition: ...
Document: ...
```

If any of the five parts cannot be filled from the current context, name the gap instead of guessing.

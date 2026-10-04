---
name: integration-card
description: Create or update docs/integrations/<service>.md before calling an external API or paid service for the first time, before any paid or bulk run, and after any surprise from that service (unexpected cost, async behavior, missing data, rate limit). Use when code is about to integrate, call in a loop, or spend credits on a third-party API.
---

# Integration Card

An integration card is the project's single page of truth about one external service: what each call costs, what it actually does, and where the code enforces the limits. It is written once by whoever understands the service best and read by every later executor, including cheaper models.

A card is documentation. It does not stop a bad run by itself. The protection lives in code — a budget cap, a spend ledger, a registry of pending asynchronous requests, a stop condition — and the card points to it by `file:line`. A card whose gate section points nowhere means the service is not ready for paid or bulk use.

## When to Write or Update

- Before the first call to a service from this project.
- Before any paid run or any loop over more than one call.
- After any surprise: cost above estimate, a request that returned "accepted" but no data, a field that was always empty, a rate limit, a silent partial result. Add it under Pitfalls with date and evidence.

## Sources, in Order

1. Official documentation and pricing pages. Record URL and the date you read them.
2. The project's own evidence: ledgers, logs, earlier responses already on disk.
3. Minimal probes: the fewest calls that confirm the behavior you cannot read in the docs, within the budget the user authorized. A probe that spends money needs the user's explicit OK first. One call may not exercise an async cycle end to end; plan the probe around the cycle, not around a fixed count.

Never paste credentials, tokens, or private endpoints into the card. Point to where they are configured.

## Card Template

Write to `docs/integrations/<service>.md`:

```markdown
# <Service>

Last verified: YYYY-MM-DD · Official docs: <url> · Pricing: <url>

## Cost
Unit and price (and conversion to the project currency, when billing differs). Cost per call type actually used.

## Endpoints in use
For each: purpose; sync or async; if async, how and when the result is fetched and what happens if it never is; pagination; idempotency (is a retry billed twice?); what "fresh data" means.

## Limits
Rate, quota, batch size, geography, data the service does not return.

## Tested recipes
Minimal call and the observed result, with date. Reproducible without secrets in the text.

## Pitfalls
One line per surprise: date, what happened, evidence path, what changed afterwards.

## Execution gate
Where the code enforces each item (file:line), or "missing":
- Budget cap and who authorizes it
- Spend ledger
- Pending async requests registry and the recapture step
- Stop condition and dry-run count before spending

## Open questions
What is still unverified.
```

## Rules

- State, not intent: write what the service does and what the code enforces, not plans.
- Separate documented behavior from observed behavior; when they disagree, record both with dates.
- Keep it short. Detail that only matters to one script belongs in that script's comments.
- When a cheaper model will run the integration, it reads the card before the first call and stops if any gate line says "missing".

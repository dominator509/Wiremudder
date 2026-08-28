# Performance

WireMudder protects your gameplay with measured budgets and graceful
degradation. The performance constitution (SPEC-004) is binding: P0 and P1
latency budgets must be met, and no optional system may regress them.

## Priority Rings

Work is scheduled by priority. The manual gameplay path (P0) always wins.
Optional systems (AI, voice, renderer, telemetry) run at lower priority and
degrade first under load (WM-FEAT-0239).

## Budgets

Scripts, triggers, aliases, timers, macros, packages, and AI requests run
with measured budgets. When a budget is exceeded, the client records a
slow-offender diagnostic and keeps playing (WM-SPEC-008-R02).

## Queues

Bounded queues protect the client from overload. When a queue is full,
new events are dropped or coalesced according to the documented policy
(SPEC-004). The drop/coalesce behavior is recorded in telemetry
(SPEC-026-R04).

## Degradation

Optional systems degrade gracefully: if the AI provider is slow, the
renderer is behind, or the voice system fails, the terminal keeps working.
You can disable any optional system without affecting manual gameplay.

## What Performance Does Not Do

Performance tuning never weakens a security boundary, never skips a
permission check, and never hides a real failure.

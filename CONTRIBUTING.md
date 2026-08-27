# Contributing to WireMudder

## Start

Read `AGENTS.md`, the active ExecPlan, the current upstream instructions, and the relevant upstream skill before editing. Work from repository evidence, not memory.

## Branch and Commit

Use one Graphlock node and one milestone at a time. Commit format is `[EP-XXX][Mk] imperative summary`. Do not force push. AI-assisted upstream contributions follow the currently verified Mudlet policy and require human testing and sign-off; an agent never fabricates a sign-off.

## Scope

Change only static expected paths and approved discovered paths. No broad formatting, cleanup, dependency swap, rename, source move, or architecture change outside the plan.

## Code

Follow current Mudlet Qt/C++ conventions in inherited integration code. Keep the bridge minimal. Rust code follows repository-pinned formatting, lint, error, and unsafe-code policy established by EP-005. Comments explain why and cite `WM-ARCH-XXX` or requirement IDs where the constraint is not obvious.

## Tests and Documentation

Update feature and requirement traceability, add independent tests, run targeted then broad gates, document failure and rollback, and update user or developer docs for visible behavior.

## Review

Review compatibility, source evidence, upstream divergence, authority, privacy, secrets, command safety, routing, performance, accessibility, migration, failure, observability, license, supply chain, and release claims. A passing build is insufficient.

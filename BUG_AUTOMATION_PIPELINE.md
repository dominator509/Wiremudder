# WireMudder Bug Automation Pipeline

## Goal

Support low-cost, privacy-safe diagnosis and future bounded remediation without allowing an agent to invent a reproduction, weaken a gate, or claim an unrun result.

## States

`intake`, `redact`, `deduplicate`, `reproduce`, `diagnose`, `plan`, `patch`, `targeted-verify`, `broad-verify`, `independent-review`, `canary-recommendation`, `done`, and `blocked`.

## Required Evidence

Issue summary, sanitized logs, stable fingerprint, affected versions and platforms, priority ring, reproduction command or evidence-backed explanation, source paths and symbols, hypotheses, attempted diffs, tests, performance and privacy impact, rollback, and release recommendation.

## Rules

- Reproduce before patch when feasible.
- Do not start from raw user transcripts or secrets.
- Scope the patch to the owning subsystem and expected-file fence.
- P0/P1 defects require performance review.
- Privacy, AI, voice, routing, secrets, package, import, update, or diagnostic defects require security or privacy review.
- Add a regression test or benchmark.
- Run independent review against the accepted specification and oracle.
- Never edit a gate to satisfy code.
- Bounded retries end in DONE or a complete BLOCKED report.
- Autonomous stable release is forbidden.

## Severity

Critical includes data loss, profile or secret corruption, unsafe command send, emergency-stop failure, credential exposure, sandbox escape, hidden microphone capture, updater signature bypass, or silent route fallback. Error, warning, info, and debug classifications follow the event schema in SPEC-019.

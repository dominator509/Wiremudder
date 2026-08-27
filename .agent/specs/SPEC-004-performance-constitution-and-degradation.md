# SPEC-004: Performance Constitution and Degradation

## Status

Accepted blueprint specification.

## Goal

Protect raw text gameplay with priority rings, bounded queues, budgets, isolation, metrics, and deterministic degradation for every optional subsystem.

## Canonical Terms

P0, P1, P2, P3, P4, bounded queue, backpressure, degradation, budget, quarantine.

## Required Behavior

WM-SPEC-004-R01: P0 contains connection state, socket delivery into the inherited client, terminal output, manual input, command send, and emergency stop and never waits on optional work.

WM-SPEC-004-R02: P1 contains protocol parsing, triggers, aliases, timers, macros, command safety, and bounded gameplay logic and cannot stall P0.

WM-SPEC-004-R03: P2 contains mapper assistance, hot memory, quest, tactical, context distillation, and AI suggestions and may lag, snapshot, reduce frequency, or pause.

WM-SPEC-004-R04: P3 contains voice, renderer, visual emits, narrator, and soundscapes and may drop, coalesce, freeze, cancel, or disable.

WM-SPEC-004-R05: P4 contains indexing, compaction, package/update checks, replay compression, telemetry export, and source/help indexing and runs only when idle or explicitly requested.

WM-SPEC-004-R06: Every queue has capacity, priority, overflow behavior, latency metric, drop/coalesce count, and owner.

WM-SPEC-004-R07: Every trigger, regex, script, plugin hook, parser, model call, speech job, renderer frame, storage batch, and importer has a declared time, memory, and cancellation budget.

WM-SPEC-004-R08: Slow rules are identified and quarantined without blocking manual play.

WM-SPEC-004-R09: One busy session cannot starve another session or global emergency stop.

WM-SPEC-004-R10: Every feature declares a text-gameplay-preserving fallback and a benchmark fixture before node completion.

WM-SPEC-004-R11: Target budgets begin with input under 5 ms, outbound queue under 10 ms, terminal append under 10 ms, emergency stop under 10 ms, and renderer work under a measured 4-6 ms frame budget when enabled; observed baselines may tighten but not silently loosen these goals.

WM-SPEC-004-R12: Performance readiness requires distributions, hardware profile, workload, raw evidence, and regression thresholds rather than a single anecdotal timing.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Performance degradation may never disable consent, redaction, command safety, or signature verification.

## Performance

- This specification is the binding performance policy.

## Non-Goals

- Optimizing optional animation at the expense of text gameplay
- Unbounded retries or queues

## Required Tests

- Text flood replay
- ANSI spam
- Trigger storm
- Pathological regex
- Mapper pathfinding
- Provider failure
- Multi-session stress
- Cold-start benchmark

## Acceptance

All requirements for SPEC-004 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-005, EP-008, EP-009, EP-023, EP-024, EP-025, EP-026, EP-032. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.

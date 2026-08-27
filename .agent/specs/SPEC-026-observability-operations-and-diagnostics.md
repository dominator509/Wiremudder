# SPEC-026: Observability, Operations, and Diagnostics

## Status

Accepted blueprint specification.

## Goal

Provide local-first logs, metrics, health, traces where useful, runbooks, resource budgets, support bundles, and operator workflows without mandatory hosted observability.

## Canonical Terms

health, readiness, structured log, metric, trace, diagnostic bundle, runbook.

## Required Behavior

WM-SPEC-026-R01: Structured logs use time, severity, subsystem, priority, app version, platform, session/profile hashes, correlation, event, error, latency, queue, drop/coalesce, feature, privacy, and redaction fields.

WM-SPEC-026-R02: Health distinguishes Mudlet core, bridge, WireCore, storage, provider, voice, renderer, updater, and optional worker states.

WM-SPEC-026-R03: Readiness means the component can accept its declared capability, not merely that a process exists.

WM-SPEC-026-R04: Metrics cover P0/P1 latency, queue depth, trigger/script runtime, storage delay, token/cost, provider latency, speech timing, renderer frame time, drops, cancellations, crashes, updates, and package policy.

WM-SPEC-026-R05: Tracing is bounded, local by default, sampled, redacted, and disabled if its cost threatens gameplay.

WM-SPEC-026-R06: Runbooks cover start, stop, health, recovery, backup, restore, upgrade, rollback, disable, diagnostics, and incident triage.

WM-SPEC-026-R07: Support bundles are previewable, redacted, reproducible, and content-addressed.

WM-SPEC-026-R08: No hosted telemetry, crash reporting, or analytics endpoint is required for core operation.

WM-SPEC-026-R09: Optional external observability requires explicit configuration and privacy policy.

WM-SPEC-026-R10: Operations evidence is retained under .agent/state/evidence and linked to node and release claims.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Observability data follows the same sensitivity and retention policy as source data.

## Performance

- Hot-path observability is limited to bounded counters and ring-buffer events.

## Non-Goals

- Always-on remote telemetry
- Health that ignores dependency readiness

## Required Tests

- Health failure
- Metric presence
- Redaction
- Runbook drill
- Bundle preview

## Acceptance

All requirements for SPEC-026 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-005, EP-014, EP-016, EP-023, EP-024, EP-025, EP-028, EP-029, EP-035. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.

# SPEC-025: Error Handling, Recovery, and Compensation

## Status

Accepted blueprint specification.

## Goal

Use stable typed errors, correlation, safe user messages, bounded retries, recovery, compensation, and fail-closed behavior across inherited and new components.

## Canonical Terms

error code, retry class, compensation, quarantine, degraded state, correlation.

## Required Behavior

WM-SPEC-025-R01: Error classes include validation, authentication, authorization, consent, policy, unavailable, timeout, canceled, conflict, rate limit, external provider, storage, protocol, compatibility, security, verification, rollback, and invariant failure.

WM-SPEC-025-R02: Every public error has a stable code, safe message, correlation ID, retry class, user action, diagnostic reference, and redacted internal cause.

WM-SPEC-025-R03: Retries are bounded, jittered where network-appropriate, idempotent, and never applied to destructive or ambiguous effects without an idempotency key.

WM-SPEC-025-R04: Repeated failures quarantine the optional subsystem or asset and preserve text gameplay.

WM-SPEC-025-R05: Partial side effects use compensation or explicit reconciliation and are visible in audit history.

WM-SPEC-025-R06: Unknown errors fail closed for command, privacy, secret, permission, routing, update, and signing decisions.

WM-SPEC-025-R07: Cancellation is distinct from failure and propagates to provider, speech, renderer, import, indexing, and long-running tasks.

WM-SPEC-025-R08: Crash recovery reopens the last known good profile and reports unsaved optional work without claiming completion.

WM-SPEC-025-R09: User-facing messages do not expose stack traces, paths, credentials, private text, provider payloads, or signing metadata.

WM-SPEC-025-R10: Every forced-failure test asserts error, logs, metrics, audit, cleanup, and preserved gameplay.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Sensitive failures disclose no secret material.

## Performance

- Failure handling cannot create unbounded logs, queues, or retry storms.

## Non-Goals

- Infinite retry
- Success response after partial failure

## Required Tests

- Error schema
- Retry bounds
- Cancellation
- Compensation
- Crash recovery

## Acceptance

All requirements for SPEC-025 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-005, EP-006, EP-008, EP-014, EP-016, EP-024, EP-025, EP-028, EP-029, EP-034. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.

# SPEC-019: Telemetry, Replay, Diagnostics, and Bug Automation

## Status

Accepted blueprint specification.

## Goal

Create local-first structured diagnostics, replay, redaction, compatibility fixtures, performance evidence, AI-assisted debugging, and bounded autonomous remediation without hidden telemetry.

## Canonical Terms

telemetry event, ring buffer, diagnostic bundle, Session Replay, AI Debugger, Compatibility Lab, Protocol Museum, bug remediation.

## Required Behavior

WM-SPEC-019-R01: Telemetry is off by default and local structured event capture uses bounded crash-safe ring buffers.

WM-SPEC-019-R02: Events include schema/app/platform/subsystem/priority/severity/fingerprint/correlation/scope/feature/privacy/latency/queue/drop/coalesce/provider/voice/renderer/redaction fields without raw secrets.

WM-SPEC-019-R03: Crash and diagnostic bundles are local, redacted, previewable, content-addressed, and never submitted without explicit user action or opt-in policy.

WM-SPEC-019-R04: Session Replay records deterministic sanitized events and preserves version information needed for reproduction.

WM-SPEC-019-R05: Sanitized fixture generation strips secrets, player names, private messages, routing credentials, full prompts, and voice transcripts unless the user specifically approves inclusion.

WM-SPEC-019-R06: AI Debugger may analyze approved evidence and propose a hypothesis, reproduction, patch plan, tests, risk, and rollback but cannot self-certify success.

WM-SPEC-019-R07: Compatibility Lab runs reference and WireMudder scenarios and records semantic diffs.

WM-SPEC-019-R08: Protocol Museum provides controlled fake MUD servers for negotiation, malformed input, latency, disconnect, compression, and protocol event fixtures.

WM-SPEC-019-R09: Bug automation uses bounded reproduction, diagnosis, patch, test, review, canary, and rollback states and reaches DONE or evidence-backed BLOCKED.

WM-SPEC-019-R10: Any P0/P1 bug receives performance review and any transcript, AI, voice, routing, secrets, package, or update bug receives privacy or security review.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Diagnostic export is a user-visible effect with scope and content review.

## Performance

- Only bounded ring-buffer writes may occur near hot paths; compression and export are P4.

## Non-Goals

- Unreviewed external telemetry
- Autonomous gate weakening
- Raw private transcript upload

## Required Tests

- Redaction corpus
- Crash bundle preview
- Replay determinism
- Protocol Museum scenarios
- Bug-fix regression loop

## Acceptance

All requirements for SPEC-019 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-003, EP-022, EP-028, EP-029, EP-032, EP-036. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.

# SPEC-009: Command Safety, Emergency Stop, and Pacing

## Status

Accepted blueprint specification.

## Goal

Apply one deterministic action gateway to every non-manual command source, keep the emergency stop immediate, and make automation visible, reversible, scoped, and auditable.

## Canonical Terms

Command Database, risk tier, Action Proposal, confirmation, Emergency Stop, Human-Tempo Assist, outbound queue.

## Required Behavior

WM-SPEC-009-R01: Manual user input remains direct except for connection state and emergency-stop constraints; AI classification is never required for manual send.

WM-SPEC-009-R02: AI, autopilot, voice, macro, trigger, script, plugin, headless, and cross-session commands enter the same deterministic Action Proposal path.

WM-SPEC-009-R03: The gate verifies connection, emergency-stop state, source visibility, profile automation mode, command database, Soul policy, risk tier, confirmation policy, routing stability, prompt-injection checks, cooldown, pacing, and audit creation.

WM-SPEC-009-R04: Destructive, social, trade, PvP, account, privacy, and irreversible actions require explicit confirmation unless a narrow user allowlist says otherwise.

WM-SPEC-009-R05: No command is sent solely because a model reports high confidence.

WM-SPEC-009-R06: Emergency stop cancels queued automation, stops new proposals, bypasses pacing delay, and propagates within the P0 target budget.

WM-SPEC-009-R07: Human-Tempo Assist is an anti-spam and usability control, not bot-detection evasion, impersonation, or terms circumvention.

WM-SPEC-009-R08: The visible queue shows original suggestion, normalized command, source, risk, required approval, pacing decision, and final send result.

WM-SPEC-009-R09: Every sent automated command is traceable to observation, active memory citations, command policy, Soul document, approvals, and send time.

WM-SPEC-009-R10: Stale safety state, unavailable command database, or ambiguous command intent pauses automation rather than guessing.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Action policy is local-first and fail-closed.

## Performance

- Emergency stop and manual send retain reserved queue capacity.

## Non-Goals

- Hidden auto-send
- Model confidence as authorization
- Pacing designed to evade detection

## Required Tests

- Risk-table tests
- Emergency-stop stress proof
- Confirmation E2E
- Stale-state denial
- Audit replay

## Acceptance

All requirements for SPEC-009 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-008, EP-017, EP-018, EP-019, EP-023, EP-024. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.

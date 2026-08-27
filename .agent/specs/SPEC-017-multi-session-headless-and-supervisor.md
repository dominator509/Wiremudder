# SPEC-017: Multi-Session, Headless, and Supervisor

## Status

Accepted blueprint specification.

## Goal

Support independent bounded desktop and headless sessions, structured event output, scenario files, a supervisor, controlled cross-session rules, and global emergency stop.

## Canonical Terms

session, headless session, scenario file, JSONL event, Headless Supervisor, cross-session rule.

## Required Behavior

WM-SPEC-017-R01: Desktop supports multiple tabs and windows with independent connection, profile, memory, command, voice, renderer, soundscape, routing, and performance state.

WM-SPEC-017-R02: Each session has bounded queues and one busy world cannot starve another.

WM-SPEC-017-R03: Headless mode shares connection, protocol, profile, privacy, command safety, storage, AI, and automation contracts with desktop.

WM-SPEC-017-R04: Headless mode emits versioned structured JSONL and can disable UI, renderer, audio, and voice for lower overhead.

WM-SPEC-017-R05: Scenario files declare worlds, profiles, routing references, privacy mode, feature flags, budgets, and allowed cross-session workflows and are schema-validated.

WM-SPEC-017-R06: Headless Supervisor shows session state, room, last command, AI/autopilot state, risk queue, route label, token spend, health, and emergency stop.

WM-SPEC-017-R07: Cross-session orchestration is explicit, user-defined, rate-limited, auditable, and cannot leak private data between profiles without permission.

WM-SPEC-017-R08: Global emergency stop halts all automated queues while preserving manual disconnect and shutdown controls.

WM-SPEC-017-R09: CI fixture mode uses controlled fake servers and sanitized profiles, not live worlds or user data.

WM-SPEC-017-R10: Headless session overhead is benchmarked below the equivalent desktop configuration.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Every session retains its own privacy, routing, consent, and command policy.

## Performance

- Fair scheduling and reserved emergency capacity are mandatory.

## Non-Goals

- Hidden mass automation
- Cross-profile memory sharing by default

## Required Tests

- Multi-session stress
- JSONL schema
- Scenario validation
- Global emergency stop
- Headless resource benchmark

## Acceptance

All requirements for SPEC-017 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-007, EP-008, EP-023, EP-032, EP-036. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.

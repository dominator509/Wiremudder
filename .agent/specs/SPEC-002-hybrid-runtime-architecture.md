# SPEC-002: Hybrid Runtime Architecture

## Status

Accepted blueprint specification.

## Goal

Define the retained Qt/C++/Lua client, minimal native bridge, isolated Rust WireCore services, and strangler-migration rules that protect inherited behavior and the P0 gameplay path.

## Canonical Terms

Mudlet core, WireMudder native bridge, WireCore, sidecar, worker boundary, strangler migration, P0 hot path.

## Required Behavior

WM-SPEC-002-R01: Mudlet remains the initial desktop shell, terminal, profile, mapper, Lua, package, and classic automation implementation.

WM-SPEC-002-R02: New WireMudder code is namespaced under src/wiremudder, wirecore, schemas/wiremudder, tests/wiremudder, and docs/wiremudder unless a verified integration point requires a minimal inherited-source patch.

WM-SPEC-002-R03: The C++ bridge publishes versioned events and receives typed proposals but contains no model, memory, provider, or business-policy logic.

WM-SPEC-002-R04: WireCore runs outside the Mudlet process by default so a crash, deadlock, or upgrade cannot terminate active text gameplay.

WM-SPEC-002-R05: All bridge queues are bounded and P2-P4 backpressure cannot propagate into the inherited connection, terminal, manual input, or emergency-stop path.

WM-SPEC-002-R06: The bridge authenticates the local peer, validates schema versions, enforces message-size limits, and fails closed on malformed input.

WM-SPEC-002-R07: Transport and encoding selection is completed in EP-005 using repository evidence and benchmarks, then pinned by ADR; no executor invents an unverified library API.

WM-SPEC-002-R08: UI additions use Qt and existing Mudlet conventions for the initial product rather than introducing a second desktop shell.

WM-SPEC-002-R09: A component may be replaced only behind a reversible feature flag after differential compatibility, performance, failure, and rollback proofs pass.

WM-SPEC-002-R10: No replacement removes the inherited implementation until at least one stable release proves rollback and migration.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- The sidecar never receives secrets unless a narrowly scoped, user-approved capability requires them.

## Performance

- Manual gameplay must function with WireCore stopped, hung, slow, or absent.

## Non-Goals

- A Tauri-first rewrite
- A Rust conversion quota
- One process containing all optional systems

## Required Tests

- Bridge contract tests
- Sidecar crash isolation
- Backpressure flood test
- Feature-flag rollback

## Acceptance

All requirements for SPEC-002 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-001, EP-004, EP-005, EP-032, EP-036. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.

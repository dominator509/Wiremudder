# SPEC-024: Bridge, IPC, API, and Headless Contracts

## Status

Accepted blueprint specification.

## Goal

Define local process lifecycle, handshake, schema negotiation, backpressure, cancellation, errors, streaming, and equivalent desktop/headless commands.

## Canonical Terms

Bridge Hello, schema negotiation, local peer authentication, request ID, cancellation, stream frame.

## Required Behavior

WM-SPEC-024-R01: The Mudlet process starts, monitors, reconnects, and stops WireCore through an explicit lifecycle with bounded readiness and kill paths.

WM-SPEC-024-R02: The local transport is OS-local, authenticated, permission-restricted, and unavailable to arbitrary remote peers.

WM-SPEC-024-R03: Handshake negotiates protocol major/minor, feature capabilities, maximum frame size, compression policy if any, privacy mode, and build identity.

WM-SPEC-024-R04: Requests carry request, correlation, causation, session, profile, deadline, cancellation, sensitivity, and capability context.

WM-SPEC-024-R05: Streaming messages preserve ordering within a stream and expose dropped, coalesced, canceled, and terminal states.

WM-SPEC-024-R06: The bridge never blocks the Qt main thread waiting for model, storage, voice, renderer, or remote provider completion.

WM-SPEC-024-R07: Malformed, oversized, unauthorized, expired, duplicated, and unsupported messages receive typed errors and no side effect.

WM-SPEC-024-R08: Desktop and headless commands use the same application contracts and policy gates.

WM-SPEC-024-R09: Restart resynchronizes snapshots rather than replaying unbounded raw history.

WM-SPEC-024-R10: Contract compatibility is tested across at least the current and previous supported protocol minor version.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Local peer identity and permission checks precede profile or secret disclosure.

## Performance

- High-frequency event transport is benchmarked before enablement.

## Non-Goals

- Remote unauthenticated control port
- Unbounded transcript replay after reconnect

## Required Tests

- Handshake
- Frame fuzzing
- Cancellation
- Restart resync
- Backward compatibility
- Main-thread nonblocking

## Acceptance

All requirements for SPEC-024 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-004, EP-005, EP-014, EP-023, EP-028. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.

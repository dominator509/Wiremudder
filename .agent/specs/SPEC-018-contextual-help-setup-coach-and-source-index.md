# SPEC-018: Contextual Help, Setup Coach, and Source Index

## Status

Accepted blueprint specification.

## Goal

Provide field-level help, safe setup guidance, local documentation search, optional AI explanations, and opt-in source indexing without giving the coach mutation authority.

## Canonical Terms

help bubble, Setup Coach, Help Knowledge Index, Ask WireMudder AI, source index.

## Required Behavior

WM-SPEC-018-R01: Circular help controls appear beside fields, feature cards, wizard steps, and advanced controls and provide safe defaults, validation hints, privacy notes, and documentation links.

WM-SPEC-018-R02: Ask WireMudder AI receives only the active field ID, sanitized UI state, validation error, approved docs, schemas, command catalog, ADRs, and cited source references.

WM-SPEC-018-R03: Help modes are local-only and remote-redacted or disabled according to privacy policy.

WM-SPEC-018-R04: The Help Knowledge Index is generated reproducibly from accepted docs, UI schemas, command catalog, configuration schemas, ADRs, and sanitized source references.

WM-SPEC-018-R05: Optional source checkout indexing is opt-in, local-first, idle-only, secret-aware, ignore-file-aware, resumable, and removable.

WM-SPEC-018-R06: The coach may explain and propose steps but cannot change settings, enable telemetry or autopilot, change routing, install packages, send commands, edit Soul documents, edit command packs, or access secrets.

WM-SPEC-018-R07: Headless and CLI users receive equivalent command and configuration help.

WM-SPEC-018-R08: World onboarding identifies server capabilities through observed negotiation and user confirmation rather than invented assumptions.

WM-SPEC-018-R09: Help content is versioned with the app and reports when an answer relies on stale or unavailable source evidence.

WM-SPEC-018-R10: Help requests never block settings interaction or gameplay.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Source index excludes secrets, ignored files, user profiles, and generated sensitive artifacts.

## Performance

- Indexing is P4 and pauses during active gameplay.

## Non-Goals

- Coach-controlled configuration
- Automatic source upload

## Required Tests

- No-side-effect coach test
- Local-only route
- Index redaction
- Capability detector fixture
- CLI parity

## Acceptance

All requirements for SPEC-018 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-004, EP-006, EP-011, EP-027, EP-031. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.

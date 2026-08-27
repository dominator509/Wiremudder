# SPEC-003: Canonical Vocabulary, Events, and Capabilities

## Status

Accepted blueprint specification.

## Goal

Lock public names, event schemas, capability descriptors, versioning, provenance, and traceability so independent agents cannot create incompatible synonyms or untracked contracts.

## Canonical Terms

canonical term, event envelope, capability descriptor, schema version, correlation ID, causation ID, source evidence.

## Required Behavior

WM-SPEC-003-R01: Public names are declared in .agent/vocabulary/CANONICAL_TERMS.tsv and may change only through an ADR, schema update, feature matrix update, and ledger event.

WM-SPEC-003-R02: Every bridge, storage, AI, voice, renderer, telemetry, package, update, and headless message uses a versioned schema under schemas/wiremudder.

WM-SPEC-003-R03: Every event includes event ID, schema version, timestamp, source, session/profile scope, correlation ID, causation ID, priority ring, sensitivity class, and provenance references where applicable.

WM-SPEC-003-R04: Unknown required fields, invalid enum values, oversized payloads, and unsupported major schema versions are rejected deterministically.

WM-SPEC-003-R05: Backward-compatible additions increment minor versions; breaking changes require a major version, migration, compatibility fixture, and rollback plan.

WM-SPEC-003-R06: Generated bindings are reproducible and never edited by hand.

WM-SPEC-003-R07: Feature flags, environment variables, queues, commands, errors, privacy modes, and release profiles use vocabulary-locked names.

WM-SPEC-003-R08: Every public behavior maps to a SPEC requirement ID, feature ID, node ID, test path, and live-fire proof or documented research decision.

WM-SPEC-003-R09: Source evidence records include repository, commit, path, symbol or line reference, command, output hash, and observation date.

WM-SPEC-003-R10: Free-form provider payloads are normalized at the adapter boundary and never become domain contracts.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Sensitivity classes and redaction policy are mandatory schema fields where user content may appear.

## Performance

- Event envelopes are compact enough for bounded queues and measured before high-frequency use.

## Non-Goals

- Conversation-derived names as authority
- Provider-specific payloads in core domain code

## Required Tests

- Schema validation
- Binding regeneration check
- Vocabulary lock check
- Traceability check

## Acceptance

All requirements for SPEC-003 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-003, EP-004, EP-005, EP-014, EP-016. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.

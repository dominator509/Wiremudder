# SPEC-023: Data Model and Retention

## Status

Accepted blueprint specification.

## Goal

Define stable entities, ownership, provenance, sensitivity, lifecycle, retention, export, deletion, and migration rules for WireMudder data.

## Canonical Terms

world, session, character profile, routing profile, memory fact, audit event, retention policy.

## Required Behavior

WM-SPEC-023-R01: Core entities include local app identity, worlds, sessions, character profiles, routing profiles, default bindings, command databases, Soul documents, automation objects, packages, permissions, rooms, exits, zones, entities, quests, items, World Bible rules, renderer assets/emits, soundscape bindings, transcripts, replay fixtures, memory facts, indexes, AI events, token events, privacy events, voice events, command events, routing events, telemetry events, update events, and audit events.

WM-SPEC-023-R02: Every record declares owner/profile/world scope, created and observed time, source, actor, schema version, sensitivity, retention, and content hash where applicable.

WM-SPEC-023-R03: Derived records declare confidence, derivation references, model or rule version, and supersession links.

WM-SPEC-023-R04: IDs are opaque and stable; provider IDs and user-facing names do not become primary keys.

WM-SPEC-023-R05: Private, secret, diagnostic, voice, transcript, and public content use distinct data classifications and default retention.

WM-SPEC-023-R06: Deletion is tombstoned or hard-deleted according to legal and audit requirements and does not resurrect through re-indexing.

WM-SPEC-023-R07: Export includes schemas, provenance, relationships, and checksums and excludes secrets unless a separately encrypted user export is explicitly requested.

WM-SPEC-023-R08: Schema migrations include forward compatibility, backup, idempotency, validation, and rollback or restore.

WM-SPEC-023-R09: Indexes are rebuildable projections and never the sole canonical copy.

WM-SPEC-023-R10: Cross-profile sharing is explicit and permissioned rather than inferred.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Data classification drives redaction and egress policy.

## Performance

- Hot state and durable state are separated.

## Non-Goals

- Provider-specific core tables
- Secret values in semantic memory

## Required Tests

- Schema validation
- Migration
- Export/delete
- Index rebuild
- Cross-profile denial

## Acceptance

All requirements for SPEC-023 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-004, EP-006, EP-007, EP-014, EP-021, EP-028. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.

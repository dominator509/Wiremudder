# SPEC-011: Local Storage, Transcripts, Search, and Backup

## Status

Accepted blueprint specification.

## Goal

Store WireMudder state locally with bounded asynchronous writes, append-only transcripts, searchable indexes, migrations, backup, restore, export, and deletion.

## Canonical Terms

SQLite, WAL, transcript chunk, FTS, vector index, migration, backup, restore.

## Required Behavior

WM-SPEC-011-R01: WireCore uses a repository-selected and pinned local database implementation, with SQLite as the default candidate verified during EP-014.

WM-SPEC-011-R02: Raw transcript chunks are append-only files with durable metadata and offsets rather than one database row per incoming line.

WM-SPEC-011-R03: Structured profile, memory, map augmentation, policy, package, audit, telemetry, and update metadata has explicit schema ownership and migrations.

WM-SPEC-011-R04: FTS indexes searchable transcripts, notes, room descriptions, NPCs, quests, commands, and local help where enabled.

WM-SPEC-011-R05: Vector indexing applies only to selected user-approved facts and summaries and never every raw line.

WM-SPEC-011-R06: All writes from gameplay subscribers use bounded asynchronous queues; socket and terminal paths never wait on storage.

WM-SPEC-011-R07: Migrations are versioned, idempotent or completion-detecting, backup-aware, resumable, and blocked during active sessions when risk requires shutdown.

WM-SPEC-011-R08: Backup, restore, export, deletion, corruption recovery, and index rebuild have live-fire proofs.

WM-SPEC-011-R09: Sensitive data is encrypted using OS-backed keys or a documented encrypted fallback selected by ADR.

WM-SPEC-011-R10: Retention and deletion cover transcripts, voice transcripts, AI events, diagnostics, replay fixtures, memory, and audit exceptions.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Secrets are not stored in ordinary SQLite tables or transcript files.

## Performance

- Storage can lag under load but cannot corrupt current session state.

## Non-Goals

- Synchronous database write in socket parsing
- Embedding all raw lines

## Required Tests

- Migration test
- Crash recovery
- Backup/restore
- FTS search
- Vector rebuild
- Queue-pressure test

## Acceptance

All requirements for SPEC-011 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-004, EP-006, EP-014, EP-021, EP-028, EP-030. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.

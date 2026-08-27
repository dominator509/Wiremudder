# WireMudder Local Storage, Transcripts, Search, and Backup (EP-014)

## Design: M2 Core Behavior

### 1. Architecture

EP-014 introduces namespaced local persistence with zero new supply
chain:

- `wirecore/crates/wire-storage/` - Rust core linking the host SQLite
  C library (pinned 3.45.1) directly via a small FFI subset.
- `wirecore/migrations/` - versioned, idempotent SQL migrations.
- `schemas/wiremudder/storage/` - version 1 JSON schemas.
- `tools/wiremudder-backup/` - backup/export/verify shell tool using
  SQLite's online backup (VACUUM INTO).

Storage is strictly OS-local: the database is a single file opened in
WAL mode (`PRAGMA journal_mode=WAL`, `synchronous=NORMAL`) with no
network, socket, or remote-I/O dependency in the crate. Access is
permission-restricted by the operating system file permissions on the
database path (SPEC-024, WM-SPEC-024-R02).

The inherited Mudlet surface (TLuaInterpreter luasql.sqlite3,
searchRoom, getRoomHidden) remains unedited. Evidence:
WM-SRC-000101..000103.

### 2. Transcript Metadata (WM-SPEC-011-R04)

- Append-only `transcripts` table: seq (autoincrement), profile,
  direction (in/out/note), text, time.
- FTS5 virtual table over profile/direction/text with an AFTER INSERT
  trigger keeping the index in sync.
- Search returns rowid, profile, direction, text, and a snippet with
  match highlighting.

### 3. Bounded Async Write Queue (WM-SPEC-011-R06)

- `WriteQueue` with a configurable depth (default 4096).
- Gameplay writes enqueue without touching the socket/terminal path.
- `drain_into` flushes the queue to the store in one pass.
- Queue-full returns a typed error; no blocking, no silent drop.

### 4. Migrations (WM-SPEC-011-R07, WM-SPEC-023-R08)

- `wire_schema_version(version, applied_at)` records applied versions.
- Migrations are versioned, idempotent (skip already-applied), and
  resumable (re-run after partial failure continues from the next
  version).
- Each migration is backup-aware: a backup can be taken before upgrade.

### 5. Export / Delete / Backup / Restore (WM-SPEC-010-R10, R08)

- Export: full transcript list as versioned JSON (schema-validated).
- Delete: per-profile delete returns the number of removed rows.
- Backup: `VACUUM INTO` consistent snapshot + integrity check.
- Restore: open the snapshot file; verified row survives.
- Verify: `PRAGMA integrity_check` returns ok.

### 6. Secrets Stay Outside Storage (SPEC-010/022)

- Storage writes only transcript/profile data; no secret vault, no
  provider keys, no routing profiles are stored by this crate.
- Sensitivity classification lives in the world-graph crate (EP-013),
  not here.

### 7. Deterministic Invariants

1. Append increments seq and count.
2. FTS finds matching lines with snippets; no-match returns empty.
3. Migration re-run is idempotent; version advances monotonically.
4. Write queue is bounded; drain preserves order.
5. Export contains every row; delete removes exactly the profile rows.
6. Integrity check returns ok.
7. Backup snapshot restores identical rows.

### 8. Verification

- Rust: `cargo test` (8 unit tests).
- Migrations/schemas: file presence + JSON contract.
- Backup tool: real DB create -> backup -> restore -> export -> verify.

### 9. Integration (M3)

- Full lifecycle oracle: `storage_lifecycle` example runs the real
  crate through queue -> drain -> search -> export -> delete and prints
  deterministic outcomes; the integration test asserts each sentinel.
- E2E export/restore: seed a real DB through the migration, export JSON,
  take a `VACUUM INTO` snapshot, verify integrity, restore and confirm
  both row count and the FTS index survive.
- Degraded mode: a missing DB fails the backup tool cleanly (typed,
  non-zero, no crash); manual gameplay state is independent of storage.

### 10. Rollback

Revert M3 commit; M1/M2 fences and verifier remain intact. No inherited
paths were edited.

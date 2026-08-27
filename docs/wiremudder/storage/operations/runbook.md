# WireMudder Storage Operations Runbook (EP-014 M4)

## Health and Readiness

- Crate health: `cargo test --manifest-path wirecore/crates/wire-storage/Cargo.toml`
  (9 unit tests). Green means core invariants hold.
- Backup tool health: `sh tools/wiremudder-backup/wiremudder-backup.sh verify <db>`
  prints `backup: ok verify` when integrity passes.

## Disable

- Storage is an optional system. Manual gameplay never waits on it:
  writes go to the bounded queue first (WM-SPEC-011-R06), and if
  storage is unavailable the queue fills and returns a typed error;
  the socket/terminal path is untouched.

## Recovery

- Corrupt DB: `Storage::open` returns a typed error at open; the
  previous database file can be replaced from the latest snapshot
  (`wiremudder-backup.sh verify` first).
- Partial migration: `migrate` is idempotent and resumable - re-run
  continues from the next unapplied version.

## Backup and Restore

- Backup: `wiremudder-backup.sh backup <db> <outdir>` creates a
  `VACUUM INTO` consistent snapshot and checks integrity.
- Export: `wiremudder-backup.sh export <db> <file.json>` writes the
  transcript export (schema `schemas/wiremudder/storage/`).
- Restore: point the app at the snapshot file; verify with
  `wiremudder-backup.sh verify`.

## Upgrade

- Add a new file under `wirecore/migrations/` with the next version
  number. Migration runner applies unapplied versions in order.
- Back up before upgrading (backup-aware migration, WM-SPEC-023-R08).

## Rollback

- Revert the node commit. No inherited paths are edited, so rollback is
  a pure revert of namespaced code. Never cross a completed green tag.

## Bounded Resources

- Write queue: configurable depth (default 4096), typed QueueFull.
- Transcript table: append-only, autoincrement seq.
- FTS index: maintained by trigger, search bounded by LIMIT.

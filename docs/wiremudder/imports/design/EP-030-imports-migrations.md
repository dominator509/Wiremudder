# EP-030 Design: Imports, Migrations, and Client Ecosystem

## Purpose

Provide safe migration from Mudlet assets and evidence-backed import paths
for MUSHclient, TinTin++, zMUD/CMUD concepts, and generic formats with
disabled automation and rollback (SPEC-021, SPEC-008, SPEC-020, SPEC-022).
Every import is hashed, backed up, provenance-tracked, and reversible.

## Boundaries

- `wirecore/crates/wire-import/` — the import/migration engine.
- `src/wiremudder/ui/import/` — passive Qt6 boundary pane (compile-proof
  only; the pane never executes imports or enables automation).
- `compatibility/imports/` — representative corpus fixtures
  (WM-SPEC-021-R08): clean, malformed, generic JSON/CSV, MUSHclient,
  TinTin++, zMUD/CMUD.
- `schemas/wiremudder/import/` — canonical plan and report schemas.

The inherited edit is `src/CMakeLists.txt` (source list wiring), authorized
by the discovered-path amendment WM-SRC-000221.

## Import Plan (WM-SPEC-021-R03)

Every import creates: source hash (sha256), format version, provenance
record, backup path, normalized result, warning list, unsupported-item
list, conflict list, and rollback path. Automation is always disabled
(`automation_disabled: true`) — imported triggers, aliases, timers, and
scripts start disabled until reviewed (WM-SPEC-021-R04, WM-SPEC-008-R06).

## Format Discovery (WM-SPEC-021-R01/R02)

- Mudlet XML: verified format, detected from the profile/package root.
- MUSHclient, TinTin++, zMUD/CMUD, generic JSON/CSV/YAML: research paths
  (WM-FEAT-0120, research-decision-required) — read-only analysis, no
  apply, with `unverified_format` warnings.

Specific XML roots (MUSHclient, World/Class) are checked before the generic
XML fallback so documents are never misclassified as Mudlet.

## Safety (WM-SPEC-021-R07)

- Size bound: 64 MiB default; depth bound: 64; entry bound: 100,000.
- Traversal rejected: absolute paths, parent-directory components.
- Unknown fields are reported, never silently dropped (WM-SPEC-021-R05).

## Conflict Policy (WM-SPEC-021-R06)

Deterministic policy enum: `import_wins`, `destination_wins`, `keep_both`;
conflicts are user-visible in the plan and report.

## Session Deferral (WM-SPEC-020-R07)

`assert_migration_allowed(active_sessions, user_approved)` refuses
migrations during active sessions unless the user stops sessions and
approves.

## Commands

Build and test:

```
CARGO_TARGET_DIR=$PWD/wirecore/target cargo test --manifest-path wirecore/crates/wire-import/Cargo.toml
```

Observed sentinels (M3):

- `integration EP-030 import-boundary-qt6: ok`
- `integration EP-030 corpus-analysis: ok` (7 fixtures, correct formats,
  hash len 64, automation disabled)
- `e2e import-migration-disabled-automation: ok`

## Rollback

The crate exposes `rollback(backup_path, rollback_path)` which requires
real files and refuses to proceed otherwise. A failed import leaves the
original and destination unchanged except a removable diagnostic report
(WM-SPEC-021-R09). To remove the subsystem entirely, revert the EP-030
commits and `git checkout -- src/CMakeLists.txt` (the discovered
amendment's declared rollback).

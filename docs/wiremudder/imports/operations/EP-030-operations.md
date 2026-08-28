# EP-030 Operations: Imports, Migrations, and Client Ecosystem

## Health

- Crate tests:
  `CARGO_TARGET_DIR=$PWD/wirecore/target cargo test --manifest-path wirecore/crates/wire-import/Cargo.toml`
- Qt6 boundary compile:
  `g++ -std=c++17 -fPIC -c src/wiremudder/ui/import/import_boundary.cpp -I/opt/qt/6.8.2/gcc_64/include -I/opt/qt/6.8.2/gcc_64/include/QtCore -Wall -Wextra`

## Readiness

Ready when: the crate compiles with zero warnings, all unit tests pass, the
corpus analysis harness classifies every fixture with a 64-char hash and
disabled automation, and the performance fixture reports
`perf fixture EP-030: ok` within the 5 ms budget.

## Disable

The subsystem is optional and fully isolated. Disable by not invoking the
import engine; the Qt6 boundary pane is passive and never executes imports.
To remove entirely: revert the EP-030 node commits and run
`git checkout -- src/CMakeLists.txt` (the discovered amendment's rollback).
Manual text gameplay is unaffected either way.

## Recovery

- A malformed import produces a plan with warnings/unsupported reports; it
  never corrupts the destination.
- A failed import leaves the original and destination unchanged except a
  removable diagnostic report (WM-SPEC-021-R09).
- Migrations defer during active sessions (WM-SPEC-020-R07); stop sessions
  and approve to proceed.

## Backup and Restore

- Every import declares a backup path and rollback path before apply.
- `rollback(backup_path, rollback_path)` refuses without real files.
- Restore the backup file to the destination to undo a migration.

## Upgrade

- Rebuild with `cargo build --manifest-path wirecore/crates/wire-import/Cargo.toml`.
- Schema version is pinned (`IMPORT_SCHEMA_VERSION = 1`); a future schema
  bump is a material change requiring the spec-update process.

## Rollback

- Crate-level: `rollback()` restores the declared backup.
- Node-level: revert EP-030 M1..M5 commits; the inherited CMake edit is
  reverted by `git checkout -- src/CMakeLists.txt` per the discovered
  amendment, returning the client to its pre-EP-030 state exactly.

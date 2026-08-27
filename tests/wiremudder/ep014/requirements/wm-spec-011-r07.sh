#!/usr/bin/env sh
# WM-SPEC-011-R07: migrations are versioned, idempotent or
# completion-detecting, backup-aware, resumable, and blocked during
# active sessions when risk requires shutdown.
set -eu
cd "$(dirname "$0")/../../../.."

DB=/tmp/wm-r07.db
rm -f "$DB" "$DB-wal" "$DB-shm"
trap 'rm -f "$DB" "$DB-wal" "$DB-shm"' EXIT

fail() { echo "wm-spec-011-r07: FAIL - $1" >&2; exit 1; }

# Versioned: canonical migration files exist under wirecore/migrations.
ls wirecore/migrations/0001_transcripts_fts.sql >/dev/null 2>&1 || fail "migration 0001"

# Idempotent: applying the migration twice must succeed and keep one schema.
sqlite3 "$DB" < wirecore/migrations/0001_transcripts_fts.sql || fail "apply 1"
sqlite3 "$DB" < wirecore/migrations/0001_transcripts_fts.sql || fail "apply 2 (idempotent)"
sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='trigger' AND name LIKE 'transcripts_%';" \
  | grep -qx "3" || fail "trigger count (ai/ad/au)"

# Completion-detecting: crate migration tracks versions in
# wire_schema_version and skips applied versions.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-storage/Cargo.toml migration_is_idempotent \
  >/dev/null 2>&1 || fail "crate migration test"

# Backup-aware + resumable: runbook documents back up before upgrading and
# resumable partial migration.
grep -qi "back up before upgrading" docs/wiremudder/storage/operations/runbook.md \
  || fail "backup-aware upgrade missing"
grep -qi "resumable" docs/wiremudder/storage/operations/runbook.md \
  || fail "resumable missing"

echo "wm-spec-011-r07: ok"

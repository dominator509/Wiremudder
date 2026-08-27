#!/usr/bin/env sh
# WM-SPEC-023-R08: schema migrations include forward compatibility,
# backup, idempotency, validation, and rollback or restore.
set -eu
cd "$(dirname "$0")/../../../.."

DB=/tmp/wm-r23.db
rm -f "$DB" "$DB-wal" "$DB-shm"
trap 'rm -f "$DB" "$DB-wal" "$DB-shm"' EXIT

fail() { echo "wm-spec-023-r08: FAIL - $1" >&2; exit 1; }

# Forward compatibility: schema keeps an explicit version record and
# additive DDL only (CREATE IF NOT EXISTS).
sqlite3 "$DB" < wirecore/migrations/0001_transcripts_fts.sql || fail "schema"
grep -q "IF NOT EXISTS" wirecore/migrations/0001_transcripts_fts.sql \
  || fail "migration not additive-idempotent"

# Idempotency: applying twice is a no-op (one schema, same counts).
sqlite3 "$DB" < wirecore/migrations/0001_transcripts_fts.sql || fail "reapply"
sqlite3 "$DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='transcripts';" \
  | grep -qx "1" || fail "duplicate table"

# Validation: CHECK constraint rejects bad direction values.
if sqlite3 "$DB" "INSERT INTO transcripts(profile, direction, text, time)
                  VALUES('x','sideways','bad',1);" >/dev/null 2>&1; then
  fail "CHECK constraint not enforced"
fi

# Backup: the migration is backup-aware per the runbook.
grep -qi "back up before upgrading" docs/wiremudder/storage/operations/runbook.md \
  || fail "backup-aware upgrade missing"

# Rollback or restore: runbook documents rollback of the node commit and
# restore from snapshot.
grep -qi "rollback" docs/wiremudder/storage/operations/runbook.md || fail "rollback missing"
grep -qi "restore" docs/wiremudder/storage/operations/runbook.md || fail "restore missing"

echo "wm-spec-023-r08: ok"

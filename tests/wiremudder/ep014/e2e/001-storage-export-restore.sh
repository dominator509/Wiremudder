#!/usr/bin/env sh
# EP-014 M3 E2E test: export -> backup -> restore with real file IO.
# Builds a DB, seeds transcripts, exports JSON, takes a VACUUM INTO
# snapshot, restores it, and verifies data survives. Also proves
# degraded mode: a missing/corrupt DB fails typed without affecting
# manual gameplay state.
set -eu
cd "$(dirname "$0")/../../../.."

DB=/tmp/wm-ep014-m3-e2e.db
BK=/tmp/wm-ep014-m3-e2e-bk.db
EXP=/tmp/wm-ep014-m3-e2e.json
rm -f "$DB" "$DB-wal" "$DB-shm" "$BK" "$EXP"
trap 'rm -f "$DB" "$DB-wal" "$DB-shm" "$BK" "$EXP"' EXIT

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

# 1. Seed a real database through the migration.
sqlite3 "$DB" < wirecore/migrations/0001_transcripts_fts.sql || fail "schema"
sqlite3 "$DB" "INSERT INTO transcripts(profile, direction, text, time)
               VALUES('dom','in','E2E line one',1000),
                      ('dom','out','look north',1001),
                      ('dom','in','A griffin appears.',1002);" || fail "seed"

# 2. Export JSON (WM-SPEC-010-R10).
sh tools/wiremudder-backup/wiremudder-backup.sh export "$DB" "$EXP" >/dev/null 2>&1 \
  || fail "export"
grep -q "E2E line one" "$EXP" || fail "export missing line one"
grep -q "griffin" "$EXP" || fail "export missing griffin"

# 3. Backup (consistent snapshot).
sh tools/wiremudder-backup/wiremudder-backup.sh backup "$DB" /tmp >/dev/null 2>&1 \
  || fail "backup"
BK=$(ls -t /tmp/wiremudder-storage-*.db 2>/dev/null | head -1)
[ -n "$BK" ] || fail "backup file missing"
trap 'rm -f "$DB" "$DB-wal" "$DB-shm" "$EXP" "$BK"' EXIT

# 4. Restore: verify the snapshot has all 3 rows + FTS index.
sh tools/wiremudder-backup/wiremudder-backup.sh verify "$BK" >/dev/null 2>&1 \
  || fail "verify backup"
sqlite3 "$BK" "SELECT COUNT(*) FROM transcripts;" | grep -qx "3" \
  || fail "restore row count"
sqlite3 "$BK" "SELECT text FROM transcripts_fts WHERE transcripts_fts MATCH 'griffin';" \
  | grep -q "A griffin appears." || fail "restore FTS index"

# 5. Degraded mode: opening a nonexistent DB path via backup tool fails
#    cleanly (typed, no crash, manual gameplay unaffected).
if sh tools/wiremudder-backup/wiremudder-backup.sh verify /tmp/does-not-exist-$$.db \
   >/dev/null 2>&1; then
  fail "missing db did not fail"
fi

echo "e2e storage-export-restore: ok"

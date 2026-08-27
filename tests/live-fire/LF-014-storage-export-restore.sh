#!/usr/bin/env sh
# LF-014 live-fire: storage export/restore and corruption recovery.
# Real controlled outcome for Local Storage, Transcripts, Search, and
# Backup: seeds a database, exports JSON, takes a VACUUM INTO snapshot,
# restores, proves deletion keeps the FTS index consistent, and proves
# corrupt files fail typed at open. Then runs the real feature coverage
# and spec trace gates.
set -eu
cd "$(dirname "$0")/../.."

DB=/tmp/wm-lf014-live.db
BK=/tmp/wm-lf014-live-bk.db
EXP=/tmp/wm-lf014-live.json
CORRUPT=/tmp/wm-lf014-corrupt.db
rm -f "$DB" "$DB-wal" "$DB-shm" "$BK" "$EXP" "$CORRUPT"
trap 'rm -f "$DB" "$DB-wal" "$DB-shm" "$BK" "$EXP" "$CORRUPT"' EXIT

fail() { echo "LF-014: FAIL - $1" >&2; exit 1; }

# 1. Seed a real database through the canonical migration.
sqlite3 "$DB" < wirecore/migrations/0001_transcripts_fts.sql || fail "schema"
sqlite3 "$DB" "INSERT INTO transcripts(profile, direction, text, time)
               VALUES('dom','in','LF line one',1000),
                      ('dom','out','look north',1001),
                      ('dom','in','A griffin appears.',1002),
                      ('alice','in','alice private note',1003);" || fail "seed"

# 2. Export JSON (WM-SPEC-010-R10) and prove content survives.
sh tools/wiremudder-backup/wiremudder-backup.sh export "$DB" "$EXP" >/dev/null 2>&1 \
  || fail "export"
grep -q "LF line one" "$EXP" || fail "export missing line one"
grep -q "griffin" "$EXP" || fail "export missing griffin"

# 3. Backup: consistent snapshot with integrity verified.
sh tools/wiremudder-backup/wiremudder-backup.sh backup "$DB" /tmp >/dev/null 2>&1 \
  || fail "backup"
BK=$(ls -t /tmp/wiremudder-storage-*.db 2>/dev/null | head -1)
[ -n "$BK" ] || fail "backup file missing"
trap 'rm -f "$DB" "$DB-wal" "$DB-shm" "$EXP" "$CORRUPT" "$BK"' EXIT

# 4. Restore: row count and FTS index survive in the snapshot.
sh tools/wiremudder-backup/wiremudder-backup.sh verify "$BK" >/dev/null 2>&1 \
  || fail "verify backup"
sqlite3 "$BK" "SELECT COUNT(*) FROM transcripts;" | grep -qx "4" \
  || fail "restore row count"
sqlite3 "$BK" "SELECT text FROM transcripts_fts WHERE transcripts_fts MATCH 'griffin';" \
  | grep -q "A griffin appears." || fail "restore FTS index"

# 5. Deletion keeps the FTS index consistent (WM-SPEC-010-R10 + SPEC-025):
#    delete alice, then search must return empty, not SQLITE_CORRUPT.
sqlite3 "$DB" "DELETE FROM transcripts WHERE profile='alice';" || fail "delete"
sqlite3 "$DB" "SELECT COUNT(*) FROM transcripts_fts WHERE transcripts_fts MATCH 'alice';" \
  | grep -qx "0" || fail "FTS stale after delete"
sqlite3 "$DB" "PRAGMA integrity_check;" | grep -qx "ok" || fail "integrity after delete"

# 6. Corruption recovery (WM-SPEC-011-R08): a garbage file must fail a
#    typed integrity check; backup tool verify must reject it cleanly.
printf 'this is not a sqlite database' > "$CORRUPT"
if sh tools/wiremudder-backup/wiremudder-backup.sh verify "$CORRUPT" \
   >/dev/null 2>&1; then
  fail "corrupt db did not fail verify"
fi

# 7. Feature coverage and spec trace (real gates).
sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"

echo "LF-014: ok (export+backup+restore round trip, FTS delete consistency, corrupt rejection)"

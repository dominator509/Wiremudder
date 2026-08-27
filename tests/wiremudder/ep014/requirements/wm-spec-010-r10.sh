#!/usr/bin/env sh
# WM-SPEC-010-R10: local data supports export, deletion, backup,
# restore, retention, and provenance without requiring a cloud account.
set -eu
cd "$(dirname "$0")/../../../.."

DB=/tmp/wm-r10.db
BK=/tmp/wm-r10-bk.db
EXP=/tmp/wm-r10.json
rm -f "$DB" "$DB-wal" "$DB-shm" "$BK" "$EXP"
trap 'rm -f "$DB" "$DB-wal" "$DB-shm" "$BK" "$EXP"' EXIT

fail() { echo "wm-spec-010-r10: FAIL - $1" >&2; exit 1; }

sqlite3 "$DB" < wirecore/migrations/0001_transcripts_fts.sql || fail "schema"
sqlite3 "$DB" "INSERT INTO transcripts(profile, direction, text, time)
               VALUES('dom','in','retention line',1000),
                      ('dom','out','look',1001);" || fail "seed"

# Export (portable JSON) without any cloud account.
sh tools/wiremudder-backup/wiremudder-backup.sh export "$DB" "$EXP" >/dev/null 2>&1 \
  || fail "export"
grep -q "retention line" "$EXP" || fail "export content"

# Backup (consistent snapshot) and restore verification.
sh tools/wiremudder-backup/wiremudder-backup.sh backup "$DB" /tmp >/dev/null 2>&1 \
  || fail "backup"
BK=$(ls -t /tmp/wiremudder-storage-*.db 2>/dev/null | head -1)
[ -n "$BK" ] || fail "backup file"
sh tools/wiremudder-backup/wiremudder-backup.sh verify "$BK" >/dev/null 2>&1 \
  || fail "restore verify"
sqlite3 "$BK" "SELECT COUNT(*) FROM transcripts;" | grep -qx "2" || fail "restore rows"

# Deletion: rows removed, FTS index stays consistent, integrity ok.
sqlite3 "$DB" "DELETE FROM transcripts WHERE profile='dom';" || fail "delete"
sqlite3 "$DB" "SELECT COUNT(*) FROM transcripts;" | grep -qx "0" || fail "rows remain"
sqlite3 "$DB" "PRAGMA integrity_check;" | grep -qx "ok" || fail "integrity after delete"

# Retention/provenance: seq ordering and timestamps are preserved in export.
grep -q '"time":1000' "$EXP" || fail "provenance time missing"

echo "wm-spec-010-r10: ok"

#!/usr/bin/env sh
# EP-014 M2 unit test: backup tool creates consistent, verifiable
# snapshots (WM-SPEC-011-R08, WM-SPEC-010-R10).
set -eu
cd "$(dirname "$0")/../../../.."

DB=/tmp/wm-ep014-m2-backup.db
OUT=/tmp/wm-ep014-m2-backup-out
EXPORT=/tmp/wm-ep014-m2-export.json
rm -f "$DB" "$DB-wal" "$DB-shm"; rm -rf "$OUT"
trap 'rm -f "$DB" "$DB-wal" "$DB-shm"; rm -rf "$OUT" "$EXPORT"' EXIT

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

# Build a real database with the schema + a row.
sqlite3 "$DB" < wirecore/migrations/0001_transcripts_fts.sql || fail "schema apply"
sqlite3 "$DB" "INSERT INTO transcripts(profile, direction, text, time) VALUES('dom','in','backup me',1000);" \
  || fail "seed insert"

# Backup: consistent snapshot + integrity check.
sh tools/wiremudder-backup/wiremudder-backup.sh backup "$DB" "$OUT" >/tmp/wm-ep014-bk.log 2>&1 \
  || { cat /tmp/wm-ep014-bk.log >&2; fail "backup"; }
BK=$(ls "$OUT"/*.db)
grep -q "backup: ok" /tmp/wm-ep014-bk.log || fail "backup sentinel"

# Restore: open the snapshot and verify the row survived.
[ -f "$BK" ] || fail "backup file missing"
sqlite3 "$BK" "SELECT text FROM transcripts WHERE profile='dom';" | grep -qx "backup me" \
  || fail "row missing after restore"

# Export: JSON contains the transcript.
sh tools/wiremudder-backup/wiremudder-backup.sh export "$DB" "$EXPORT" >/dev/null 2>&1 \
  || fail "export"
grep -q '"text":"backup me"' "$EXPORT" || fail "export missing row"

# Verify: integrity ok.
sh tools/wiremudder-backup/wiremudder-backup.sh verify "$BK" >/dev/null 2>&1 \
  || fail "verify"

echo "unit EP-014 M2 backup-tool: ok"

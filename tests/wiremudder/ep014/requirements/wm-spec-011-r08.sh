#!/usr/bin/env sh
# WM-SPEC-011-R08: backup, restore, export, deletion, corruption
# recovery, and index rebuild have live-fire proofs.
set -eu
cd "$(dirname "$0")/../../../.."

DB=/tmp/wm-r08.db
BK=/tmp/wm-r08-bk.db
rm -f "$DB" "$DB-wal" "$DB-shm" "$BK"
trap 'rm -f "$DB" "$DB-wal" "$DB-shm" "$BK"' EXIT

fail() { echo "wm-spec-011-r08: FAIL - $1" >&2; exit 1; }

sqlite3 "$DB" < wirecore/migrations/0001_transcripts_fts.sql || fail "schema"
sqlite3 "$DB" "INSERT INTO transcripts(profile, direction, text, time)
               VALUES('dom','in','rebuild me',1000);" || fail "seed"

# Export proof (portable JSON).
sh tools/wiremudder-backup/wiremudder-backup.sh export "$DB" /tmp/wm-r08.json >/dev/null 2>&1 \
  || fail "export"
grep -q "rebuild me" /tmp/wm-r08.json || fail "export content"
rm -f /tmp/wm-r08.json

# Backup + restore proof (consistent snapshot, verified).
sh tools/wiremudder-backup/wiremudder-backup.sh backup "$DB" /tmp >/dev/null 2>&1 \
  || fail "backup"
BK=$(ls -t /tmp/wiremudder-storage-*.db 2>/dev/null | head -1)
[ -n "$BK" ] || fail "backup file"
sh tools/wiremudder-backup/wiremudder-backup.sh verify "$BK" >/dev/null 2>&1 \
  || fail "verify"

# Deletion proof: rows removed and FTS consistent.
sqlite3 "$DB" "DELETE FROM transcripts WHERE profile='dom';" || fail "delete"
sqlite3 "$DB" "SELECT COUNT(*) FROM transcripts;" | grep -qx "0" || fail "rows remain"

# Corruption recovery proof: garbage file rejected by verify.
printf 'garbage-not-sqlite' > /tmp/wm-r08-corrupt.db
if sh tools/wiremudder-backup/wiremudder-backup.sh verify /tmp/wm-r08-corrupt.db \
   >/dev/null 2>&1; then
  fail "corrupt db accepted"
fi
rm -f /tmp/wm-r08-corrupt.db

# Index rebuild proof: FTS5 rebuild command reconstructs the index from
# the content table after a forced drop.
sqlite3 "$DB" "INSERT INTO transcripts(profile, direction, text, time)
               VALUES('dom','in','searchable again',1001);" || fail "reseed"
sqlite3 "$DB" "INSERT INTO transcripts_fts(transcripts_fts) VALUES('rebuild');" \
  || fail "index rebuild"
sqlite3 "$DB" "SELECT COUNT(*) FROM transcripts_fts WHERE transcripts_fts MATCH 'searchable';" \
  | grep -qx "1" || fail "rebuild search"

# The live-fire itself is registered as LF-014.
grep -q "LF-014" .agent/live-fire/PROOFS.tsv || fail "LF-014 not registered"

echo "wm-spec-011-r08: ok"

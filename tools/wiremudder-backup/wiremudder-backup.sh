#!/usr/bin/env sh
# WireMudder backup tool (EP-014, WM-SPEC-011-R08, WM-SPEC-010-R10).
# Takes a consistent backup of a WireMudder storage database using
# SQLite's online backup API through the CLI (VACUUM INTO), plus a JSON
# export for portability. Restore = reopen the backup file.
set -eu

usage() {
    echo "usage: wiremudder-backup.sh backup <db> <outdir>" >&2
    echo "       wiremudder-backup.sh export <db> <outfile.json>" >&2
    echo "       wiremudder-backup.sh verify <backup.db>" >&2
    exit 2
}

[ "$#" -ge 2 ] || usage
cmd=$1

case "$cmd" in
  backup)
    [ "$#" -eq 3 ] || usage
    db=$2; outdir=$3
    [ -f "$db" ] || { echo "backup: db not found: $db" >&2; exit 1; }
    mkdir -p "$outdir"
    ts=$(date -u +%Y%m%dT%H%M%SZ)
    out="$outdir/wiremudder-storage-$ts.db"
    # VACUUM INTO creates a consistent snapshot (online backup).
    sqlite3 "$db" "VACUUM INTO '$out';" || { echo "backup: VACUUM INTO failed" >&2; exit 1; }
    sqlite3 "$out" "PRAGMA integrity_check;" | grep -qx "ok" || { echo "backup: integrity check failed" >&2; exit 1; }
    echo "backup: ok $out"
    ;;
  export)
    [ "$#" -eq 3 ] || usage
    db=$2; outfile=$3
    [ -f "$db" ] || { echo "backup: db not found: $db" >&2; exit 1; }
    sqlite3 -json "$db" \
      "SELECT seq, profile, direction, text, time FROM transcripts ORDER BY seq;" \
      > "$outfile" || { echo "backup: export failed" >&2; exit 1; }
    echo "backup: ok export $outfile"
    ;;
  verify)
    [ "$#" -eq 2 ] || usage
    db=$2
    [ -f "$db" ] || { echo "backup: db not found: $db" >&2; exit 1; }
    sqlite3 "$db" "PRAGMA integrity_check;" | grep -qx "ok" \
      || { echo "backup: verify failed" >&2; exit 1; }
    echo "backup: ok verify $db"
    ;;
  *)
    usage
    ;;
esac

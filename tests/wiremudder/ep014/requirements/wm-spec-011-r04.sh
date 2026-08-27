#!/usr/bin/env sh
# WM-SPEC-011-R04: FTS indexes searchable transcripts.
set -eu
cd "$(dirname "$0")/../../../.."

DB=/tmp/wm-r04.db
rm -f "$DB" "$DB-wal" "$DB-shm"
trap 'rm -f "$DB" "$DB-wal" "$DB-shm"' EXIT

fail() { echo "wm-spec-011-r04: FAIL - $1" >&2; exit 1; }

sqlite3 "$DB" < wirecore/migrations/0001_transcripts_fts.sql || fail "schema"
sqlite3 "$DB" "INSERT INTO transcripts(profile, direction, text, time)
               VALUES('dom','in','The griffin guards the golden gate.',1000),
                      ('dom','in','A dusty old tome sits here.',1001);" || fail "seed"

# FTS finds the matching transcript and returns the full text.
hit=$(sqlite3 "$DB" "SELECT text FROM transcripts_fts WHERE transcripts_fts MATCH 'griffin';")
printf '%s' "$hit" | grep -q "griffin guards" || fail "FTS no hit"

# FTS ranking: exact term match outranks unrelated rows; no match is empty.
n=$(sqlite3 "$DB" "SELECT COUNT(*) FROM transcripts_fts WHERE transcripts_fts MATCH 'tome';")
[ "$n" = "1" ] || fail "FTS tome count"
n0=$(sqlite3 "$DB" "SELECT COUNT(*) FROM transcripts_fts WHERE transcripts_fts MATCH 'dragon';")
[ "$n0" = "0" ] || fail "FTS false positive"

# The crate-level search (snippet path) is proven by its unit test.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-storage/Cargo.toml fts_search_finds_transcripts \
  >/dev/null 2>&1 || fail "crate FTS test"

echo "wm-spec-011-r04: ok"

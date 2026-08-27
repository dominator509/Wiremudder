#!/usr/bin/env sh
# EP-014 M2 unit test: migration file + storage schemas are valid and
# versioned (WM-SPEC-011-R07, WM-SPEC-023-R08).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

[ -f wirecore/migrations/0001_transcripts_fts.sql ] || fail "migration 0001 missing"
grep -q "CREATE TABLE IF NOT EXISTS transcripts" wirecore/migrations/0001_transcripts_fts.sql \
  || fail "migration missing transcripts table"
grep -q "fts5" wirecore/migrations/0001_transcripts_fts.sql \
  || fail "migration missing FTS5 index"

[ -f schemas/wiremudder/storage/transcript-export.schema.json ] \
  || fail "transcript export schema missing"
python3 -c "import json; json.load(open('schemas/wiremudder/storage/transcript-export.schema.json'))" \
  || fail "invalid export schema JSON"
python3 - <<'PY' || fail "export schema contract"
import json
s = json.load(open("schemas/wiremudder/storage/transcript-export.schema.json"))
assert s["type"] == "array", "export must be an array"
items = s["items"]
for field in ("seq", "profile", "direction", "text", "time"):
    assert field in items["required"], f"missing {field}"
assert items["properties"]["direction"]["enum"] == ["in", "out", "note"]
print("storage export schema: ok")
PY

echo "unit EP-014 M2 migrations-schemas: ok"

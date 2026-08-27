#!/usr/bin/env sh
# EP-013 M2 unit test: versioned world schemas are valid JSON, carry the
# expected schema_version, and export output conforms to the shape.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

for f in \
  schemas/wiremudder/world/world-graph.schema.json \
  schemas/wiremudder/world/world-event.schema.json \
  schemas/wiremudder/world/derived-fact.schema.json; do
  [ -f "$f" ] || fail "missing schema $f"
  python3 -c "import json,sys; json.load(open('$f'))" || fail "invalid JSON $f"
done

# world-graph schema must be version 1 and require schema_version + rooms.
python3 - "$PWD" <<'PY' || fail "world-graph schema contract"
import json, sys
root = sys.argv[1]
s = json.load(open(f"{root}/schemas/wiremudder/world/world-graph.schema.json"))
assert s["properties"]["schema_version"]["const"] == 1, "schema version"
assert "rooms" in s["required"], "rooms required"
assert "areas" in s["properties"] and "zones" in s["properties"], "areas/zones"
print("schemas world-graph: ok")
PY

# derived-fact schema must carry provenance fields (WM-SPEC-012-R02).
python3 - "$PWD" <<'PY' || fail "derived-fact schema contract"
import json, sys
root = sys.argv[1]
s = json.load(open(f"{root}/schemas/wiremudder/world/derived-fact.schema.json"))
req = set(s["required"])
for field in ("source_event", "time", "scope", "confidence", "sensitivity", "model_version"):
    assert field in req, f"missing {field}"
print("schemas derived-fact: ok")
PY

echo "unit EP-013 M2 world-schemas: ok"

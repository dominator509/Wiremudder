#!/usr/bin/env sh
# EP-018 M2 unit test: agents schemas are valid JSON with stable versions.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

for f in skill-tree memory-permissions council; do
  p="schemas/wiremudder/agents/$f-v1.json"
  [ -f "$p" ] || fail "missing schema $p"
  python3 -c "import json,sys; json.load(open('$p'))" || fail "invalid JSON $p"
  grep -q '"schema_version"' "$p" || fail "schema $p missing schema_version"
done

echo "unit EP-018 M2 agents-schemas: ok"

#!/usr/bin/env sh
# EP-017 M2 unit test: copilot schemas are valid JSON with stable versions.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

for f in suggestion soul why; do
  p="schemas/wiremudder/copilot/$f-v1.json"
  [ -f "$p" ] || fail "missing schema $p"
  python3 -c "import json,sys; json.load(open('$p'))" || fail "invalid JSON $p"
  grep -q '"schema_version"' "$p" || fail "schema $p missing schema_version"
done

echo "unit EP-017 M2 copilot-schemas: ok"

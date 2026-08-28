#!/usr/bin/env sh
# EP-019 M2 unit test: autopilot schemas are valid JSON with stable versions.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

for f in autopilot-config autopilot-status; do
  p="schemas/wiremudder/autopilot/$f-v1.json"
  [ -f "$p" ] || fail "missing schema $p"
  python3 -c "import json,sys; json.load(open('$p'))" || fail "invalid JSON $p"
  grep -q '"schema_version"' "$p" || fail "schema $p missing schema_version"
  grep -q '"const": 1' "$p" || fail "schema $p version not pinned to 1"
done

echo "unit EP-019 M2 autopilot-schemas: ok"

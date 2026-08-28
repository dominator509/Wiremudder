#!/usr/bin/env sh
# EP-022 M2 unit test: debug schemas must exist, be valid JSON, and
# declare the accepted contracts (draft preview-only, replay fixture,
# AI diagnosis self-certified=false, budget sample).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

for s in automation-draft-v1 replay-fixture-v1 ai-diagnosis-v1 budget-sample-v1; do
  f="schemas/wiremudder/debug/$s.json"
  [ -f "$f" ] || fail "missing schema $f"
  python3 -c "import json,sys; json.load(open('$f'))" || fail "invalid JSON in $f"
done

grep -q '"preview_only"' schemas/wiremudder/debug/automation-draft-v1.json || fail "automation-draft lacks preview_only"
grep -q '"self_certified": { "const": false }' schemas/wiremudder/debug/ai-diagnosis-v1.json || fail "ai-diagnosis must pin self_certified=false"
grep -q '"over_budget"' schemas/wiremudder/debug/budget-sample-v1.json || fail "budget-sample lacks over_budget"

echo "unit debug-schemas: ok"

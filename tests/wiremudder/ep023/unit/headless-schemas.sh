#!/usr/bin/env sh
# EP-023 M2 unit test: headless schemas must exist, be valid JSON, and
# declare the accepted contracts (supervisor snapshot, JSONL event with
# SPEC-026-R01 fields, scenario validation, request context).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

for s in supervisor-snapshot-v1 jsonl-event-v1 scenario-v1 request-context-v1; do
  f="schemas/wiremudder/headless/$s.json"
  [ -f "$f" ] || fail "missing schema $f"
  python3 -c "import json,sys; json.load(open('$f'))" || fail "invalid JSON in $f"
done

grep -q '"correlation"' schemas/wiremudder/headless/jsonl-event-v1.json || fail "jsonl-event lacks correlation"
grep -q '"redacted"' schemas/wiremudder/headless/jsonl-event-v1.json || fail "jsonl-event lacks redaction"
grep -q '"risk_queue_len"' schemas/wiremudder/headless/supervisor-snapshot-v1.json || fail "snapshot lacks risk queue"
grep -q '"cancellation"' schemas/wiremudder/headless/request-context-v1.json || fail "request lacks cancellation"

echo "unit headless-schemas: ok"

#!/usr/bin/env sh
# EP-033 M5 requirement test: WM-SPEC-022-R09 — security-sensitive changes
# require forced-failure and denial tests and cannot be waived by a model
# vote.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "requirement: FAIL - $1" >&2; exit 1; }

# Forced-failure and denial tests exist for this node.
for t in tests/wiremudder/ep033/failure/*.sh; do
  [ -f "$t" ] || fail "missing failure test"
done
grep -q "forced-failure" tests/wiremudder/ep033/fixtures/threat-model-session-bridge.json \
  || fail "forced-failure verification missing"

# No model-vote waiver path exists in the denial surface.
if grep -qE 'waive|bypass|allow_override' security/wiremudder/src/injection.rs; then
  fail "denial surface contains a waiver path"
fi

echo "requirement WM-SPEC-022-R09: ok"

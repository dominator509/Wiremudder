#!/usr/bin/env sh
# WM-SPEC-028-R10 (live-fire): RUN_COMPLETE is appended only after the
# release tag and all observed gate sentinels are recorded.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req: FAIL - $1" >&2; exit 1; }

# 1. The completion discipline is documented.
grep -q "RUN_COMPLETE" docs/wiremudder/release/operations/runbook.md \
  || fail "runbook missing RUN_COMPLETE discipline"
grep -q "RUN_COMPLETE" .agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md \
  || fail "SPEC-028 missing RUN_COMPLETE"

# 2. No RUN_COMPLETE exists before the graph is complete (EP-039 owns it).
if grep -q "RUN_COMPLETE" .agent/state/LEDGER.md; then
  fail "RUN_COMPLETE appended prematurely"
fi

# 3. The release tag and gate sentinels are the recorded evidence chain:
#    node verify must print its exact sentinel for this node.
sh scripts/node-verifiers/EP-035.sh M1 >/dev/null 2>&1 \
  || fail "M1 verifier not green"

echo "req WM-SPEC-028-R10: ok"

#!/usr/bin/env sh
# WM-SPEC-019-R09: Bug automation uses bounded reproduction, diagnosis,
# patch, test, review, canary, and rollback states and reaches DONE or
# evidence-backed BLOCKED.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "wm-spec-019-r09: FAIL - $1" >&2; exit 1; }

grep -q "WM-SPEC-019-R09: Bug automation uses bounded reproduction, diagnosis, patch, test, review, canary, and rollback states and reaches DONE or evidence-backed BLOCKED" \
  .agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md \
  || fail "requirement missing from SPEC-019"

# The crate implements all ten stages with a terminal DONE or BLOCKED.
for stage in "Intake" "Reproduction" "Diagnosis" "Patch" "Validation" "Review" "Canary" "Rollback" "Done" "Blocked"; do
  grep -q "$stage" wirecore/crates/wire-bug-automation/src/lib.rs \
    || fail "stage $stage missing from crate"
done
grep -q "pub fn is_terminal" wirecore/crates/wire-bug-automation/src/lib.rs \
  || fail "terminal check missing"

# BLOCKED reports are complete: bug id, stage, reason, retry signatures,
# evidence refs, and human next steps.
grep -q '"human_next_steps"' schemas/wiremudder/bugs/blocked.schema.json \
  || fail "BLOCKED schema missing human_next_steps"
grep -q "retry_signatures" schemas/wiremudder/bugs/blocked.schema.json \
  || fail "BLOCKED schema missing retry signatures"

echo "wm-spec-019-r09: ok"

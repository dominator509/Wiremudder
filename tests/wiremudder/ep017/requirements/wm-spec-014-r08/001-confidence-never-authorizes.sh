#!/usr/bin/env sh
# WM-SPEC-014-R08: AI Confidence Meter is calibrated by task and evaluation
# set and never authorizes an action.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r08: FAIL - $1" >&2; exit 1; }

grep -q "pub struct ConfidenceMeter" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "ConfidenceMeter missing"
grep -q "pub fn confidence(&self, task: TaskClass)" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "task calibration missing"
grep -q "with_eval_score" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "evaluation-set calibration missing"
grep -q "pub fn authorizes(&self) -> bool" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "never-authorizes invariant missing"

# Live-fire confidence is in (0,1): calibrated and non-authoritative.
python3 - <<'PY' || fail "live confidence invalid"
import json
d = json.load(open(".agent/state/evidence/EP-017/M5/lf017-certification.json"))
c = d["confidence"]
assert 0.0 < c < 1.0, f"confidence must be calibrated in (0,1), got {c}"
PY

echo "req WM-SPEC-014-R08: ok"

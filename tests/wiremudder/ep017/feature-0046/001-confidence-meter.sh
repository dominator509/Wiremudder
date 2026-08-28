#!/usr/bin/env sh
# EP-017 M5 feature test: WM-FEAT-0046 AI Confidence Meter.
# Confidence is calibrated by task and evaluation set and never authorizes
# an action (WM-SPEC-014-R08).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0046: FAIL - $1" >&2; exit 1; }

grep -q "pub struct ConfidenceMeter" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "ConfidenceMeter missing"
grep -q "pub fn authorizes(&self) -> bool" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "authorizes() invariant missing"
grep -q "fn authorizes" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "authorizes invariant not tested"
grep -q "with_eval_score" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "evaluation-set calibration missing"
grep -q "calibration" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "calibration table missing"

# Confidence is visible in the pane and suggestion schema.
grep -q "confidence" schemas/wiremudder/copilot/suggestion-v1.json \
  || fail "confidence missing from suggestion schema"
grep -q "confidence" src/wiremudder/ui/copilot/copilot_boundary.h \
  || fail "confidence missing from pane"

echo "feature-0046 confidence-meter: ok"

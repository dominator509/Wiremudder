#!/usr/bin/env sh
# EP-017 M5 feature test: WM-FEAT-0047 AI Why explanations.
# Why cites observations, memory, policy, uncertainty, and rejected
# alternatives without exposing chain-of-thought or secrets (R09).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0047: FAIL - $1" >&2; exit 1; }

grep -q "pub struct WhyExplanation" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "WhyExplanation missing"
grep -q "rejected_alternatives" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "rejected alternatives missing"
grep -q "Redactor" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "redactor missing from Why"
grep -q "evidence" schemas/wiremudder/copilot/why-v1.json \
  || fail "evidence missing from why schema"
grep -q "rejected_alternatives" schemas/wiremudder/copilot/why-v1.json \
  || fail "rejected alternatives missing from why schema"

# Why is rendered in the live-fire and contains no secrets.
sh tests/live-fire/LF-017-copilot-suggestion-explanation.sh >/dev/null 2>&1 \
  || fail "LF-017 live-fire for why"
python3 - <<'PY' || fail "why evidence invalid"
import json
d = json.load(open(".agent/state/evidence/EP-017/M5/lf017-certification.json"))
assert d["why_nonempty"] is True
assert d["citations"] >= 1
assert d["privacy_leak_count"] == 0
PY

echo "feature-0047 why-explanations: ok"

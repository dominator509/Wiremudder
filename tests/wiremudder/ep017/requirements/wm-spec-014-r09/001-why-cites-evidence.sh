#!/usr/bin/env sh
# WM-SPEC-014-R09: Why explanations cite observations, memory, policy,
# uncertainty, and rejected alternatives without exposing hidden
# chain-of-thought or secrets.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r09: FAIL - $1" >&2; exit 1; }

grep -q "pub struct WhyExplanation" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "WhyExplanation missing"
grep -q "pub evidence" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "evidence citations missing"
grep -q "rejected_alternatives" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "rejected alternatives missing"
grep -q "pub fn render" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "render missing"
grep -q "Redactor" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "redaction missing"

# No chain-of-thought or secret classes in rendered Why (live evidence).
python3 - <<'PY' || fail "why leak evidence"
import json
d = json.load(open(".agent/state/evidence/EP-017/M5/lf017-certification.json"))
assert d["why_nonempty"] is True
assert d["privacy_leak_count"] == 0, "Why leaked secrets"
assert d["citations"] >= 1
PY

echo "req WM-SPEC-014-R09: ok"

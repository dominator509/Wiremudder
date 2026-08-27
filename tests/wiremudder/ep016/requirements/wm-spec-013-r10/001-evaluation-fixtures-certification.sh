#!/usr/bin/env sh
# WM-SPEC-013-R10: evaluation fixtures compare quality, privacy leakage,
# latency, cancellation, cost, and fallback behavior before provider
# certification. The LF-016 certification evidence is the live-fire proof.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r10: FAIL - $1" >&2; exit 1; }

# Evaluation fixture logic (unit-level, deterministic).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml 2>&1 \
  | grep -q "21 passed" || fail "router unit invariants"

# The certification evidence carries real measured values from LF-016.
EVIDENCE=.agent/state/evidence/EP-016/M5/lf016-certification.json
[ -f "$EVIDENCE" ] || fail "missing certification evidence"
python3 - "$EVIDENCE" <<'PY' || fail "invalid certification evidence"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["certified"] is True
assert d["completion_latency_ms"] > 0
assert d["stream_chunks"] > 0
assert d["privacy_leak_count"] == 0
assert d["fallback_count"] == 0
assert d["quality_score"] >= d["baseline_quality"]
PY

# The certified local route references that evidence.
grep -q "certification_evidence" config/wiremudder/providers/routing-policy.example.json \
  || fail "routing policy missing certification evidence reference"

echo "req WM-SPEC-013-R10: ok"

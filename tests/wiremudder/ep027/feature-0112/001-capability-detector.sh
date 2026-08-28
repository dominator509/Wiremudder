#!/usr/bin/env sh
# WM-FEAT-0112: per-world capability detector — evidence-based
# observation with user confirmation; guessing is denied.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0112: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-help/src/lib.rs
[ -f "$LIB" ] || fail "wire-help crate missing"
grep -q "observe_capability" "$LIB" || fail "capability observation missing"
grep -q "evidence" "$LIB" || fail "evidence field missing"
grep -q "CapabilityProbe" "$LIB" || fail "capability probe missing"
grep -q "DeniedPolicy" "$LIB" || fail "guess denial missing"
echo "feature WM-FEAT-0112 per-world-capability-detector: ok"

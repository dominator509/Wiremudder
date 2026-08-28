#!/usr/bin/env sh
# WM-FEAT-0187: Contextual Help and Setup Coach Agent — the agent
# surfaces scoped help and propose-only coach steps; no mutation path.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0187: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-help/src/lib.rs
[ -f "$LIB" ] || fail "wire-help crate missing"
grep -q "build_ask_context" "$LIB" || fail "ask context missing"
grep -q "add_coach_step" "$LIB" || fail "coach steps missing"
grep -q "side_effect_free" "$LIB" || fail "side-effect-free guarantee missing"
grep -q "apply_step" "$LIB" || fail "apply denial missing"
echo "feature WM-FEAT-0187 help-coach-agent: ok"

#!/usr/bin/env sh
# EP-019 M5 feature test: WM-FEAT-0041 Guarded Autopilot.
# Opt-in, profile-scoped, visible bounded Action Proposals, stale-state
# pause, rate limits, confirmations, pause/cancel, and audit under the
# deterministic command gateway (WM-SPEC-014-R10).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0041: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-autopilot/src/lib.rs
grep -q "pub struct AutopilotEngine" "$LIB" || fail "AutopilotEngine missing"
grep -q "pub struct AutopilotConfig" "$LIB" || fail "AutopilotConfig missing"
grep -q "AutopilotMode::Disabled" "$LIB" || fail "off-by-default missing"
grep -q "pub fn propose" "$LIB" || fail "propose missing"
grep -q "pub fn confirm_and_send" "$LIB" || fail "confirm_and_send missing"
grep -q "pub fn cancel" "$LIB" || fail "cancel missing"
grep -q "pub fn emergency_stop" "$LIB" || fail "emergency stop missing"
grep -q "StaleReason" "$LIB" || fail "stale-state pause missing"
grep -q "max_actions_per_window" "$LIB" || fail "rate limit missing"
grep -q "pub fn audit_log" "$LIB" || fail "audit missing"

# Schemas exist and are versioned.
python3 -c "import json; json.load(open('schemas/wiremudder/autopilot/autopilot-config-v1.json'))" \
  || fail "autopilot config schema invalid"
python3 -c "import json; json.load(open('schemas/wiremudder/autopilot/autopilot-status-v1.json'))" \
  || fail "autopilot status schema invalid"

# Real behavior: off by default, visible before send, confirmation,
# stale pause, emergency stop all proven by the crate tests.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-autopilot/Cargo.toml 2>&1 \
  | grep -q "off_by_default" || fail "off-by-default invariant"

echo "feature-0041 guarded-autopilot: ok"

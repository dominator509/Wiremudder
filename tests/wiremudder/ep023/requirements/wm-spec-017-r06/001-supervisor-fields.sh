#!/usr/bin/env sh
# WM-SPEC-017-R06: Headless Supervisor shows session state, room, last
# command, AI/autopilot state, risk queue, route label, token spend,
# health, and emergency stop.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "pub struct SupervisorSnapshot" "$LIB" || fail "snapshot missing"
grep -q "pub state" "$LIB" || fail "state missing"
grep -q "pub room" "$LIB" || fail "room missing"
grep -q "pub last_command" "$LIB" || fail "last command missing"
grep -q "pub ai_state" "$LIB" || fail "AI state missing"
grep -q "pub autopilot_state" "$LIB" || fail "autopilot state missing"
grep -q "pub risk_queue_len" "$LIB" || fail "risk queue missing"
grep -q "pub route_label" "$LIB" || fail "route label missing"
grep -q "pub token_spend" "$LIB" || fail "token spend missing"
grep -q "pub health" "$LIB" || fail "health missing"
grep -q "emergency_stop" "$LIB" || fail "emergency stop missing"
echo "requirement WM-SPEC-017-R06 supervisor-fields: ok"

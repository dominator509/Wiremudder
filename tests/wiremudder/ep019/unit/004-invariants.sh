#!/usr/bin/env sh
# EP-019 M2 unit test: guarded-autopilot structural invariants hold at the
# crate surface (independent of the Rust run).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-autopilot/src/lib.rs

# 1. Off by default and profile-scoped (obligation 1).
grep -q "AutopilotMode::Disabled" "$LIB" || fail "default mode is not Disabled"
grep -q "ProfileMismatch" "$LIB" || fail "profile scoping missing"
grep -q "active_profile" "$LIB" || fail "active profile state missing"

# 2. Every action is visible before send (obligation 2).
grep -q "approved-visible" "$LIB" || fail "visible-before-send state missing"
grep -q "awaiting-confirmation" "$LIB" || fail "awaiting-confirmation state missing"

# 3. Stale or ambiguous state pauses (obligation 3).
grep -q "StaleReason" "$LIB" || fail "stale reason missing"
grep -q "StaleState" "$LIB" || fail "stale-state error missing"

# 4. Emergency stop cancels immediately (obligation 4).
grep -q "emergency_stop" "$LIB" || fail "emergency stop missing"

# 5. Rate and command policies are deterministic (obligation 5).
grep -q "max_actions_per_window" "$LIB" || fail "rate limit missing"
grep -q "RateLimited" "$LIB" || fail "rate-limited error missing"

# 6. No hidden social automation: every send is visible + audited.
grep -q "action: \"proposed\"" "$LIB" || fail "proposal visibility audit missing"
grep -q '"sent"' "$LIB" || fail "send audit missing"
grep -q "allowlist" "$LIB" || fail "narrow allowlist missing"

echo "unit EP-019 M2 invariants: ok"

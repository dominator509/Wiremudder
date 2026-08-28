#!/usr/bin/env sh
# WM-SPEC-020-R07: Updates and migrations defer during active sessions
# unless the user explicitly stops sessions and approves.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "wm-spec-020-r07: FAIL - $1" >&2; exit 1; }

grep -q "WM-SPEC-020-R07: Updates and migrations defer during active sessions unless the user explicitly stops sessions and approves" \
  .agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md \
  || fail "requirement missing from SPEC-020"

# The crate enforces the deferral.
grep -q "pub fn assert_migration_allowed" wirecore/crates/wire-import/src/lib.rs \
  || fail "session-defer gate missing from crate"
grep -q "session_active" wirecore/crates/wire-import/src/lib.rs \
  || fail "session_active error code missing from crate"

# Unit test proves both sides of the gate.
grep -q "fn migration_defers_during_active_sessions" wirecore/crates/wire-import/src/lib.rs \
  || fail "session-defer unit test missing"

echo "wm-spec-020-r07: ok"

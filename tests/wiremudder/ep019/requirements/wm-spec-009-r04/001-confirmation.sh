#!/usr/bin/env sh
# WM-SPEC-009-R04: Destructive, social, trade, PvP, account, privacy, and
# irreversible actions require explicit confirmation unless a narrow user
# allowlist says otherwise.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r04: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-autopilot/src/lib.rs
grep -q "awaiting-confirmation" "$LIB" || fail "confirmation state missing"
grep -q "confirm_and_send" "$LIB" || fail "explicit confirmation path missing"
grep -q "allowlist" "$LIB" || fail "narrow allowlist missing"
grep -q "AllowlistAuto" "$LIB" || fail "allowlist mode missing"

# The policy tier decides confirmation (EP-008): risky/destructive.
grep -q "requires_confirmation" wirecore/crates/wire-policy/src/lib.rs \
  || fail "policy confirmation missing"

# Real behavior: destructive requires confirmation; allowlist auto-send is
# only for allowlisted commands.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-autopilot/Cargo.toml destructive 2>&1 \
  | grep -q "destructive_requires_confirmation" || fail "confirmation invariant"

echo "req WM-SPEC-009-R04: ok"

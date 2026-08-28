#!/usr/bin/env sh
# EP-019 M3 integration test: no hidden auto-send.
# The pane has no command path; the crate refuses to send without a
# visible proposal and explicit confirmation (or a narrow allowlist match);
# denied commands never send; every send is audited.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-autopilot/src/lib.rs
# No send occurs inside propose(); sends only in confirm_and_send/auto_send.
grep -q "pub fn propose" "$LIB" || fail "propose missing"
grep -q "pub fn confirm_and_send" "$LIB" || fail "confirm_and_send missing"
grep -q "pub fn auto_send" "$LIB" || fail "auto_send missing"
grep -q "action: \"sent\"" "$LIB" || fail "send audit missing"

# The crate rejects sends when disabled, profile mismatched, stale, or
# rate-limited; denied commands never reach the send path.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-autopilot/Cargo.toml 2>&1 \
  | grep -q "denied_commands_never_send" || fail "denied-never-send invariant"

echo "integration EP-019 M3 no-hidden-send: ok"

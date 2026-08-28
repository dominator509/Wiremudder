#!/usr/bin/env sh
# EP-025 M4 security test: provenance, injection, asset-trust, and
# permission boundaries for the retro renderer. Fails unless every
# required security proof is true (SPEC-016, SPEC-022, node contract):
# protected assets rejected, metadata validated, injection treated as
# data, no command path, no scope-grant surface.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-renderer/Cargo.toml \
  --example security_matrix 2>&1 | tee /tmp/ep025_security.log

grep -q "security matrix EP-025: ok 5/5" /tmp/ep025_security.log || fail "security matrix not green"

for n in 1 2 3 4 5; do
  grep -q "security-$n " /tmp/ep025_security.log || fail "security proof $n missing"
done

# The renderer boundary must never gain a command path.
BOUNDARY=src/wiremudder/ui/renderer/renderer_boundary.h
grep -q "canSendCommand() const { return false; }" "$BOUNDARY" || fail "renderer boundary has command path"
grep -q "canEditGates() const { return false; }" "$BOUNDARY" || fail "renderer boundary can edit gates"

echo "security EP-025 M4 matrix: ok"

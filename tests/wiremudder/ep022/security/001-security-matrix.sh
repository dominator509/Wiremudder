#!/usr/bin/env sh
# EP-022 M4 security test: prompt injection, secrets, permission denial,
# gate-editing resistance through the real wire-debugger crate.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-debugger/Cargo.toml \
  --example security_matrix 2>&1 | tee /tmp/ep022_security_matrix.log
grep -q "security matrix: 5 controls exercised, all closed" /tmp/ep022_security_matrix.log \
  || fail "security matrix did not complete"

# Pane-level security: no command path, no gate editing, private redaction.
HDR=src/wiremudder/ui/power-tools/power_tools_boundary.h
grep -q "canSendCommand() const { return false; }" "$HDR" || fail "pane has command path"
grep -q "canEditGates() const { return false; }" "$HDR" || fail "pane can edit gates"
grep -q '"<redacted>"' "$HDR" || fail "pane lacks redacted marker"

echo "security EP-022 M4 security-matrix: ok"

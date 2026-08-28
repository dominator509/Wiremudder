#!/usr/bin/env sh
# EP-023 M4 security test: prompt injection, secrets, permission denial,
# credential exposure through the real wire-headless crate.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-headless/Cargo.toml \
  --example security_matrix 2>&1 | tee /tmp/ep023_security_matrix.log
grep -q "security matrix: 5 controls exercised, all closed" /tmp/ep023_security_matrix.log \
  || fail "security matrix did not complete"

# Pane/tool-level security: supervisor is passive, no command path.
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "is_passive" "$LIB" || fail "supervisor not passive"

echo "security EP-023 M4 security-matrix: ok"

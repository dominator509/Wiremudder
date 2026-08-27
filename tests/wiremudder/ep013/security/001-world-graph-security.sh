#!/usr/bin/env sh
# EP-013 M4 security test: secrets, denied policy, injection, integrity.
# Real controlled checks over the wire-world-graph crate.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

[ -x /root/.cargo/bin/cargo ] || fail "cargo missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-world-graph/Cargo.toml \
  --example security_matrix > /tmp/wm-ep013-m4-security.txt 2>/dev/null \
  || fail "security matrix"

grep -q "secrets-classified:ok" /tmp/wm-ep013-m4-security.txt || fail "secret classification"
grep -q "denied-policy:ok" /tmp/wm-ep013-m4-security.txt || fail "denied policy"
grep -q "injection-as-data:ok" /tmp/wm-ep013-m4-security.txt || fail "injection as data"
grep -q "integrity-tamper:ok" /tmp/wm-ep013-m4-security.txt || fail "tamper rejection"

echo "security EP-013 M4 world-graph: ok"

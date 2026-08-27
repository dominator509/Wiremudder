#!/usr/bin/env sh
# EP-013 M2 unit test: wire-world-graph crate deterministic invariants.
# Runs the real Rust crate's unit test suite (17 tests: routing, exits,
# zones, facts, corrections, cache, import/export).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

[ -x /root/.cargo/bin/cargo ] || fail "cargo missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-graph/Cargo.toml \
  > /tmp/wg-m2-unit.log 2>&1 || { tail -20 /tmp/wg-m2-unit.log >&2; fail "cargo test"; }
grep -q "test result: ok" /tmp/wg-m2-unit.log \
  || { tail -20 /tmp/wg-m2-unit.log >&2; fail "no passing test summary"; }
passed=$(grep -oE "test result: ok\. [0-9]+ passed" /tmp/wg-m2-unit.log | head -1 | grep -oE "[0-9]+" || echo 0)
[ "$passed" -ge 17 ] \
  || { tail -20 /tmp/wg-m2-unit.log >&2; fail "expected at least 17 passing tests, got $passed"; }

echo "unit EP-013 M2 world-graph: ok"

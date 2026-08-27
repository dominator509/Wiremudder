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
grep -q "test result: ok. 17 passed" /tmp/wg-m2-unit.log \
  || { tail -20 /tmp/wg-m2-unit.log >&2; fail "expected 17 passing tests"; }

echo "unit EP-013 M2 world-graph: ok"

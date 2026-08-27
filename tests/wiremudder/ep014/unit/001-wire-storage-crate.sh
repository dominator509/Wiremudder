#!/usr/bin/env sh
# EP-014 M2 unit test: wire-storage crate deterministic invariants.
# Runs the real crate's unit tests (append, FTS search, migrations,
# write queue, export/delete, integrity).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

[ -x /root/.cargo/bin/cargo ] || fail "cargo missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-storage/Cargo.toml \
  > /tmp/ws-m2-unit.log 2>&1 || { tail -20 /tmp/ws-m2-unit.log >&2; fail "cargo test"; }
grep -q "test result: ok" /tmp/ws-m2-unit.log \
  || { tail -20 /tmp/ws-m2-unit.log >&2; fail "no passing test summary"; }
passed=$(grep -oE "test result: ok\. [0-9]+ passed" /tmp/ws-m2-unit.log | head -1 | grep -oE "[0-9]+" || echo 0)
[ "$passed" -ge 8 ] \
  || { tail -20 /tmp/ws-m2-unit.log >&2; fail "expected at least 8 passing tests, got $passed"; }

echo "unit EP-014 M2 wire-storage: ok"

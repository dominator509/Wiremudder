#!/usr/bin/env sh
# EP-030 M2 unit test: the wire-import crate builds and passes its
# deterministic unit suite (SPEC-021: format detection, hashing, traversal
# and size bounds, disabled automation, conflict/unsupported reporting,
# session-defer, rollback).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

log=$(mktemp /tmp/ep030_import_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" test \
  --manifest-path wirecore/crates/wire-import/Cargo.toml >"$log" 2>&1 || {
  cat "$log" >&2
  fail "wire-import tests failed"
}
grep -q "14 passed" "$log" || fail "expected 14 passing tests in wire-import"

echo "unit wire-import: ok"

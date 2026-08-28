#!/usr/bin/env sh
# EP-034 M2 unit test: the wire-updater crate builds with zero warnings and
# passes its deterministic unit suite (SPEC-020 signed manifest verification,
# channel/lane policy, staged rollout, resumable downloads, permission
# expansion rejection, migration planning, active-session deferral,
# quarantine/rollback, version ordering, size limits).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

# 1. Build must be warning-free (SPEC-027 zero-warning gate).
build_log=$(mktemp /tmp/ep034_build_XXXX.log)
"$cargo_bin" build --quiet --manifest-path wirecore/crates/wire-updater/Cargo.toml \
  >"$build_log" 2>&1 || { cat "$build_log" >&2; fail "wire-updater build failed"; }
if grep -q "^warning" "$build_log"; then
  cat "$build_log" >&2
  fail "wire-updater build emitted warnings"
fi

# 2. Deterministic unit suite must pass.
test_log=$(mktemp /tmp/ep034_test_XXXX.log)
"$cargo_bin" test --quiet --manifest-path wirecore/crates/wire-updater/Cargo.toml \
  >"$test_log" 2>&1 || { cat "$test_log" >&2; fail "wire-updater tests failed"; }
grep -q "17 passed" "$test_log" || { cat "$test_log" >&2; fail "expected 17 tests to pass"; }

echo "unit EP-034 wire-updater-core: ok"

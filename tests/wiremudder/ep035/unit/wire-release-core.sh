#!/usr/bin/env sh
# EP-035 M2 unit test: the wire-release crate builds with zero warnings and
# passes its deterministic unit suite (SPEC-020-R01 channels, SPEC-028-R05
# artifact completeness, SPEC-020-R09 agent-signing boundary, SPEC-028-R07
# rollout revocation, SPEC-028-R09 sync rehearsal, checksums, provenance).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

# 1. Warning-free build.
build_log=$(mktemp /tmp/ep035_build_XXXX.log)
"$cargo_bin" build --quiet --manifest-path packaging/wiremudder/Cargo.toml \
  >"$build_log" 2>&1 || { cat "$build_log" >&2; fail "wire-release build failed"; }
if grep -q "^warning" "$build_log"; then
  cat "$build_log" >&2
  fail "wire-release build emitted warnings"
fi

# 2. Deterministic unit suite.
test_log=$(mktemp /tmp/ep035_test_XXXX.log)
"$cargo_bin" test --quiet --manifest-path packaging/wiremudder/Cargo.toml \
  >"$test_log" 2>&1 || { cat "$test_log" >&2; fail "wire-release tests failed"; }
grep -q "9 passed" "$test_log" || { cat "$test_log" >&2; fail "expected 9 tests to pass"; }

echo "unit EP-035 wire-release-core: ok"

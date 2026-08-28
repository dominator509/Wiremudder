#!/usr/bin/env sh
# EP-022 M2 unit test: wire-debugger crate must compile and all
# deterministic unit tests must pass.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

cd wirecore/crates/wire-debugger
out=$("$cargo_bin" test 2>&1) || fail "cargo test failed: $out"

count=$(echo "$out" | grep -c "^test result: ok" || true)
[ "$count" -ge 1 ] || fail "no passing test result"
echo "$out" | grep "^test result: ok" | head -1

echo "unit wire-debugger: ok"

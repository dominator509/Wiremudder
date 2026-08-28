#!/usr/bin/env sh
# EP-033 M2 unit test: the wiremudder-security crate builds with zero
# warnings and passes its deterministic unit suite (SPEC-022 threat model,
# secrets scan, prompt-injection guard, supply-chain inventory, SBOM,
# license inventory, update lanes, release blocking).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

export CARGO_TARGET_DIR="$PWD/wirecore/target"
out=$(mktemp /tmp/ep033_cargo_XXXX.log)
"$cargo_bin" test --manifest-path security/wiremudder/Cargo.toml >"$out" 2>&1 || {
  cat "$out" >&2
  fail "cargo test failed"
}
grep -q "33 passed" "$out" || fail "expected 33 passing security unit tests"

# Zero warnings on the lib+bin build.
warn=$(grep -cE '^warning' "$out" || true)
[ "$warn" -eq 0 ] || fail "build produced warnings: $warn"

echo "unit wiremudder-security: ok"

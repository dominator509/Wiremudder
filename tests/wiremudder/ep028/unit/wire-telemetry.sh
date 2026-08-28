#!/usr/bin/env sh
# EP-028 M2 unit test: wire-telemetry — off by default, bounded ring
# buffers, redaction corpus, fingerprints, coalescing, journal recovery.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

log=$(mktemp /tmp/ep028_telemetry_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" test \
  --manifest-path wirecore/crates/wire-telemetry/Cargo.toml >"$log" 2>&1 || {
  cat "$log" >&2
  fail "wire-telemetry tests failed"
}
grep -q "11 passed" "$log" || fail "expected 11 passing tests in wire-telemetry"

echo "unit wire-telemetry: ok"

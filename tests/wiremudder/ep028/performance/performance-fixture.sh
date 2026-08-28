#!/usr/bin/env sh
# EP-028 M4 performance test: the real performance fixture must run
# through the production wire-telemetry and wire-replay crates and stay
# within the SPEC-004 budget (5 ms; bounded ring writes only on hot
# paths, compression/export are P4).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

out=$(mktemp /tmp/ep028_perf_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" run --release \
  --manifest-path wirecore/crates/wire-replay/Cargo.toml \
  --example perf_fixture >"$out" 2>&1 || {
  cat "$out" >&2
  fail "performance fixture did not run"
}

grep -q "perf ring-record:" "$out" || fail "ring-record measurement missing"
grep -q "perf ring-raw:" "$out" || fail "ring-raw measurement missing"
grep -q "perf redaction:" "$out" || fail "redaction measurement missing"
grep -q "perf replay-hash:" "$out" || fail "replay-hash measurement missing"
grep -q "perf bundle-build:" "$out" || fail "bundle-build measurement missing"
grep -q "budget_us=5000" "$out" || fail "budget line missing"
grep -q "perf fixture EP-028: ok" "$out" || fail "perf fixture not ok"

echo "performance EP-028 fixture: ok"

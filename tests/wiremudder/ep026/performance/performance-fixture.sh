#!/usr/bin/env sh
# EP-026 M4 performance test: the real performance fixture must run
# through the production wire-soundscape crate and stay within the
# SPEC-004 budgets (P3 op 5 ms; P0 emergency stop 10 ms).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

out=$(mktemp /tmp/ep026_perf_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" run --release \
  --manifest-path wirecore/crates/wire-soundscape/Cargo.toml \
  --example perf_fixture >"$out" 2>&1 || {
  cat "$out" >&2
  fail "performance fixture did not run"
}

grep -q "perf request-play:" "$out" || fail "request-play measurement missing"
grep -q "perf tick-coalesce:" "$out" || fail "tick measurement missing"
grep -q "perf transition-start:" "$out" || fail "transition measurement missing"
grep -q "perf studio-control:" "$out" || fail "studio-control measurement missing"
grep -q "perf asset-provenance:" "$out" || fail "asset-provenance measurement missing"
grep -q "perf emergency-stop:" "$out" || fail "emergency-stop measurement missing"
grep -q "perf worst_case_us=.*budget_us=5000" "$out" || fail "P3 op budget line missing"
grep -q "emergency_stop_us=.*budget_us=10000" "$out" || fail "P0 e-stop budget line missing"
grep -q "perf fixture EP-026: ok" "$out" || fail "perf fixture not ok"

echo "performance EP-026 fixture: ok"

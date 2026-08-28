#!/usr/bin/env sh
# EP-027 M4 performance test: the real performance fixture must run
# through the production wire-help crate and stay within the SPEC-004
# budget (5 ms; help never blocks settings or gameplay).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

out=$(mktemp /tmp/ep027_perf_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" run --release \
  --manifest-path wirecore/crates/wire-help/Cargo.toml \
  --example perf_fixture >"$out" 2>&1 || {
  cat "$out" >&2
  fail "performance fixture did not run"
}

grep -q "perf index-add:" "$out" || fail "index-add measurement missing"
grep -q "perf answer-lookup:" "$out" || fail "answer-lookup measurement missing"
grep -q "perf ask-context:" "$out" || fail "ask-context measurement missing"
grep -q "perf coach-propose:" "$out" || fail "coach-propose measurement missing"
grep -q "perf source-index-scan:" "$out" || fail "source-index measurement missing"
grep -q "perf cli-help:" "$out" || fail "cli-help measurement missing"
grep -q "perf worst_case_us=.*budget_us=5000" "$out" || fail "lookup budget line missing"
grep -q "perf fixture EP-027: ok" "$out" || fail "perf fixture not ok"

echo "performance EP-027 fixture: ok"

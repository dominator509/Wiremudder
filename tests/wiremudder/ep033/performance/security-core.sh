#!/usr/bin/env sh
# EP-033 M4 performance test: real measured distribution for the security
# core hot paths, within the SPEC-004 budget (P3, 1ms).
#
# Drives the crate's perf fixture and asserts the observed p50/p95/max and
# budget, writing raw evidence.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

out=$(mktemp /tmp/ep033_perf_XXXX.log)
"$cargo_bin" run --quiet --release --manifest-path security/wiremudder/Cargo.toml \
  --example perf_fixture >"$out" 2>&1 || {
  cat "$out" >&2
  fail "perf fixture run failed"
}
grep -q "^perf security:" "$out" || fail "perf sentinel missing"

python3 - "$out" <<'PY' || fail "perf distribution check failed"
import re, sys
out = open(sys.argv[1]).read()
m = re.search(r"perf security: p50_us=(\d+) p95_us=(\d+) max_us=(\d+) budget_us=(\d+)", out)
assert m, "perf line missing"
p50, p95, mx, budget = map(int, m.groups())
assert p95 <= budget, f"p95 {p95}us over budget {budget}us"
assert mx <= budget, f"max {mx}us over budget {budget}us"
print(f"perf security: p50={p50}us p95={p95}us max={mx}us budget={budget}us OK")
PY

echo "performance EP-033 security-core: ok"

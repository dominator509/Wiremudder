#!/usr/bin/env sh
# EP-034 M4 performance test: real measured distribution for the secure
# updater hot paths, within the SPEC-004 budget (P4, 1 ms).
#
# Drives the crate's perf fixture and asserts the observed p50/p95/max and
# budget, writing raw evidence.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

out=$(mktemp /tmp/ep034_perf_XXXX.log)
"$cargo_bin" run --quiet --release --manifest-path wirecore/crates/wire-updater/Cargo.toml \
  --example perf_fixture >"$out" 2>&1 || {
  cat "$out" >&2
  fail "perf fixture run failed"
}
grep -q "^perf updater:" "$out" || fail "perf sentinel missing"

python3 - "$out" <<'PY' || fail "perf distribution check failed"
import re, sys
out = open(sys.argv[1]).read()
m = re.search(r"perf updater: p50_us=(\d+) p95_us=(\d+) max_us=(\d+) budget_us=(\d+) samples=(\d+)", out)
assert m, "perf line missing"
p50, p95, mx, budget, samples = map(int, m.groups())
assert samples >= 1000, f"too few samples: {samples}"
assert p95 <= budget, f"p95 {p95}us over budget {budget}us"
assert mx <= budget, f"max {mx}us over budget {budget}us"
print(f"perf updater: p50={p50}us p95={p95}us max={mx}us budget={budget}us samples={samples} OK")
PY

echo "performance EP-034 updater-core: ok"

#!/usr/bin/env sh
# EP-032 M4 performance test: re-run the full perf-capture suite and
# verify every owned subsystem stays inside its declared regression
# threshold (SPEC-004-R12, SPEC-027-R06). This is the live regression
# gate: p95 over budget fails the node.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

out=$(mktemp /tmp/ep032_perf_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" run --quiet --release \
  --manifest-path tools/perf-capture/Cargo.toml -- \
  --suite ep032 --out tools/perf-capture/artifacts >"$out" 2>&1 || {
  cat "$out" >&2
  fail "perf-capture run failed"
}
grep -q "perf-capture: ok" "$out" || fail "perf-capture sentinel missing"

# Verify the artifact's regression thresholds hold (p95 within budget).
artifact=tools/perf-capture/artifacts/ep032-perf-raw.json
python3 - "$artifact" <<'PY' || fail "regression threshold check failed"
import json, sys
a = json.load(open(sys.argv[1]))
runs = {r["queue"]: r for r in a["runs"]}
assert len(runs) >= 6, "expected >=6 runs"
for q, r in runs.items():
    assert r["budget_met"] is True, f"queue {q} over budget: {r}"
    assert r["p95_us"] <= r["budget_us"], f"queue {q} p95 over threshold"
    print(f"  {q:24s} p95={r['p95_us']:>5}us max={r['max_us']:>5}us budget={r['budget_us']}us met={r['budget_met']}")
PY

echo "performance EP-032 regression-gate: ok"

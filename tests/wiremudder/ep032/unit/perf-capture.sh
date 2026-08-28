#!/usr/bin/env sh
# EP-032 M2 unit test: the perf-capture tool runs the owned crate perf
# fixtures reproducibly and writes a real SPEC-004-R12 raw artifact with
# hardware profile, workload, distributions, and regression thresholds.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

out=$(mktemp /tmp/ep032_perfcapture_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" run --quiet --release \
  --manifest-path tools/perf-capture/Cargo.toml -- \
  --suite ep032 --out tools/perf-capture/artifacts >"$out" 2>&1 || {
  cat "$out" >&2
  fail "perf-capture run failed"
}
grep -q "perf-capture: ok" "$out" || fail "perf-capture sentinel missing"

artifact=tools/perf-capture/artifacts/ep032-perf-raw.json
[ -f "$artifact" ] || fail "missing raw artifact $artifact"

python3 - "$artifact" "$out" <<'PY' || fail "raw artifact check failed"
import json, sys
artifact = json.load(open(sys.argv[1]))
out = open(sys.argv[2]).read()
assert artifact.get("suite") == "ep032", "suite mismatch"
assert artifact.get("raw_evidence") is True, "raw_evidence must be true"
hw = artifact.get("hardware", {})
assert hw.get("arch"), "hardware arch missing"
assert hw.get("os"), "hardware os missing"
runs = artifact.get("runs", [])
assert len(runs) >= 6, f"expected >=6 runs, got {len(runs)}"
for r in runs:
    assert "p50_us" in r and "p95_us" in r and "max_us" in r, f"distribution missing in {r}"
    assert "budget_met" in r, f"budget_met missing in {r}"
    assert r["budget_met"] is True, f"budget not met: {r}"
    assert "p50_us" in r and "p95_us" in r and "max_us" in r
    assert r["p95_us"] <= r["budget_us"], f"p95 over budget: {r}"
thr = artifact.get("regression_thresholds", [])
assert len(thr) >= 6, f"expected >=6 regression thresholds, got {len(thr)}"
assert any("p95_us_limit" in t for t in thr), "regression thresholds missing p95 limit"
print(f"artifact runs={len(runs)} thresholds={len(thr)} all budgets met")
PY

echo "unit perf-capture: ok"

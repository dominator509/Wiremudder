#!/usr/bin/env sh
# EP-032 M3 integration test: the perf-capture tool drives the real owned
# crate perf fixtures end to end (release builds), and the benchmark model
# crate's deterministic invariants hold. This proves the constitution's
# fixtures run reproducibly through the EP-032 tooling (WM-FEAT-0131).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

# The tool builds from a clean target dir and runs the fixtures.
out=$(mktemp /tmp/ep032_integration_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" run --quiet --release \
  --manifest-path tools/perf-capture/Cargo.toml -- \
  --suite ep032 --out tools/perf-capture/artifacts >"$out" 2>&1 || {
  cat "$out" >&2
  fail "perf-capture integration run failed"
}
grep -q "perf-capture: ok" "$out" || fail "perf-capture sentinel missing"

# Every owned fixture line must be present in the run output.
for queue in renderer-emits voice-jobs import-plan replay-batch \
             bug-automation soundscape-transitions; do
  grep -q "perf-capture $queue:" "$out" || fail "fixture $queue missing from run"
done

# The artifact records hardware + workload + distributions + thresholds.
artifact=tools/perf-capture/artifacts/ep032-perf-raw.json
[ -f "$artifact" ] || fail "missing raw artifact"
python3 - "$artifact" <<'PY' || fail "artifact integration check failed"
import json, sys
a = json.load(open(sys.argv[1]))
assert a["raw_evidence"] is True
assert a["hardware"]["arch"] and a["hardware"]["os"]
assert len(a["runs"]) >= 6
for r in a["runs"]:
    assert r["budget_met"] is True
    assert r["p95_us"] <= r["budget_us"]
assert len(a["regression_thresholds"]) >= 6
print("integration artifact ok")
PY

echo "integration EP-032 perf-capture-driver: ok"

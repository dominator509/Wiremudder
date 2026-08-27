#!/usr/bin/env sh
# EP-013 M4 performance test: routing latency on a 10,000-room graph.
# Runs the real wire-world-graph release binary, records hardware +
# distributions as raw evidence, and asserts the p95 budget (10 ms).
set -eu
cd "$(dirname "$0")/../../../.."

EVIDENCE=.agent/state/evidence/EP-013/M4/performance-001.json
mkdir -p .agent/state/evidence/EP-013/M4

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --release --quiet \
  --manifest-path wirecore/crates/wire-world-graph/Cargo.toml \
  --example route_bench > /tmp/wm-ep013-m4-perf.json 2>/dev/null \
  || fail "route bench"

python3 - "$EVIDENCE" <<'PY' || fail "performance evidence"
import json, os, platform, sys, time
raw = json.load(open('/tmp/wm-ep013-m4-perf.json'))
ev = {
    "node": "EP-013", "milestone": "M4", "fixture": "mapper-route-bench",
    "hardware": {"uname": platform.uname()._asdict(), "cpu_count": os.cpu_count()},
    "workload": {"rooms": raw["rooms"], "routes": raw["routes"]},
    "distributions_ms": raw["distributions_ms"],
    "budget_ms": raw["budget_ms"],
    "ok": raw["ok"],
    "observed_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
}
json.dump(ev, open(sys.argv[1], "w"), indent=2)
assert raw["ok"], f"p95 exceeded budget: {raw['distributions_ms']['p95']}ms"
print(f"performance mapper-route-bench: ok p95={raw['distributions_ms']['p95']:.3f}ms budget={raw['budget_ms']}ms")
PY

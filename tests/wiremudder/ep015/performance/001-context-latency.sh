#!/usr/bin/env sh
# EP-015 M4 performance test: distillation throughput + capsule size.
# Records raw evidence and asserts budgets (distill < 0.1 ms/line).
set -eu
cd "$(dirname "$0")/../../../.."

EVIDENCE=.agent/state/evidence/EP-015/M4/performance-001.json
mkdir -p .agent/state/evidence/EP-015/M4

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --release --quiet \
  --manifest-path wirecore/crates/wire-context/Cargo.toml \
  --example distill_bench > /tmp/wm-ep015-m4-perf.json 2>/dev/null \
  || fail "distill bench"

python3 - "$EVIDENCE" <<'PY' || fail "performance evidence"
import json, os, platform, sys, time
raw = json.load(open('/tmp/wm-ep015-m4-perf.json'))
ev = {
    "node": "EP-015", "milestone": "M4", "fixture": "context-distill-budget",
    "hardware": {"uname": platform.uname()._asdict(), "cpu_count": os.cpu_count()},
    "workload": {"lines": raw["lines"], "events": raw["events"]},
    "per_line_ms": raw["per_line_ms"],
    "total_ms": raw["total_ms"],
    "capsule_bytes": raw["capsule_bytes"],
    "budgets_ms": {"per_line": 0.1},
    "ok": raw["ok"],
    "observed_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
}
json.dump(ev, open(sys.argv[1], "w"), indent=2)
assert raw["ok"], f"budget exceeded: per_line={raw['per_line_ms']:.4f}ms"
print(f"performance context-distill-budget: ok per_line={raw['per_line_ms']:.4f}ms events={raw['events']} capsule={raw['capsule_bytes']}B")
PY

#!/usr/bin/env sh
# EP-014 M4 performance test: append throughput + FTS query latency.
# Records hardware + distributions as raw evidence, asserts budgets
# (append < 0.1 ms/line, search < 10 ms/query).
set -eu
cd "$(dirname "$0")/../../../.."

EVIDENCE=.agent/state/evidence/EP-014/M4/performance-001.json
mkdir -p .agent/state/evidence/EP-014/M4

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --release --quiet \
  --manifest-path wirecore/crates/wire-storage/Cargo.toml \
  --example storage_bench > /tmp/wm-ep014-m4-perf.json 2>/dev/null \
  || fail "storage bench"

python3 - "$EVIDENCE" <<'PY' || fail "performance evidence"
import json, os, platform, sys, time
raw = json.load(open('/tmp/wm-ep014-m4-perf.json'))
ev = {
    "node": "EP-014", "milestone": "M4", "fixture": "storage-append-search",
    "hardware": {"uname": platform.uname()._asdict(), "cpu_count": os.cpu_count()},
    "workload": {"lines": raw["lines"], "queries": raw["queries"]},
    "append_per_line_ms": raw["append_per_line_ms"],
    "search_per_query_ms": raw["search_per_query_ms"],
    "budgets_ms": {"append_per_line": 0.1, "search_per_query": 10.0},
    "ok": raw["ok"],
    "observed_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
}
json.dump(ev, open(sys.argv[1], "w"), indent=2)
assert raw["ok"], f"budget exceeded: append={raw['append_per_line_ms']:.4f}ms search={raw['search_per_query_ms']:.3f}ms"
print(f"performance storage-append-search: ok append={raw['append_per_line_ms']:.4f}ms/line search={raw['search_per_query_ms']:.3f}ms/query")
PY

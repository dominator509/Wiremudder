#!/usr/bin/env sh
# EP-006 M4 performance test: redaction throughput.
# Runs the real redaction engine against a ~1 MiB workload, records
# hardware + distributions as raw evidence, and asserts the
# linear-time budget (SPEC-004-R11/R12).
set -eu

cd "$(dirname "$0")/../../../.."
EVIDENCE=.agent/state/evidence/EP-006/M4/performance-001.json
mkdir -p .agent/state/evidence/EP-006/M4

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --release --quiet \
  --manifest-path wirecore/crates/wire-privacy/Cargo.toml \
  --example redact_bench > /tmp/wm-ep006-m4-perf.json 2>/dev/null \
  || { echo "FAIL: redaction bench" >&2; exit 1; }

python3 - "$EVIDENCE" <<'PY' || { echo "FAIL: performance evidence" >&2; exit 1; }
import json, platform, os, sys, time
raw = json.load(open('/tmp/wm-ep006-m4-perf.json'))
ev = {
    "node": "EP-006", "milestone": "M4", "fixture": "redaction-throughput",
    "hardware": {"uname": platform.uname()._asdict(), "cpu_count": os.cpu_count()},
    "workload": {"bytes": raw["bytes"], "patterns": 3, "iterations": 5},
    "distributions_ms": {"p50": raw["p50_ms"], "p95": raw["p95_ms"]},
    "throughput_mib_per_s": raw["throughput_mib_per_s"],
    "thresholds": {"min_throughput_mib_per_s": 5.0},
    "observed_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
}
json.dump(ev, open(sys.argv[1], "w"), indent=2)
assert raw["throughput_mib_per_s"] > 5.0, f"throughput too low: {raw['throughput_mib_per_s']}"
print(f"performance redaction-throughput: ok {raw['throughput_mib_per_s']:.1f} MiB/s p95={raw['p95_ms']:.3f}ms")
PY

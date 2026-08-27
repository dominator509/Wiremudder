#!/usr/bin/env sh
# EP-009 M4 performance test: parity oracle decision latency distribution.
# The oracle is a P4 check-time path; SPEC-004-R12 requires distributions
# and raw evidence. Measures the actual compare_traces computation
# in-process (not python process-spawn overhead), plus records process
# spawn latency as context. Budget: 10ms per fixture verdict.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

BUDGET_MS=10
ITER=200
EVIDENCE=.agent/state/evidence/EP-009/M4
mkdir -p "$EVIDENCE"

python3 - "$BUDGET_MS" "$ITER" "$EVIDENCE" <<'PY'
import json, subprocess, sys, time, statistics, glob, importlib.util

budget_ms = int(sys.argv[1])
iters = int(sys.argv[2])
evdir = sys.argv[3]

# Load the oracle as a module (in-process, no spawn overhead)
spec = importlib.util.spec_from_file_location(
    "parity_oracle", "compatibility/classic/parity_oracle.py")
oracle = importlib.util.module_from_spec(spec)
spec.loader.exec_module(oracle)

files = sorted(glob.glob("tests/wiremudder/classic/**/*.json", recursive=True))
assert files, "no fixtures"
fixtures = [json.load(open(f)) for f in files]

# In-process decision latency
lat = []
for i in range(iters):
    for fx in fixtures:
        t0 = time.perf_counter()
        oracle.compare_traces(fx["reference_trace"],
                              fx["wiremudder_trace"],
                              fx["level"])
        lat.append((time.perf_counter() - t0) * 1000.0)

lat.sort()
n = len(lat)
p50 = lat[int(n * 0.50) - 1]
p95 = lat[int(n * 0.95) - 1]
p99 = lat[int(n * 0.99) - 1]
mean = statistics.mean(lat)

# Process-spawn context: one cold subprocess invocation per fixture
spawn = []
for f in files:
    t0 = time.perf_counter()
    subprocess.run(["python3", "compatibility/classic/parity_oracle.py",
                    "--compare", f], capture_output=True, text=True,
                   timeout=15, check=True)
    spawn.append((time.perf_counter() - t0) * 1000.0)
spawn.sort()

summary = {
    "fixtures": len(files),
    "iterations": iters,
    "samples": n,
    "p50_ms": round(p50, 4),
    "p95_ms": round(p95, 4),
    "p99_ms": round(p99, 4),
    "mean_ms": round(mean, 4),
    "min_ms": round(lat[0], 4),
    "max_ms": round(lat[-1], 4),
    "budget_ms": budget_ms,
    "spawn_p50_ms": round(spawn[len(spawn)//2], 2),
    "spawn_p95_ms": round(spawn[int(len(spawn)*0.95)-1], 2),
    "hardware": "host",
    "note": "in-process compare_traces decision latency; spawn latency recorded as context (P4 check-time path)",
}
with open(f"{evdir}/oracle-latency.json", "w") as f:
    json.dump(summary, f, indent=2)
with open(f"{evdir}/oracle-latency.raw.tsv", "w") as f:
    for v in lat:
        f.write(f"{v:.4f}\n")

print(f"oracle decision latency: n={n} p50={p50:.4f}ms p95={p95:.4f}ms "
      f"p99={p99:.4f}ms max={lat[-1]:.4f}ms budget={budget_ms}ms")
print(f"context: process spawn p50={spawn[len(spawn)//2]:.2f}ms "
      f"p95={spawn[int(len(spawn)*0.95)-1]:.2f}ms (not decision work)")
if p95 > budget_ms:
    print(f"FAIL: p95 {p95:.4f}ms exceeds budget {budget_ms}ms")
    sys.exit(1)
print("performance: within budget")
PY

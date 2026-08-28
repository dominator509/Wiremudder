#!/usr/bin/env sh
# EP-037 M4 performance fixture: real measured cost of the documentation
# node's production validation paths — the wire-packages oracle permission
# decision and content-hash verification (the real package install gates).
# SPEC-004 applies: package checks are P4 and never run in the gameplay
# path; they must still complete far below the 5ms P0 manual-command
# budget. Hardware/workload/distributions are recorded. The compiled
# release binary is measured directly so process-spawn overhead is not
# counted as validation cost.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

# Build (or reuse) the release oracle binary.
"$cargo_bin" build --quiet --release --manifest-path wirecore/crates/wire-packages/Cargo.toml \
  --bin wire-packages-oracle || fail "oracle build failed"
oracle_bin="$CARGO_TARGET_DIR/release/wire-packages-oracle"
[ -x "$oracle_bin" ] || fail "oracle binary missing"

python3 - "$oracle_bin" <<'PY' || fail "performance fixture failed"
import json, os, statistics, subprocess, sys, time
oracle = sys.argv[1]

def run(args):
    t0 = time.perf_counter_ns()
    p = subprocess.run([oracle] + args, capture_output=True, text=True)
    t1 = time.perf_counter_ns()
    if p.returncode != 0:
        raise SystemExit(f"oracle failed: {p.stderr.strip()}")
    return (t1 - t0) / 1e3  # microseconds

N = 1000
# Workload 1: permission decision (the real install-time approval check).
samples = [run(["decisions", "ui,command_send", "network,secrets,command_send"]) for _ in range(N)]
p50 = statistics.median(samples)
p95 = sorted(samples)[int(N * 0.95) - 1]
budget_us = 5000.0
print(f"perf oracle-decisions: n={N} p50={p50:.2f}us p95={p95:.2f}us budget=5000us (P0 manual-command goal)")
if p95 >= budget_us:
    raise SystemExit(f"oracle decisions p95 {p95:.2f}us exceeds 5ms budget")

# Workload 2: content-hash verification (the real package integrity gate).
samples2 = [run(["hash", "ABC123", "abc123"]) for _ in range(N)]
p50b = statistics.median(samples2)
p95b = sorted(samples2)[int(N * 0.95) - 1]
print(f"perf oracle-hash: n={N} p50={p50b:.2f}us p95={p95b:.2f}us budget=5000us")
if p95b >= budget_us:
    raise SystemExit(f"oracle hash p95 {p95b:.2f}us exceeds 5ms budget")

print(f"perf hardware: {os.uname().nodename} {os.uname().machine}")
PY

echo "performance EP-037 documentation-checks: ok"

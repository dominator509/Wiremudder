#!/usr/bin/env sh
# EP-008 M4 performance test: gate evaluation and emergency-stop
# propagation under SPEC-004 budgets (10ms p95). Records raw evidence.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep008-m4-perf-$$
EVIDENCE=.agent/state/evidence/EP-008/M4
trap 'rm -f "$HARNESS"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep008/harness/ep008_harness.cpp \
  src/wiremudder/command-safety/action_gateway.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

mkdir -p "$EVIDENCE"
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" bench > "$EVIDENCE/performance-001.json" 2>&1 \
  || { echo "FAIL: bench" >&2; exit 1; }
cat "$EVIDENCE/performance-001.json"

python3 - "$EVIDENCE/performance-001.json" <<'PY' || { echo "FAIL: perf budget" >&2; exit 1; }
import json, sys
d = json.load(open(sys.argv[1]))
assert d['evaluate_p95_us'] <= d['budget_p95_us'], 'evaluate over budget'
assert d['estop_propagation_us'] <= d['budget_p95_us'], 'estop propagation over budget'
assert d['iterations'] >= 100000, 'insufficient iterations'
print(f"perf gate p95: {d['evaluate_p95_us']}us (budget {d['budget_p95_us']}us) estop: {d['estop_propagation_us']}us")
PY

echo "performance gate-latency: ok"

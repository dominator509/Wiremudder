#!/usr/bin/env sh
# EP-007 M4 performance test: routing decision and profile-store latency
# under SPEC-004 budgets (input budget 10ms p95). Records raw evidence.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep007-m4-perf-$$
EVIDENCE=.agent/state/evidence/EP-007/M4
trap 'rm -f "$HARNESS"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep007/harness/ep007_harness.cpp \
  src/wiremudder/profiles/character_profile_store.cpp \
  src/wiremudder/routing/route_profile_store.cpp \
  src/wiremudder/routing/router.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

mkdir -p "$EVIDENCE"
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" bench > "$EVIDENCE/performance-001.json" 2>&1 \
  || { echo "FAIL: bench" >&2; exit 1; }
cat "$EVIDENCE/performance-001.json"

python3 - "$EVIDENCE/performance-001.json" <<'PY' || { echo "FAIL: perf budget" >&2; exit 1; }
import json, sys
d = json.load(open(sys.argv[1]))
assert d['decision_p95_us'] <= d['budget_p95_us'], \
    f"decision p95 {d['decision_p95_us']}us exceeds budget {d['budget_p95_us']}us"
assert d['iterations'] >= 100000, 'insufficient iterations'
print(f"perf decision p95: {d['decision_p95_us']}us (budget {d['budget_p95_us']}us) upsert avg: {d['upsert_avg_us']}us")
PY

echo "performance decision-latency: ok"

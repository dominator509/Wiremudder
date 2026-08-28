#!/usr/bin/env sh
# EP-019 M3 E2E test: full guarded-autopilot user-visible flow.
# 1. Rust autopilot flow (propose visible, confirm, cancel, stale pause,
#    emergency stop, complete audit).
# 2. Real compiled C++ Qt autopilot pane harness.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

# 1. Rust flow.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-autopilot/Cargo.toml \
  --example e2e_autopilot_flow 2>&1 | tee /tmp/e2e_autopilot_flow.log
grep -q "E2E autopilot: ok" /tmp/e2e_autopilot_flow.log || fail "rust autopilot e2e"

# 2. C++ Qt pane harness (compiled against the real header, real Qt6).
QT=/opt/qt/6.8.2/gcc_64
OUT=/tmp/autopilot_pane_harness
c++ -std=c++20 -fPIC -I/root/wiremudder-repo \
  -I"$QT/include" -I"$QT/include/QtCore" \
  tests/wiremudder/ep019/e2e/autopilot_pane_harness.cpp \
  src/wiremudder/ui/autopilot/autopilot_boundary.cpp \
  -L"$QT/lib" -lQt6Core \
  -Wl,-rpath,"$QT/lib" -o "$OUT" 2>&1 | head -20
[ -x "$OUT" ] || fail "pane harness compile"
LD_LIBRARY_PATH="$QT/lib" "$OUT" | tee /tmp/e2e_autopilot_pane.log
grep -q "E2E autopilot pane: ok" /tmp/e2e_autopilot_pane.log || fail "pane harness run"

echo "e2e EP-019 M3 autopilot: ok"

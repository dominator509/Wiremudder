#!/usr/bin/env sh
# EP-017 M3 E2E test: full user-visible copilot flow.
# 1. Rust engine flow (distill -> route -> copilot -> degraded path).
# 2. Real compiled C++ Qt pane harness (state machine, cancellation,
#    bounded history, passive observer).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

# 1. Rust engine E2E (real capsule, real router, real engine).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-copilot/Cargo.toml \
  --example e2e_copilot_flow 2>&1 | tee /tmp/e2e_copilot_rust.log
grep -q "E2E copilot flow: ok" /tmp/e2e_copilot_rust.log \
  || fail "rust engine e2e"

# 2. C++ Qt pane harness (compiled against the real header, real Qt6).
QT=/opt/qt/6.8.2/gcc_64
OUT=/tmp/copilot_pane_harness
c++ -std=c++20 -fPIC -I/root/wiremudder-repo \
  -I"$QT/include" -I"$QT/include/QtCore" \
  tests/wiremudder/ep017/e2e/copilot_pane_harness.cpp \
  src/wiremudder/ui/copilot/copilot_boundary.cpp \
  -L"$QT/lib" -lQt6Core \
  -Wl,-rpath,"$QT/lib" -o "$OUT" 2>&1 | head -20
[ -x "$OUT" ] || fail "pane harness compile"
LD_LIBRARY_PATH="$QT/lib" "$OUT" | tee /tmp/e2e_copilot_pane.log
grep -q "E2E copilot pane: ok" /tmp/e2e_copilot_pane.log \
  || fail "pane harness run"

echo "e2e EP-017 M3 copilot-flow: ok"

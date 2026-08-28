#!/usr/bin/env sh
# EP-018 M3 E2E test: full soul/agents user-visible flow.
# 1. Rust soul/agents flow (validate, permissions, skill tree, council).
# 2. Real compiled C++ Qt soul pane harness.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

# 1. Rust flow.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-agents/Cargo.toml \
  --example e2e_soul_agents 2>&1 | tee /tmp/e2e_soul_agents.log
grep -q "E2E soul-agents: ok" /tmp/e2e_soul_agents.log || fail "rust soul-agents e2e"

# 2. C++ Qt pane harness (compiled against the real header, real Qt6).
QT=/opt/qt/6.8.2/gcc_64
OUT=/tmp/soul_pane_harness
c++ -std=c++20 -fPIC -I/root/wiremudder-repo \
  -I"$QT/include" -I"$QT/include/QtCore" \
  tests/wiremudder/ep018/e2e/soul_pane_harness.cpp \
  src/wiremudder/ui/soul/soul_boundary.cpp \
  -L"$QT/lib" -lQt6Core \
  -Wl,-rpath,"$QT/lib" -o "$OUT" 2>&1 | head -20
[ -x "$OUT" ] || fail "pane harness compile"
LD_LIBRARY_PATH="$QT/lib" "$OUT" | tee /tmp/e2e_soul_pane.log
grep -q "E2E soul pane: ok" /tmp/e2e_soul_pane.log || fail "pane harness run"

echo "e2e EP-018 M3 soul-agents: ok"

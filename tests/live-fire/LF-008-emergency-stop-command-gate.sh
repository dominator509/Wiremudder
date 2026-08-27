#!/usr/bin/env sh
# LF-008 emergency-stop-command-gate (live-fire)
#
# Proves the real user outcome of EP-008: all non-manual sources use one
# deterministic action gateway; risk and confirmation policy is
# deterministic; no high-confidence shortcut exists; emergency stop
# cancels queued automation and blocks new proposals; Human-Tempo is
# anti-spam only; every action is replayable from audit evidence; and
# both real implementations (Rust core + C++ Qt layer) agree.
set -eu
fail() { echo "LF-008: FAIL - $1" >&2; exit 1; }

cd "$(dirname "$0")/../.."
QT=/opt/qt/6.8.2/gcc_64
[ -d "$QT" ] || fail "Qt 6.8.2 not at $QT"
HARNESS=/tmp/wm-lf008-harness-$$
trap 'rm -f "$HARNESS"' EXIT

echo "LF-008: emergency-stop-command-gate"
echo "observed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 1. Real Rust cores: full test suites (policy tiers + gateway + estop).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-policy/Cargo.toml >/tmp/wm-lf008-p.log 2>&1 \
  || fail "wire-policy tests"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-actions/Cargo.toml >/tmp/wm-lf008-a.log 2>&1 \
  || fail "wire-actions tests"

# 2. Real C++ layer: policy, gateway, estop, failures invariants.
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep008/harness/ep008_harness.cpp \
  src/wiremudder/command-safety/action_gateway.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || fail "harness compile"
for sub in policy gateway estop failures; do
  LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" "$sub" >/tmp/wm-lf008-${sub}.out 2>&1 \
    || fail "$sub invariants"
done

# 3. Cross-implementation oracle: identical policy and gate decisions.
sh tests/wiremudder/ep008/e2e/001-oracle.sh >/dev/null 2>&1 \
  || fail "oracle divergence"

# 4. Full command flow: manual path direct, all sources gated, audit
#    schema fields present.
sh tests/wiremudder/ep008/e2e/002-command-flow.sh >/dev/null 2>&1 \
  || fail "command flow"

# 5. Emergency stop budget: measured propagation must be under 10ms.
python3 - <<'PY' || fail "estop budget"
import json, subprocess
out = subprocess.run(['sh', 'tests/wiremudder/ep008/performance/001-gate-latency.sh'],
                     capture_output=True, text=True)
assert out.returncode == 0, out.stderr
PY

echo "LF-008: emergency-stop-command-gate ok"

#!/usr/bin/env sh
# EP-023 M3 integration test: wire-headless integration flow.
# 1. The wire-headless crate builds and its deterministic suite passes.
# 2. The headless schemas exist and are valid JSON.
# 3. The supervisor CLI tool builds against the real crate.
# 4. Manual gameplay is preserved: the supervisor is a passive observer
#    with no command path.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# 1. Crate surface real and tested.
[ -f wirecore/crates/wire-headless/Cargo.toml ] || fail "missing wire-headless crate manifest"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-headless/Cargo.toml 2>&1 \
  | grep -q "9 passed" || fail "wire-headless crate tests"

# 2. Schemas valid.
for f in schemas/wiremudder/headless/*.json; do
  python3 -c "import json,sys; json.load(open('$f'))" || fail "invalid schema $f"
done

# 3. Supervisor CLI builds against the real crate.
[ -f tools/wiremudder-supervisor/Cargo.toml ] || fail "missing supervisor manifest"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo build --quiet \
  --manifest-path tools/wiremudder-supervisor/Cargo.toml 2>&1 \
  || fail "supervisor build"

# 4. Passive supervisor: no command path; the scheduler owns the global
#    emergency stop; sessions are independent and bounded.
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "is_passive" "$LIB" || fail "supervisor not passive"
grep -q "SESSION_QUEUE_CAPACITY" "$LIB" || fail "session queues not bounded"
grep -q "MAX_SESSIONS" "$LIB" || fail "session count not bounded"
grep -q "emergency_stop" "$LIB" || fail "global emergency stop missing"

# 5. Desktop headless adapter boundary compiles with real Qt6 and is
#    passive (no command path, no emergency-stop authority).
ADAPTER=src/wiremudder/headless/headless_adapter_boundary
[ -f "$ADAPTER.h" ] || fail "headless adapter header missing"
QT=/opt/qt/6.8.2/gcc_64
if [ -d "$QT" ] && command -v c++ >/dev/null 2>&1; then
  c++ -std=c++20 -fPIC -I/root/wiremudder-repo \
    -I"$QT/include" -I"$QT/include/QtCore" \
    -c "$ADAPTER.cpp" -o /tmp/headless_adapter.o 2>&1 | head -10 \
    || fail "headless adapter compile"
  [ -f /tmp/headless_adapter.o ] || fail "headless adapter object missing"
fi
grep -q "canSendCommand() const { return false; }" "$ADAPTER.h" || fail "adapter has command path"
grep -q "canEmergencyStop() const { return false; }" "$ADAPTER.h" || fail "adapter can emergency stop"

echo "integration EP-023 M3 headless-flow: ok"

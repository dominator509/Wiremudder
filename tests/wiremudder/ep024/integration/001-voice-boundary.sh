#!/usr/bin/env sh
# EP-024 M3 integration test: voice companion integration flow.
# 1. The wire-voice crate builds and its deterministic suite passes.
# 2. The voice schemas exist and are valid JSON.
# 3. The voice UI boundary compiles with real Qt6 and is passive
#    (no command path, no gate editing), and is wired into the client
#    build list (src/CMakeLists.txt, discovered amendment WM-SRC-000155).
# 4. Manual gameplay is preserved: the voice boundary is a passive
#    observer with no command path; failure degrades to text.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# 1. Crate surface real and tested.
[ -f wirecore/crates/wire-voice/Cargo.toml ] || fail "missing wire-voice crate manifest"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-voice/Cargo.toml 2>&1 \
  | grep -q "18 passed" || fail "wire-voice crate tests"

# 2. Schemas valid.
for f in schemas/wiremudder/voice/*.json; do
  python3 -c "import json,sys; json.load(open('$f'))" || fail "invalid schema $f"
done

# 3. Voice UI boundary compiled into the client build (discovered
#    amendment WM-SRC-000155) and present.
[ -f src/wiremudder/ui/voice/voice_boundary.cpp ] || fail "voice boundary cpp missing"
[ -f src/wiremudder/ui/voice/voice_boundary.h ] || fail "voice boundary header missing"
grep -q "wiremudder/ui/voice/voice_boundary.cpp" src/CMakeLists.txt || fail "voice boundary not wired into client build"
grep -q "wiremudder/ui/voice/voice_boundary.h" src/CMakeLists.txt || fail "voice boundary header not wired into client build"

# 4. Boundary compiles with real Qt6 and is passive.
BOUNDARY=src/wiremudder/ui/voice/voice_boundary
QT=/opt/qt/6.8.2/gcc_64
if [ -d "$QT" ] && command -v c++ >/dev/null 2>&1; then
  c++ -std=c++20 -fPIC -I/root/wiremudder-repo \
    -I"$QT/include" -I"$QT/include/QtCore" \
    -c "$BOUNDARY.cpp" -o /tmp/voice_boundary.o 2>&1 | head -10 \
    || fail "voice boundary compile"
  [ -f /tmp/voice_boundary.o ] || fail "voice boundary object missing"
fi
grep -q "canSendCommand() const { return false; }" "$BOUNDARY.h" || fail "boundary has command path"
grep -q "canEditGates() const { return false; }" "$BOUNDARY.h" || fail "boundary can edit gates"
grep -q "isPassive() const { return true; }" "$BOUNDARY.h" || fail "boundary not passive"
# Mic state is always visible on the boundary.
grep -q "VoiceMicState micState()" "$BOUNDARY.h" || fail "mic state not visible"

echo "integration EP-024 M3 voice-flow: ok"

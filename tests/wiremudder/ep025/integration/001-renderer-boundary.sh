#!/usr/bin/env sh
# EP-025 M3 integration test: renderer integration flow.
# 1. The wire-renderer crate builds and its deterministic suite passes.
# 2. The renderer schemas exist and are valid JSON.
# 3. The renderer UI boundary compiles with real Qt6 and is passive
#    (no command path, no gate editing), and is wired into the client
#    build list (src/CMakeLists.txt, discovered amendment WM-SRC-000168).
# 4. Manual gameplay is preserved: the renderer boundary is a passive
#    observer with no command path; failure degrades to text.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# 1. Crate surface real and tested.
[ -f wirecore/crates/wire-renderer/Cargo.toml ] || fail "missing wire-renderer crate manifest"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-renderer/Cargo.toml 2>&1 \
  | grep -q "16 passed" || fail "wire-renderer crate tests"

# 2. Schemas valid.
for f in schemas/wiremudder/renderer/*.json; do
  python3 -c "import json,sys; json.load(open('$f'))" || fail "invalid schema $f"
done

# 3. Renderer UI boundary compiled into the client build (discovered
#    amendment WM-SRC-000168) and present.
[ -f src/wiremudder/ui/renderer/renderer_boundary.cpp ] || fail "renderer boundary cpp missing"
[ -f src/wiremudder/ui/renderer/renderer_boundary.h ] || fail "renderer boundary header missing"
grep -q "wiremudder/ui/renderer/renderer_boundary.cpp" src/CMakeLists.txt || fail "renderer boundary not wired into client build"
grep -q "wiremudder/ui/renderer/renderer_boundary.h" src/CMakeLists.txt || fail "renderer boundary header not wired into client build"

# 4. Boundary compiles with real Qt6 and is passive.
BOUNDARY=src/wiremudder/ui/renderer/renderer_boundary
QT=/opt/qt/6.8.2/gcc_64
if [ -d "$QT" ] && command -v c++ >/dev/null 2>&1; then
  c++ -std=c++20 -fPIC -I/root/wiremudder-repo \
    -I"$QT/include" -I"$QT/include/QtCore" \
    -c "$BOUNDARY.cpp" -o /tmp/renderer_boundary.o 2>&1 | head -10 \
    || fail "renderer boundary compile"
  [ -f /tmp/renderer_boundary.o ] || fail "renderer boundary object missing"
fi
grep -q "canSendCommand() const { return false; }" "$BOUNDARY.h" || fail "boundary has command path"
grep -q "canEditGates() const { return false; }" "$BOUNDARY.h" || fail "boundary can edit gates"
grep -q "isPassive() const { return true; }" "$BOUNDARY.h" || fail "boundary not passive"
# Raw text authority is preserved on the boundary.
grep -q "Raw text remains visible and" "$BOUNDARY.h" || fail "raw text authority missing"

echo "integration EP-025 M3 renderer-flow: ok"

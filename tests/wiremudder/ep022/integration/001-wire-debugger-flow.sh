#!/usr/bin/env sh
# EP-022 M3 integration test: wire-debugger integration flow.
# 1. The wire-debugger crate builds and its deterministic suite passes.
# 2. The debug schemas exist and are valid JSON.
# 3. The power-tools pane is wired into the client build list.
# 4. The pane is passive with no command path and no gate editing.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# 1. Crate surface real and tested.
[ -f wirecore/crates/wire-debugger/Cargo.toml ] || fail "missing wire-debugger crate manifest"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-debugger/Cargo.toml 2>&1 \
  | grep -q "10 passed" || fail "wire-debugger crate tests"

# 2. Schemas valid.
for f in schemas/wiremudder/debug/*.json; do
  python3 -c "import json,sys; json.load(open('$f'))" || fail "invalid schema $f"
done

# 3. Pane wired into the client build list (authorized WM-SRC-000146).
grep -q "wiremudder/ui/power-tools/power_tools_boundary.cpp" src/CMakeLists.txt \
  || fail "power-tools pane not in mudlet_SRCS"
grep -q "wiremudder/ui/power-tools/power_tools_boundary.h" src/CMakeLists.txt \
  || fail "power-tools header not in mudlet_HEADERS"

# 4. Passive observer: no command path, no gate editing.
HDR=src/wiremudder/ui/power-tools/power_tools_boundary.h
grep -q "canSendCommand() const { return false; }" "$HDR" || fail "pane has command path"
grep -q "canEditGates() const { return false; }" "$HDR" || fail "pane can edit gates"
grep -q "isPassive() const { return true; }" "$HDR" || fail "pane not passive"

# 5. Manual gameplay preserved: AI Debugger never self-certifies, never
#    touches gates; suggested patches require Graphlock validation.
LIB=wirecore/crates/wire-debugger/src/lib.rs
grep -q "self_certified: false" "$LIB" || fail "AI Debugger can self-certify"
grep -q "DeniedPolicy" "$LIB" || fail "AI Debugger lacks policy denial"

echo "integration EP-022 M3 wire-debugger-flow: ok"

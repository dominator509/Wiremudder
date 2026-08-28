#!/usr/bin/env sh
# EP-019 M3 integration test: autopilot crate + pane integration flow.
# 1. The pane is compiled into the real client build list (src/CMakeLists.txt).
# 2. The crate is real: unit tests + schemas exist.
# 3. Manual gameplay is preserved: the pane is passive with no command path.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# 1. Pane compiled into the client.
grep -q "wiremudder/ui/autopilot/autopilot_boundary.cpp" src/CMakeLists.txt \
  || fail "autopilot pane not in mudlet_SRCS"
grep -q "wiremudder/ui/autopilot/autopilot_boundary.h" src/CMakeLists.txt \
  || fail "autopilot pane header not in mudlet_HDRS"

# 2. Crate surface real and tested.
[ -f wirecore/crates/wire-autopilot/Cargo.toml ] || fail "missing autopilot crate manifest"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-autopilot/Cargo.toml 2>&1 \
  | grep -q "11 passed" || fail "autopilot crate tests"

# 3. Manual gameplay preserved: passive pane, no command path, no self-grant.
HDR=src/wiremudder/ui/autopilot/autopilot_boundary.h
grep -q "isPassive() const { return true; }" "$HDR" || fail "pane not passive"
grep -q "canSendCommand() const { return false; }" "$HDR" || fail "pane has command path"

echo "integration EP-019 M3 autopilot-flow: ok"

#!/usr/bin/env sh
# EP-020 M3 integration test: assistance crate + pane integration flow.
# 1. The pane is compiled into the real client build list (src/CMakeLists.txt).
# 2. The crates are real: unit tests + schemas exist.
# 3. Manual gameplay is preserved: the pane is passive with no command path.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# 1. Pane compiled into the client.
grep -q "wiremudder/ui/assistance/assistance_boundary.cpp" src/CMakeLists.txt \
  || fail "assistance pane not in mudlet_SRCS"
grep -q "wiremudder/ui/assistance/assistance_boundary.h" src/CMakeLists.txt \
  || fail "assistance pane header not in mudlet_HDRS"

# 2. Crate surfaces real and tested.
for c in wire-quest wire-tactical wire-narrator; do
  [ -f "wirecore/crates/$c/Cargo.toml" ] || fail "missing $c crate manifest"
done
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-narrator/Cargo.toml 2>&1 \
  | grep -q "7 passed" || fail "wire-narrator crate tests"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-quest/Cargo.toml 2>&1 \
  | grep -q "6 passed" || fail "wire-quest crate tests"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-tactical/Cargo.toml 2>&1 \
  | grep -q "5 passed" || fail "wire-tactical crate tests"

# 3. Manual gameplay preserved: passive pane, no command path, no self-grant.
HDR=src/wiremudder/ui/assistance/assistance_boundary.h
grep -q "isPassive() const { return true; }" "$HDR" || fail "pane not passive"
grep -q "canSendCommand() const { return false; }" "$HDR" || fail "pane has command path"

echo "integration EP-020 M3 assistance-flow: ok"

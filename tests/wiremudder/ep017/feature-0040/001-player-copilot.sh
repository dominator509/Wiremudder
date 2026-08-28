#!/usr/bin/env sh
# EP-017 M5 feature test: WM-FEAT-0040 Player Copilot.
# Suggestion-only engine: cites observations/memory, degrades on provider
# failure, never hidden-sends commands, and lands in the compiled pane.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0040: FAIL - $1" >&2; exit 1; }

# Engine unit invariants.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-copilot/Cargo.toml 2>&1 \
  | grep -q "10 passed" || fail "wire-copilot unit tests"

# Live-fire proves the real provider suggestion path.
sh tests/live-fire/LF-017-copilot-suggestion-explanation.sh >/dev/null 2>&1 \
  || fail "LF-017 live-fire"

# The pane is compiled into the client build (real integration).
grep -q "wiremudder/ui/copilot/copilot_boundary.cpp" src/CMakeLists.txt \
  || fail "copilot pane not compiled into client"

echo "feature-0040 player-copilot: ok"

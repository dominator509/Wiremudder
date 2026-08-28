#!/usr/bin/env sh
# EP-026 M3 e2e test: the real user-visible soundscape flow must run
# through the production wire-soundscape crate and prove every
# acceptance obligation from the node contract.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

out=$(mktemp /tmp/ep026_e2e_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" run --quiet \
  --manifest-path wirecore/crates/wire-soundscape/Cargo.toml \
  --example e2e_soundscape >"$out" 2>&1 || {
  cat "$out" >&2
  fail "soundscape e2e did not run"
}

grep -q "All binding classes are represented: 9/9" "$out" || fail "obligation 1 (binding classes) not proven"
grep -q "Assets carry license and provenance" "$out" || fail "obligation 2 (asset provenance) not proven"
grep -q "Volume and disable controls are profile-scoped" "$out" || fail "obligation 3 (profile-scoped controls) not proven"
grep -q "Transitions are bounded and cancelable" "$out" || fail "obligation 4 (bounded transitions) not proven"
grep -q "Load shedding keeps current loop or silence" "$out" || fail "obligation 5 (load shedding) not proven"
grep -q "Audio failure preserves text gameplay" "$out" || fail "obligation 6 (text preservation) not proven"

echo "e2e EP-026 soundscape-flow: ok"

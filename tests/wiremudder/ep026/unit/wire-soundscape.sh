#!/usr/bin/env sh
# EP-026 M2 unit test: wire-soundscape crate must compile and all
# deterministic unit tests must pass.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

cd wirecore/crates/wire-soundscape

CARGO_TARGET_DIR="$OLDPWD/wirecore/target" "$cargo_bin" test --quiet 2>&1 | tee /tmp/ep026_unit_test.log
grep -q "test result: ok" /tmp/ep026_unit_test.log || fail "crate tests did not pass"
grep -q "21 passed" /tmp/ep026_unit_test.log || fail "expected 21 passing tests"

# Deterministic invariants must exist in the crate source.
grep -q "all_nine_binding_classes_represented" src/lib.rs || fail "missing nine-class invariant"
grep -q "protected_asset_rejected" src/lib.rs || fail "missing protected-asset test"
grep -q "unlicensed_asset_rejected" src/lib.rs || fail "missing unlicensed-asset test"
grep -q "profile_controls_clamped_and_scoped" src/lib.rs || fail "missing profile-scoped test"
grep -q "transition_bounded_and_cancelable" src/lib.rs || fail "missing transition test"
grep -q "audio_failure_preserves_text_gameplay" src/lib.rs || fail "missing text-preservation test"
grep -q "cannot_send_commands" src/lib.rs || fail "missing no-command test"

echo "unit EP-026 wire-soundscape: ok"

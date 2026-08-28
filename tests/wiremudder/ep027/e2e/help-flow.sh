#!/usr/bin/env sh
# EP-027 M3 e2e test: the real user-visible help/coach/source-index
# flow must run through the production wire-help crate and prove every
# acceptance obligation from the node contract.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

out=$(mktemp /tmp/ep027_e2e_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" run --quiet \
  --manifest-path wirecore/crates/wire-help/Cargo.toml \
  --example e2e_help >"$out" 2>&1 || {
  cat "$out" >&2
  fail "help e2e did not run"
}

grep -q "Help content is generated from accepted sources" "$out" || fail "obligation 1 (accepted sources) not proven"
grep -q "AI help receives only scoped sanitized context" "$out" || fail "obligation 2 (sanitized context) not proven"
grep -q "Coach cannot mutate protected settings or send commands" "$out" || fail "obligation 3 (no mutation) not proven"
grep -q "Source index is opt-in, local, idle, and removable" "$out" || fail "obligation 4 (source index) not proven"
grep -q "Capability detection is evidence-based" "$out" || fail "obligation 5 (capability detection) not proven"
grep -q "CLI/headless help parity passes" "$out" || fail "obligation 6 (CLI parity) not proven"

echo "e2e EP-027 help-flow: ok"

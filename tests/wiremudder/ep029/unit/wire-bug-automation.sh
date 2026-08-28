#!/usr/bin/env sh
# EP-029 M2 unit test: the wire-bug-automation crate builds and passes its
# deterministic unit suite (SPEC-019-R09 state machine, retry bounds,
# subsystem-scoped patches, independent review, redaction, priority ring).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

log=$(mktemp /tmp/ep029_bugauto_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" test \
  --manifest-path wirecore/crates/wire-bug-automation/Cargo.toml >"$log" 2>&1 || {
  cat "$log" >&2
  fail "wire-bug-automation tests failed"
}
grep -q "19 passed" "$log" || fail "expected 19 passing tests in wire-bug-automation"

echo "unit wire-bug-automation: ok"

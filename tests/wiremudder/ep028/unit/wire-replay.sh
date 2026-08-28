#!/usr/bin/env sh
# EP-028 M2 unit test: wire-replay — deterministic replay, bundle
# preview/export match, redaction, sanitized fixtures, dedup keys.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

log=$(mktemp /tmp/ep028_replay_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" test \
  --manifest-path wirecore/crates/wire-replay/Cargo.toml >"$log" 2>&1 || {
  cat "$log" >&2
  fail "wire-replay tests failed"
}
grep -q "8 passed" "$log" || fail "expected 8 passing tests in wire-replay"

echo "unit wire-replay: ok"

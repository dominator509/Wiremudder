#!/usr/bin/env sh
# Unit tests for wire-actions: one gateway for all non-manual sources,
# gate context verification, confirmation policy, emergency stop,
# bounded queue, complete audit, malformed input rejection.
set -eu

cd "$(dirname "$0")/../../../.."
CARGO_BIN=$(command -v cargo || echo /root/.cargo/bin/cargo)
cd wirecore/crates/wire-actions

out=$(mktemp)
if ! "$CARGO_BIN" test --offline >"$out" 2>&1; then
  cat "$out" >&2
  echo "unit wire-actions: FAIL" >&2
  exit 1
fi
cat "$out"
grep -q "test result: ok" "$out" || { echo "unit wire-actions: no passing result" >&2; exit 1; }
echo "unit wire-actions: ok"

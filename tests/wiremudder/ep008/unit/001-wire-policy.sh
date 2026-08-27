#!/usr/bin/env sh
# Unit tests for wire-policy: risk tiers, deny/allow rules, argument
# validation, unknown-command defaults, Human-Tempo pacing.
set -eu

cd "$(dirname "$0")/../../../.."
CARGO_BIN=$(command -v cargo || echo /root/.cargo/bin/cargo)
cd wirecore/crates/wire-policy

out=$(mktemp)
if ! "$CARGO_BIN" test --offline >"$out" 2>&1; then
  cat "$out" >&2
  echo "unit wire-policy: FAIL" >&2
  exit 1
fi
cat "$out"
grep -q "test result: ok" "$out" || { echo "unit wire-policy: no passing result" >&2; exit 1; }
echo "unit wire-policy: ok"

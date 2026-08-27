#!/usr/bin/env sh
# Unit tests for wire-profiles: schema version lock, ten default
# domains, sensitive-default actor rules, audit redaction, round-trip.
set -eu

cd "$(dirname "$0")/../../../.."
CARGO_BIN=$(command -v cargo || echo /root/.cargo/bin/cargo)
# Standalone crate (no workspace root manifest): run from the crate dir.
cd wirecore/crates/wire-profiles

out=$(mktemp)
if ! "$CARGO_BIN" test --offline >"$out" 2>&1; then
  cat "$out" >&2
  echo "unit wire-profiles: FAIL" >&2
  exit 1
fi
cat "$out"
grep -q "test result: ok" "$out" || { echo "unit wire-profiles: no passing result" >&2; exit 1; }
echo "unit wire-profiles: ok"

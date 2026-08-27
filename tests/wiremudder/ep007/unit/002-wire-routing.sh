#!/usr/bin/env sh
# Unit tests for wire-routing: route taxonomy, kind validation,
# no-silent-fallback, connect-time decision, egress verification,
# audit redaction.
set -eu

cd "$(dirname "$0")/../../../.."
CARGO_BIN=$(command -v cargo || echo /root/.cargo/bin/cargo)
# Standalone crate (no workspace root manifest): run from the crate dir.
cd wirecore/crates/wire-routing

out=$(mktemp)
if ! "$CARGO_BIN" test --offline >"$out" 2>&1; then
  cat "$out" >&2
  echo "unit wire-routing: FAIL" >&2
  exit 1
fi
cat "$out"
grep -q "test result: ok" "$out" || { echo "unit wire-routing: no passing result" >&2; exit 1; }
echo "unit wire-routing: ok"

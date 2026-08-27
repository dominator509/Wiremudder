#!/usr/bin/env sh
# EP-010 M2 unit test: wire-packages Rust core - permission firewall,
# quarantine, hash verification, manifest round trip.
set -eu
cd "$(dirname "$0")/../../../.."
CARGO=/root/.cargo/bin/cargo

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

[ -f wirecore/crates/wire-packages/Cargo.toml ] || fail "wire-packages manifest missing"

CARGO_TARGET_DIR="$PWD/wirecore/target" "$CARGO" test \
  --manifest-path wirecore/crates/wire-packages/Cargo.toml >/tmp/wm-ep010-unit.log 2>&1 \
  || { tail -20 /tmp/wm-ep010-unit.log; fail "wire-packages tests"; }

grep -q "test result: ok" /tmp/wm-ep010-unit.log || fail "no passing test result"

echo "unit EP-010 M2: ok"

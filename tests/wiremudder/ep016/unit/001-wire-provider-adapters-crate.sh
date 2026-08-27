#!/usr/bin/env sh
# EP-016 M2 unit test: wire-provider-adapters crate deterministic invariants.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-provider-adapters/Cargo.toml 2>&1 \
  | grep -q "19 passed" || fail "wire-provider-adapters unit tests"

echo "unit EP-016 M2 wire-provider-adapters: ok"

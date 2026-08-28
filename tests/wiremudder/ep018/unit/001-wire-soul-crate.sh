#!/usr/bin/env sh
# EP-018 M2 unit test: wire-soul crate deterministic invariants.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-soul/Cargo.toml 2>&1 \
  | grep -q "8 passed" || fail "wire-soul unit tests"

echo "unit EP-018 M2 wire-soul: ok"

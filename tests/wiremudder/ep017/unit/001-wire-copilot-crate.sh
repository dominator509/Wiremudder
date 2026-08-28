#!/usr/bin/env sh
# EP-017 M2 unit test: wire-copilot crate deterministic invariants.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-copilot/Cargo.toml 2>&1 \
  | grep -q "10 passed" || fail "wire-copilot unit tests"

echo "unit EP-017 M2 wire-copilot: ok"

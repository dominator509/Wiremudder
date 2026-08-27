#!/usr/bin/env sh
# EP-015 M2 unit test: wire-token-budget crate deterministic budgets.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-token-budget/Cargo.toml 2>&1 \
  | grep -q "10 passed" || fail "wire-token-budget unit tests"

echo "unit EP-015 M2 wire-token-budget: ok"

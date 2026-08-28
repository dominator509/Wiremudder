#!/usr/bin/env sh
# EP-018 M2 unit test: wire-agents crate deterministic invariants.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-agents/Cargo.toml 2>&1 \
  | grep -q "10 passed" || fail "wire-agents unit tests"

echo "unit EP-018 M2 wire-agents: ok"

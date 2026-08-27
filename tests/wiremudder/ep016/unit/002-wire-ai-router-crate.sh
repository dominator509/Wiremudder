#!/usr/bin/env sh
# EP-016 M2 unit test: wire-ai-router crate deterministic invariants.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml 2>&1 \
  | grep -q "21 passed" || fail "wire-ai-router unit tests"

echo "unit EP-016 M2 wire-ai-router: ok"

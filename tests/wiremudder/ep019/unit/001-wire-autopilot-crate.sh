#!/usr/bin/env sh
# EP-019 M2 unit test: wire-autopilot crate deterministic invariants.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-autopilot/Cargo.toml 2>&1 \
  | grep -q "11 passed" || fail "wire-autopilot unit tests"

echo "unit EP-019 M2 wire-autopilot: ok"

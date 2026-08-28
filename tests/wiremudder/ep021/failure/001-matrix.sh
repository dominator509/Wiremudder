#!/usr/bin/env sh
# EP-021 M4 failure test: world-memory failure matrix through the real crates.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-world-brain/Cargo.toml \
  --example failure_matrix 2>&1 | tee /tmp/ep021_failure.log
grep -q "failure matrix: ok" /tmp/ep021_failure.log || fail "failure matrix"

echo "failure EP-021 M4 matrix: ok"

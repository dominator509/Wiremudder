#!/usr/bin/env sh
# EP-023 M4 failure test: real forced failures through the real
# wire-headless crate.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-headless/Cargo.toml \
  --example failure_matrix 2>&1 | tee /tmp/ep023_failure_matrix.log
grep -q "failure matrix: 8 failures exercised, all closed" /tmp/ep023_failure_matrix.log \
  || fail "failure matrix did not complete"

echo "failure EP-023 M4 failure-matrix: ok"

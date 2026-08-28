#!/usr/bin/env sh
# EP-024 M4 failure test: real controlled failures through the
# production wire-voice crate. Fails unless every required failure
# proof is true (node contract: dependency/worker unavailable, timeout
# and cancellation, malformed or oversized input, duplicate request,
# denied policy/consent, queue budget exhaustion, partial effect and
# compensation, preserved manual gameplay and data integrity).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-voice/Cargo.toml \
  --example failure_matrix 2>&1 | tee /tmp/ep024_failure.log

grep -q "failure matrix EP-024: ok 8/8" /tmp/ep024_failure.log || fail "failure matrix not green"

for n in 1 2 3 4 5 6 7 8; do
  grep -q "failure-$n " /tmp/ep024_failure.log || fail "failure proof $n missing"
done

echo "failure EP-024 M4 matrix: ok"

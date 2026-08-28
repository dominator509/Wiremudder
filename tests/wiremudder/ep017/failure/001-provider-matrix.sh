#!/usr/bin/env sh
# EP-017 M4 failure test: provider failure matrix through the real engine.
# Each controlled failure must produce NoSuggestion{degraded:true} with a
# safe user message (SPEC-025-R09) and preserve gameplay (pane passive).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-copilot/Cargo.toml \
  --example failure_matrix 2>&1 | tee /tmp/ep017_failure.log
grep -q "failure matrix: ok" /tmp/ep017_failure.log || fail "failure matrix"

echo "failure EP-017 M4 provider-matrix: ok"

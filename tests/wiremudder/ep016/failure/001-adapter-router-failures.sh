#!/usr/bin/env sh
# EP-016 M4 failure: real controlled failures against adapter and router.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml \
  --example failure_matrix > /tmp/wm-ep016-failure.txt 2>&1 \
  || { cat /tmp/wm-ep016-failure.txt; fail "failure_matrix"; }

for step in unavailable timeout malformed protocol cancel cancel-mid-stream duplicate denied bounded; do
  grep -q "M4 $step: ok" /tmp/wm-ep016-failure.txt || fail "failure step $step not proven"
done
grep -q "FAILURE_MATRIX_DONE" /tmp/wm-ep016-failure.txt || fail "missing done sentinel"

echo "failure EP-016 M4 adapter-router-failures: ok"

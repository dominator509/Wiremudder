#!/usr/bin/env sh
# WM-SPEC-025-R07: cancellation is distinct from failure and propagates to
# provider tasks.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r07: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml \
  --example failure_matrix > /tmp/wm-r07.txt 2>&1 \
  || { cat /tmp/wm-r07.txt; fail "failure_matrix"; }

grep -q "M4 cancel: ok" /tmp/wm-r07.txt || fail "cancel distinct"
grep -q "M4 cancel-mid-stream: ok" /tmp/wm-r07.txt || fail "cancel propagation mid-stream"
grep -q "M4 timeout: ok" /tmp/wm-r07.txt || fail "timeout distinct from cancel"

echo "req WM-SPEC-025-R07: ok"

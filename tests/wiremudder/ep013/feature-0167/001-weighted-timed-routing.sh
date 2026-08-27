#!/usr/bin/env sh
# WM-FEAT-0167: weighted and timed routing.
# Proves weighted routing prefers cheaper paths and timed windows gate
# traversal, with the p95 latency budget recorded (SPEC-004).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0167: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-world-graph/Cargo.toml weighted \
  > /tmp/wm-feat-0167.log 2>&1 \
  || { tail -10 /tmp/wm-feat-0167.log >&2; fail "weighted unit test"; }
grep -q "test result: ok" /tmp/wm-feat-0167.log || fail "weighted test not ok"

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-world-graph/Cargo.toml timed_exit \
  > /tmp/wm-feat-0167t.log 2>&1 \
  || { tail -10 /tmp/wm-feat-0167t.log >&2; fail "timed unit test"; }
grep -q "test result: ok" /tmp/wm-feat-0167t.log || fail "timed test not ok"

echo "feature-0167 weighted-and-timed-routing: ok"

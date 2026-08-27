#!/usr/bin/env sh
# EP-013 M4 failure test: resource exhaustion and malformed input.
# The real wire-world-graph crate must fail typed and bounded:
# - room/exit limits are enforced
# - malformed snapshots are rejected
# - duplicate exits and unknown rooms are rejected
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

[ -x /root/.cargo/bin/cargo ] || fail "cargo missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-world-graph/Cargo.toml \
  --example failure_matrix > /tmp/wm-ep013-m4-failure.txt 2>/dev/null \
  || fail "failure matrix"

grep -q "room-limit:ok" /tmp/wm-ep013-m4-failure.txt || fail "room limit not enforced"
grep -q "exit-limit:ok" /tmp/wm-ep013-m4-failure.txt || fail "exit limit not enforced"
grep -q "duplicate-exit:ok" /tmp/wm-ep013-m4-failure.txt || fail "duplicate exit not rejected"
grep -q "unknown-room:ok" /tmp/wm-ep013-m4-failure.txt || fail "unknown room not rejected"
grep -q "bad-snapshot:ok" /tmp/wm-ep013-m4-failure.txt || fail "malformed snapshot not rejected"
grep -q "bad-version:ok" /tmp/wm-ep013-m4-failure.txt || fail "bad schema version not rejected"
grep -q "invalid-timed:ok" /tmp/wm-ep013-m4-failure.txt || fail "invalid timed window not rejected"
grep -q "no-path:ok" /tmp/wm-ep013-m4-failure.txt || fail "no-path not typed"

echo "failure EP-013 M4 resource-malformed: ok"

#!/usr/bin/env sh
# EP-021 M2 unit test: wire-time-machine crate compiles and its
# deterministic invariants pass (background snapshots, compaction,
# export, restore only from user-approved checkpoints).
set -eu
cd "$(dirname "$0")/../../../../wirecore/crates/wire-time-machine"
cargo test --quiet 2>&1 | tee /tmp/ep021-timemachine-test.log
grep -q "test result: ok" /tmp/ep021-timemachine-test.log || { echo "FAIL: wire-time-machine tests not ok"; exit 1; }
if grep -q "0 failed" /tmp/ep021-timemachine-test.log; then :; else
  echo "FAIL: wire-time-machine has failing tests"; exit 1
fi
echo "wire-time-machine unit: ok"

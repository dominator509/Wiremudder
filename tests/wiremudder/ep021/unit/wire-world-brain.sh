#!/usr/bin/env sh
# EP-021 M2 unit test: wire-world-brain crate compiles and its
# deterministic invariants pass (provenance, confidence, correction
# supersedes without erasing history, hot/durable separation).
set -eu
cd "$(dirname "$0")/../../../../wirecore/crates/wire-world-brain"
cargo test --quiet 2>&1 | tee /tmp/ep021-worldbrain-test.log
grep -q "test result: ok" /tmp/ep021-worldbrain-test.log || { echo "FAIL: wire-world-brain tests not ok"; exit 1; }
if grep -q "0 failed" /tmp/ep021-worldbrain-test.log; then :; else
  echo "FAIL: wire-world-brain has failing tests"; exit 1
fi
echo "wire-world-brain unit: ok"

#!/usr/bin/env sh
# EP-020 M2 unit test: wire-quest crate compiles and its deterministic
# invariants pass (SPEC-012-R06). Real cargo build + test, no mocks.
set -eu
cd "$(dirname "$0")/../../../../wirecore/crates/wire-quest"
cargo test --quiet 2>&1 | tee /tmp/ep020-quest-test.log
# The test binary prints its own result line; require the crate's full
# suite to pass with zero failures.
grep -q "test result: ok" /tmp/ep020-quest-test.log || { echo "FAIL: wire-quest tests not ok"; exit 1; }
if grep -q "0 failed" /tmp/ep020-quest-test.log; then :; else
  echo "FAIL: wire-quest has failing tests"; exit 1
fi
echo "wire-quest unit: ok"

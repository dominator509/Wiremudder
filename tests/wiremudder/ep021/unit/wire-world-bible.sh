#!/usr/bin/env sh
# EP-021 M2 unit test: wire-world-bible crate compiles and its
# deterministic invariants pass (continuity metadata, export, no
# protected assets).
set -eu
cd "$(dirname "$0")/../../../../wirecore/crates/wire-world-bible"
cargo test --quiet 2>&1 | tee /tmp/ep021-worldbible-test.log
grep -q "test result: ok" /tmp/ep021-worldbible-test.log || { echo "FAIL: wire-world-bible tests not ok"; exit 1; }
if grep -q "0 failed" /tmp/ep021-worldbible-test.log; then :; else
  echo "FAIL: wire-world-bible has failing tests"; exit 1
fi
echo "wire-world-bible unit: ok"

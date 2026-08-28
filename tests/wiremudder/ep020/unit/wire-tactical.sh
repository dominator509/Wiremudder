#!/usr/bin/env sh
# EP-020 M2 unit test: wire-tactical crate compiles and its deterministic
# invariants pass (bounded current snapshots). Real cargo build + test.
set -eu
cd "$(dirname "$0")/../../../../wirecore/crates/wire-tactical"
cargo test --quiet 2>&1 | tee /tmp/ep020-tactical-test.log
grep -q "test result: ok" /tmp/ep020-tactical-test.log || { echo "FAIL: wire-tactical tests not ok"; exit 1; }
if grep -q "0 failed" /tmp/ep020-tactical-test.log; then :; else
  echo "FAIL: wire-tactical has failing tests"; exit 1
fi
echo "wire-tactical unit: ok"

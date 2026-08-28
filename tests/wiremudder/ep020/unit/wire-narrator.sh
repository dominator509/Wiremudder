#!/usr/bin/env sh
# EP-020 M2 unit test: wire-narrator crate compiles and its deterministic
# invariants pass (source disclosure, privacy redaction, load shedding,
# no command path). Real cargo build + test.
set -eu
cd "$(dirname "$0")/../../../../wirecore/crates/wire-narrator"
cargo test --quiet 2>&1 | tee /tmp/ep020-narrator-test.log
grep -q "test result: ok" /tmp/ep020-narrator-test.log || { echo "FAIL: wire-narrator tests not ok"; exit 1; }
if grep -q "0 failed" /tmp/ep020-narrator-test.log; then :; else
  echo "FAIL: wire-narrator has failing tests"; exit 1
fi
echo "wire-narrator unit: ok"

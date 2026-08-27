#!/usr/bin/env sh
# EP-014 M4 failure test: typed failures for queue exhaustion, corrupt
# DB, bad migration, missing table.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-storage/Cargo.toml \
  --example failure_matrix > /tmp/wm-ep014-m4-failure.txt 2>/dev/null \
  || fail "failure matrix"

grep -q "queue-full:ok" /tmp/wm-ep014-m4-failure.txt || fail "queue full"
grep -q "corrupt-open:ok" /tmp/wm-ep014-m4-failure.txt || fail "corrupt open"
grep -q "bad-migration:ok" /tmp/wm-ep014-m4-failure.txt || fail "bad migration"
grep -q "missing-table:ok" /tmp/wm-ep014-m4-failure.txt || fail "missing table"

echo "failure EP-014 M4 storage: ok"

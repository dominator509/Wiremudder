#!/usr/bin/env sh
# EP-014 M3 integration test: full transcript lifecycle through the
# real wire-storage crate (queue -> drain -> search -> export -> delete).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-storage/Cargo.toml \
  --example storage_lifecycle > /tmp/wm-ep014-m3-int.txt 2>/dev/null \
  || fail "storage lifecycle"

grep -q "queue-depth:3" /tmp/wm-ep014-m3-int.txt || fail "queue depth"
grep -q "drained:3" /tmp/wm-ep014-m3-int.txt || fail "drain count"
grep -q "stored:3" /tmp/wm-ep014-m3-int.txt || fail "stored count"
grep -q "search-hits:1" /tmp/wm-ep014-m3-int.txt || fail "fts hits"
grep -q "search-snippet:.*griffin" /tmp/wm-ep014-m3-int.txt || fail "snippet"
grep -q "export-has-griffin:true" /tmp/wm-ep014-m3-int.txt || fail "export"
grep -q "deleted:3" /tmp/wm-ep014-m3-int.txt || fail "delete count"
grep -q "after-delete:0" /tmp/wm-ep014-m3-int.txt || fail "after delete"
grep -q "integrity:ok" /tmp/wm-ep014-m3-int.txt || fail "integrity"

echo "integration storage-lifecycle: ok"

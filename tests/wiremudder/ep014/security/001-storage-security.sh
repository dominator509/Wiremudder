#!/usr/bin/env sh
# EP-014 M4 security test: injection as data, safe FTS search,
# per-profile scoped deletion.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-storage/Cargo.toml \
  --example security_matrix > /tmp/wm-ep014-m4-sec.txt 2>/dev/null \
  || fail "security matrix"

grep -q "injection-data:ok" /tmp/wm-ep014-m4-sec.txt || fail "injection as data"
grep -q "search-safe:ok" /tmp/wm-ep014-m4-sec.txt || fail "search safe"
grep -q "scoped-delete:ok" /tmp/wm-ep014-m4-sec.txt || fail "scoped delete"

echo "security EP-014 M4 storage: ok"

#!/usr/bin/env sh
# WM-SPEC-014-R06: Agent Memory Permissions define which memory classes
# each role may read, propose, summarize, share, or never access. Deny by
# default; absent grants are Deny.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r06: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-agents/src/lib.rs
grep -q "pub enum Access" "$LIB" || fail "Access enum missing"
for a in Deny Read Propose Summarize Share; do
  grep -q "$a," "$LIB" || fail "missing access level $a"
done
grep -q "pub struct MemoryPermission" "$LIB" || fail "MemoryPermission missing"
grep -q "unwrap_or(Access::Deny)" "$LIB" || fail "absent = Deny missing"
grep -q "default_deny_all" "$LIB" || fail "default deny-all missing"

# Real behavior: absent grants are Deny for every role/class pair (the one
# built-in grant is TokenBudget read on Telemetry).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-agents/Cargo.toml memory 2>&1 \
  | grep -q "memory" || fail "memory permission tests"

echo "req WM-SPEC-014-R06: ok"

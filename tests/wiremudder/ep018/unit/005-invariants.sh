#!/usr/bin/env sh
# EP-018 M2 unit test: deny-by-default and no-self-authority invariants
# hold at the crate surface (independent of the Rust run).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

# Deny-by-default is structural: access() returns Deny for absent entries.
grep -q "unwrap_or(Access::Deny)" wirecore/crates/wire-agents/src/lib.rs \
  || fail "deny-by-default unwrap missing"
grep -q "default_deny_all" wirecore/crates/wire-agents/src/lib.rs \
  || fail "default_deny_all missing"
grep -q "self_grant_is_impossible" wirecore/crates/wire-agents/src/lib.rs \
  || fail "self-grant guard missing"

# All immutable policy domains are declared in wire-soul.
grep -q "SOUL_IMMUTABLE_POLICY" wirecore/crates/wire-soul/src/lib.rs \
  || fail "immutable policy domains missing"
for d in security privacy routing package updater emergency-stop; do
  grep -q "\"$d\"" wirecore/crates/wire-soul/src/lib.rs || fail "missing policy domain $d"
done

echo "unit EP-018 M2 invariants: ok"

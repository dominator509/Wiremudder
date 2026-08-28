#!/usr/bin/env sh
# EP-018 M5 feature test: WM-FEAT-0181 Mapper and Cartographer Agent.
# Specialized mapper/cartographer roles exist in the registry (R02), their
# memory access is role-scoped and deny-by-default (R06), and no agent can
# grant itself authority.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0181: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-agents/src/lib.rs
grep -q "Mapper," "$LIB" || fail "Mapper role missing"
grep -q "Cartographer," "$LIB" || fail "Cartographer role missing"
grep -q '"mapper"' "$LIB" || fail "mapper key missing"
grep -q '"cartographer"' "$LIB" || fail "cartographer key missing"
grep -q "default_deny_all" "$LIB" || fail "deny-by-default missing"
grep -q "self_grant_is_impossible" "$LIB" || fail "no self-grant guard missing"

# Real behavior: mapper/cartographer memory access is Deny by default.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-agents/Cargo.toml \
  --example security_matrix 2>&1 | grep -q "security matrix: ok" \
  || fail "security matrix (deny-by-default) failed"

echo "feature-0181 mapper-cartographer: ok"

#!/usr/bin/env sh
# EP-018 M5 feature test: WM-FEAT-0042 Soul.md personas.
# A Soul document defines tone, roleplay, boundaries, risk tolerance,
# preferred and forbidden behaviors, and examples (SPEC-014-R03). It can
# never override immutable policy.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0042: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-soul/src/lib.rs
grep -q "pub struct SoulDocument" "$LIB" || fail "SoulDocument missing"
grep -q "pub tone: String" "$LIB" || fail "tone field missing"
grep -q "pub roleplay: String" "$LIB" || fail "roleplay field missing"
grep -q "pub risk_tolerance: String" "$LIB" || fail "risk_tolerance field missing"
grep -q "pub preferred_behaviors" "$LIB" || fail "preferred_behaviors missing"
grep -q "pub forbidden_behaviors" "$LIB" || fail "forbidden_behaviors missing"
grep -q "pub examples" "$LIB" || fail "examples missing"
grep -q "SOUL_IMMUTABLE_POLICY" "$LIB" || fail "immutable policy missing"

# Real behavior: policy override attempts are denied by the crate.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-soul/Cargo.toml soul_cannot_override_policy 2>&1 \
  | grep -q "soul_cannot_override_policy" || fail "soul policy precedence test"

echo "feature-0042 soul-dot-md-personas: ok"

#!/usr/bin/env sh
# WM-SPEC-014-R03: Soul documents define tone, roleplay, boundaries, risk
# tolerance, preferred and forbidden behaviors, and examples but cannot
# override security, privacy, routing, package, updater, or emergency-stop
# policy.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r03: FAIL - $1" >&2; exit 1; }

grep -q "pub struct SoulDocument" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "SoulDocument missing"
grep -q "SOUL_IMMUTABLE_POLICY" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "immutable policy domains missing"
grep -q "policy_precedence_ok" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "policy precedence check missing"

for d in security privacy routing package updater emergency-stop; do
  grep -q "$d" wirecore/crates/wire-copilot/src/lib.rs || fail "missing domain $d"
done

# Schema declares soul fields and the precedence rule.
grep -q "forbidden_behaviors" schemas/wiremudder/copilot/soul-v1.json \
  || fail "soul schema missing forbidden_behaviors"
grep -q "cannot override" schemas/wiremudder/copilot/soul-v1.json \
  || fail "soul schema missing precedence rule"

# The unit tests prove a soul cannot weaken privacy or emergency-stop.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-copilot/Cargo.toml 2>&1 \
  | grep -q "10 passed" || fail "wire-copilot unit tests"

echo "req WM-SPEC-014-R03: ok"

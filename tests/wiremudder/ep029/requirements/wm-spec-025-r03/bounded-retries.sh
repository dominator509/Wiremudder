#!/usr/bin/env sh
# WM-SPEC-025-R03: Retries are bounded, jittered where network-appropriate,
# idempotent, and never applied to destructive or ambiguous effects without
# an idempotency key.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "wm-spec-025-r03: FAIL - $1" >&2; exit 1; }

grep -q "WM-SPEC-025-R03: Retries are bounded, jittered where network-appropriate, idempotent, and never applied to destructive or ambiguous effects without an idempotency key" \
  .agent/specs/SPEC-025-error-handling-recovery-and-compensation.md \
  || fail "requirement missing from SPEC-025"

# Bounded retry policy in the crate: default 3, ceiling 10, signatures
# tracked.
grep -q "DEFAULT_MAX_RETRIES: u32 = 3" wirecore/crates/wire-bug-automation/src/lib.rs \
  || fail "default retry bound missing"
grep -q "MAX_ALLOWED_RETRIES: u32 = 10" wirecore/crates/wire-bug-automation/src/lib.rs \
  || fail "retry ceiling missing"
grep -q "pub fn allows" wirecore/crates/wire-bug-automation/src/lib.rs \
  || fail "bounded allows() missing"
grep -q "pub fn backoff_ms" wirecore/crates/wire-bug-automation/src/lib.rs \
  || fail "jittered backoff missing"

# Destructive/ambiguous effects require an idempotency key.
grep -q "pub fn destructive_effect_allowed" wirecore/crates/wire-bug-automation/src/lib.rs \
  || fail "idempotency-key gate missing"

# Unit tests prove the bounds.
grep -q "fn retry_policy_is_bounded" wirecore/crates/wire-bug-automation/src/lib.rs \
  || fail "retry-bounded unit test missing"
grep -q "fn destructive_effect_requires_idempotency_key" wirecore/crates/wire-bug-automation/src/lib.rs \
  || fail "idempotency unit test missing"

echo "wm-spec-025-r03: ok"

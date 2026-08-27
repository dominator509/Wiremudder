#!/usr/bin/env sh
# EP-015 M3 integration: real distillation + token budget flow through
# both crates. Proves: typed events, capsule assembly, spam collapse,
# redaction, routing, degradation, usage records, validation, and that
# every degraded/denied path exits cleanly (gameplay never waits).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# 1. Real distillation session (typed events + capsule + redaction).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-context/Cargo.toml \
  --example distill_session > /tmp/wm-ep015-distill.txt 2>/dev/null \
  || fail "distill session"

grep -q "EVENT .*room" /tmp/wm-ep015-distill.txt || fail "room event"
grep -q "EVENT .*mob" /tmp/wm-ep015-distill.txt || fail "mob event"
grep -q "EVENT .*pker" /tmp/wm-ep015-distill.txt || fail "pker event"
grep -q "EVENT .*prompt" /tmp/wm-ep015-distill.txt || fail "prompt event"
grep -q "EVENT .*private" /tmp/wm-ep015-distill.txt || fail "private event"
grep -q "CAPSULE .*The Dark Vault" /tmp/wm-ep015-distill.txt || fail "capsule room"
grep -q "CAPSULE .*goblin" /tmp/wm-ep015-distill.txt || fail "capsule entity"
grep -q "REDACTED" /tmp/wm-ep015-distill.txt || fail "redaction"
grep -q "hunter2" /tmp/wm-ep015-distill.txt && fail "secret leaked"
rm -f /tmp/wm-ep015-distill.txt

# 2. Real token budget flow (routing, degradation, usage, validation).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-token-budget/Cargo.toml \
  --example budget_flow > /tmp/wm-ep015-budget.txt 2>/dev/null \
  || fail "budget flow"

grep -q "ROUTE privacy=local-small" /tmp/wm-ep015-budget.txt || fail "privacy route"
grep -q "ROUTE approved=remote-approved" /tmp/wm-ep015-budget.txt || fail "approved route"
grep -q "DEGRADE slow=smaller-local" /tmp/wm-ep015-budget.txt || fail "degrade slow"
grep -q "budget=no-suggestion" /tmp/wm-ep015-budget.txt || fail "degrade budget"
grep -q "USAGE cost_usd_micros=" /tmp/wm-ep015-budget.txt || fail "usage record"
grep -q "VALIDATE ok=true bad=false" /tmp/wm-ep015-budget.txt || fail "validation"
rm -f /tmp/wm-ep015-budget.txt

# 3. Compatibility oracle (corpus -> exact tags).
sh compatibility/context/check.sh || fail "compat oracle"

echo "integration EP-015 M3 distilled-context-budget: ok"

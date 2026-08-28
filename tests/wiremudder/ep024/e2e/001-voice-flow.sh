#!/usr/bin/env sh
# EP-024 M3 e2e test: user-visible voice flow through the real crate.
# 1. Rust voice e2e flow (real crate, real state).
# 2. Mic state always visible; command safety; remote consent; barge-in;
#    degrade-to-text; subtitle privacy.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

# 1. Rust voice e2e flow.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-voice/Cargo.toml \
  --example e2e_voice 2>&1 | tee /tmp/e2e_voice_flow.log
grep -q "E2E voice: ok" /tmp/e2e_voice_flow.log || fail "rust voice e2e"

# 2. Acceptance obligations visible in real output.
grep -q "mic state always visible" /tmp/e2e_voice_flow.log || fail "mic state not shown"
grep -q "Action Proposal" /tmp/e2e_voice_flow.log || fail "command safety not shown"
grep -q "denied under Local Only" /tmp/e2e_voice_flow.log || fail "remote denial not shown"
grep -q "barge-in cancels" /tmp/e2e_voice_flow.log || fail "barge-in not shown"
grep -q "degrade to text" /tmp/e2e_voice_flow.log || fail "degrade to text not shown"
grep -q "private content suppressed" /tmp/e2e_voice_flow.log || fail "subtitle privacy not shown"

echo "e2e EP-024 M3 voice-flow: ok"

#!/usr/bin/env sh
# EP-024 M4 security test: prompt injection, privacy, secrets,
# permission, and abuse boundaries for the voice companion. Fails
# unless every required security proof is true (SPEC-022, node
# contract): injection cannot override command safety, private voice
# content protected by default, secrets never enter transcripts, voice
# has no command path, remote egress blocked by Local Only.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-voice/Cargo.toml \
  --example security_matrix 2>&1 | tee /tmp/ep024_security.log

grep -q "security matrix EP-024: ok 5/5" /tmp/ep024_security.log || fail "security matrix not green"

for n in 1 2 3 4 5; do
  grep -q "security-$n " /tmp/ep024_security.log || fail "security proof $n missing"
done

# The voice boundary must never gain a command path or hidden capture.
BOUNDARY=src/wiremudder/ui/voice/voice_boundary.h
grep -q "canSendCommand() const { return false; }" "$BOUNDARY" || fail "voice boundary has command path"
grep -q "canEditGates() const { return false; }" "$BOUNDARY" || fail "voice boundary can edit gates"

echo "security EP-024 M4 matrix: ok"

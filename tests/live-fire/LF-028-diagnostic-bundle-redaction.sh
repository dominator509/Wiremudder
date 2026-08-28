#!/usr/bin/env sh
# LF-028 live-fire: diagnostic bundle redaction.
#
# Proves the real user outcome: a diagnostic bundle built from a session
# that contains secrets, player names, private messages, and voice
# events is redacted, previewable, content-addressed, and never
# submitted without explicit user action — with real controlled
# dependencies (the production wire-telemetry and wire-replay crates).
set -eu
cd "$(dirname "$0")/../.."

fail() { echo "LF-028: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

out=$(mktemp /tmp/lf028_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" run --quiet \
  --manifest-path wirecore/crates/wire-replay/Cargo.toml \
  --example lf028_live >"$out" 2>&1 || {
  cat "$out" >&2
  fail "LF-028 live run did not execute"
}

# 1. Telemetry remains off externally by default.
grep -q "off by default" "$out" || fail "telemetry not off by default"

# 2. Ring buffers are bounded.
grep -q "bounded" "$out" || fail "ring buffers not bounded"

# 3. Redaction corpus passes: no raw secret survives into preview,
#    export, or fixture.
grep -q "corpus" "$out" || fail "redaction corpus not exercised"
if grep -qE "hunter2|sk-live|AKIA" "$out"; then
  fail "raw secret leaked into live-fire output"
fi

# 4. Replay is deterministic: identical inputs give one content hash.
grep -q "deterministic" "$out" || fail "replay not deterministic"

# 5. Bundle preview matches exported content.
grep -q "preview matches export" "$out" || fail "preview/export mismatch"

# 6. No secret or private data leaks: bundle is never submitted without
#    explicit approval, and the fixture strips player names/voice.
grep -q "never submitted without approval" "$out" || fail "bundle submission not gated"
grep -q "no leaks" "$out" || fail "data leak detected"

grep -q "LF-028 ok" "$out" || fail "LF-028 did not report ok"

echo "LF-028 diagnostic-bundle-redaction: ok"

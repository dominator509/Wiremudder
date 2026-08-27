#!/usr/bin/env sh
# WM-SPEC-013-R03: private messages, credentials, login commands, routing
# secrets, and unapproved voice content are redacted before any provider
# sees the request.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r03: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml \
  --example security_matrix > /tmp/wm-r03.txt 2>&1 \
  || { cat /tmp/wm-r03.txt; fail "security_matrix"; }

grep -q "SEC redaction-classes: ok" /tmp/wm-r03.txt || fail "redaction classes not proven"
grep -q "SEC prompt-injection-data: ok" /tmp/wm-r03.txt || fail "injection data"

echo "req WM-SPEC-013-R03: ok"

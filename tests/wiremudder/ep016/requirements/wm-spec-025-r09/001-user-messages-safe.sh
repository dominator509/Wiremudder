#!/usr/bin/env sh
# WM-SPEC-025-R09: user-facing messages do not expose stack traces, paths,
# credentials, private text, provider payloads, or signing metadata.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r09: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml \
  --example security_matrix > /tmp/wm-r09.txt 2>&1 \
  || { cat /tmp/wm-r09.txt; fail "security_matrix"; }

grep -q "SEC injection-errors: ok" /tmp/wm-r09.txt || fail "user messages not proven safe"

# user_message() exists and returns the safe surface.
grep -q "pub fn user_message" wirecore/crates/wire-provider-adapters/src/lib.rs \
  || fail "missing user_message"

echo "req WM-SPEC-025-R09: ok"

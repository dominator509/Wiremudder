#!/usr/bin/env sh
# EP-016 M4 security: real abuse cases against the adapter and router.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml \
  --example security_matrix > /tmp/wm-ep016-security.txt 2>&1 \
  || { cat /tmp/wm-ep016-security.txt; fail "security_matrix"; }

for step in injection-errors prompt-injection-data redaction-classes permission-denial egress-boundary privacy-gate; do
  grep -q "SEC $step: ok" /tmp/wm-ep016-security.txt || fail "security step $step not proven"
done
grep -q "SECURITY_MATRIX_DONE" /tmp/wm-ep016-security.txt || fail "missing done sentinel"

echo "security EP-016 M4 adapter-router-abuse: ok"

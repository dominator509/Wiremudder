#!/usr/bin/env sh
# EP-015 M4 security test: injection as data, secrets redacted, private
# message redaction, output secret/policy rejection, route permission,
# minimal supply chain, data integrity.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-context/Cargo.toml \
  --example security_matrix > /tmp/wm-ep015-m4-sec.txt 2>/dev/null \
  || fail "security matrix (context)"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-token-budget/Cargo.toml \
  --example security_matrix > /tmp/wm-ep015-m4-sec-budget.txt 2>/dev/null \
  || fail "security matrix (budget)"

for sentinel in injection-data secrets-redacted private-redacted \
                supply-chain-minimal data-integrity; do
  grep -q "${sentinel}:ok" /tmp/wm-ep015-m4-sec.txt || fail "$sentinel"
done
for sentinel in output-secret-rejected output-policy-rejected route-permission \
                supply-chain-minimal; do
  grep -q "${sentinel}:ok" /tmp/wm-ep015-m4-sec-budget.txt || fail "$sentinel"
done

echo "security EP-015 M4 context-budget: ok"

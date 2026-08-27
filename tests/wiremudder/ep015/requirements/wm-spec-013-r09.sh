# WM-SPEC-013-R09: AI output is untrusted data and passes schema,
# citation, policy, and command-safety validation before use.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "wm-spec-013-r09: FAIL - $1" >&2; exit 1; }
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-token-budget/Cargo.toml \
  --example security_matrix > /tmp/wm-r09.txt 2>/dev/null || fail "security matrix"
grep -q "output-secret-rejected:ok" /tmp/wm-r09.txt || fail "secret rejection"
grep -q "output-policy-rejected:ok" /tmp/wm-r09.txt || fail "policy rejection"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-token-budget/Cargo.toml validation_rejects_untrusted \
  >/dev/null 2>&1 || fail "validation test"
rm -f /tmp/wm-r09.txt
echo "wm-spec-013-r09: ok"

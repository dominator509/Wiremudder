# WM-SPEC-013-R05: routing considers task, complexity, privacy, risk,
# latency, cost, locality, availability, context size, and user policy.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "wm-spec-013-r05: FAIL - $1" >&2; exit 1; }
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-token-budget/Cargo.toml \
  --example budget_flow > /tmp/wm-r05.txt 2>/dev/null || fail "budget flow"
grep -q "ROUTE privacy=local-small" /tmp/wm-r05.txt || fail "privacy route"
grep -q "ROUTE approved=remote-approved" /tmp/wm-r05.txt || fail "approved route"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-token-budget/Cargo.toml routing_never_remote_without_privacy \
  >/dev/null 2>&1 || fail "routing privacy test"
rm -f /tmp/wm-r05.txt
echo "wm-spec-013-r05: ok"

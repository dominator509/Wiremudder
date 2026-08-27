#!/usr/bin/env sh
# EP-015 M4 failure test: typed failures in both crates (malformed,
# oversized, duplicate, capsule bounds, dashboard full, budget exceeded,
# unavailable, timeout, cancel, policy denial, partial effects).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-token-budget/Cargo.toml \
  --example failure_matrix > /tmp/wm-ep015-m4-failure.txt 2>/dev/null \
  || fail "failure matrix (budget)"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-context/Cargo.toml \
  --example failure_matrix > /tmp/wm-ep015-m4-failure-ctx.txt 2>/dev/null \
  || fail "failure matrix (context)"

for sentinel in dashboard-full budget-exceeded unavailable timeout cancel \
                policy-denied partial-effect; do
  grep -q "${sentinel}:ok" /tmp/wm-ep015-m4-failure.txt || fail "$sentinel"
done
for sentinel in malformed-input oversized-input duplicate-collapsed capsule-bounded; do
  grep -q "${sentinel}:ok" /tmp/wm-ep015-m4-failure-ctx.txt || fail "$sentinel"
done

echo "failure EP-015 M4 context-budget: ok"

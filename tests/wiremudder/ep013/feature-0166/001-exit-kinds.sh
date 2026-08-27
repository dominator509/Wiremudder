#!/usr/bin/env sh
# WM-FEAT-0166: custom hidden locked one-way and portal exits.
# Proves typed exit semantics: one-way not reversible, locked/hidden
# blocked, portal traversable, door status honored, exit bounds.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0166: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-world-graph/Cargo.toml \
  --example failure_matrix > /tmp/wm-feat-0166.log 2>/dev/null \
  || fail "failure matrix"
grep -q "duplicate-exit:ok" /tmp/wm-feat-0166.log || fail "duplicate exit"
grep -q "invalid-timed:ok" /tmp/wm-feat-0166.log || fail "invalid timed"

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-world-graph/Cargo.toml \
  --example security_matrix > /tmp/wm-feat-0166-sec.log 2>/dev/null \
  || fail "security matrix"
grep -q "denied-policy:ok" /tmp/wm-feat-0166-sec.log || fail "denied policy"

echo "feature-0166 custom-hidden-locked-oneway-portal-exits: ok"

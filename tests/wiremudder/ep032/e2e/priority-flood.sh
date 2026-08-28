#!/usr/bin/env sh
# EP-032 M3 e2e test: real priority-flood flow through the production
# benchmark model. A P3 renderer-emit flood must not stall the P0 outbound
# queue (constitution prime directive: P0 never waits on optional work),
# the P0 budget stays met, and the flooded P3 queue degrades by coalescing
# instead of blocking.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

cat > /tmp/ep032_e2e_harness.rs <<'EOF'
use wiremudder_benchmarks::{BoundedQueue, Budget, OverflowPolicy, PriorityRing, QueueSpec};

fn main() {
    // P0 outbound queue: bounded, 10ms budget.
    let mut outbound = BoundedQueue::new(QueueSpec::new(
        "outbound", "commands", PriorityRing::P0, 1000, OverflowPolicy::Process,
        Budget::new(10_000, None, false),
    ));

    // P3 renderer-emit flood: coalesce policy, 6ms frame budget.
    let mut emits = BoundedQueue::new(QueueSpec::new(
        "renderer-emits", "renderer", PriorityRing::P3, 8, OverflowPolicy::Coalesce,
        Budget::new(6_000, None, true),
    ));

    // Simulate a renderer flood: many emits land while P0 keeps working.
    let mut flood = 0;
    for i in 0..2000 {
        if emits.push(i, 100) {
            flood += 1;
        }
        // P0 manual input/command send proceeds every iteration regardless.
        outbound.push(i, 50);
        // Drain P0 so it never builds up.
        while outbound.pop().is_some() {}
    }

    // The P3 flood coalesced rather than blocking; P0 processed all work
    // and never exceeded its 10ms budget on the distribution.
    assert!(emits.coalesced > 0, "flood must coalesce at capacity");
    assert!(outbound.budget_met(), "P0 budget must stay met under P3 flood");
    assert!(outbound.dropped == 0, "P0 must not drop under optional flood");

    println!("e2e priority-flood: ok flood={} coalesced={} p0_processed={}",
             flood, emits.coalesced, outbound.processed);
}
EOF

rm -rf /tmp/ep032_e2e_src /tmp/ep032_e2e_target
mkdir -p /tmp/ep032_e2e_src/src
cat > /tmp/ep032_e2e_src/Cargo.toml <<EOF
[package]
name = "ep032_e2e"
version = "0.1.0"
edition = "2021"

[dependencies]
wiremudder-benchmarks = { path = "/root/wiremudder-repo/benchmarks/wiremudder" }
EOF
cp /tmp/ep032_e2e_harness.rs /tmp/ep032_e2e_src/src/main.rs
out=$(mktemp /tmp/ep032_e2e_XXXX.log)
CARGO_TARGET_DIR=/tmp/ep032_e2e_target "$cargo_bin" run --quiet \
  --manifest-path /tmp/ep032_e2e_src/Cargo.toml >"$out" 2>&1 || {
  cat "$out" >&2
  echo "EP-032 e2e harness FAILED" >&2
  exit 1
}
grep -q "e2e priority-flood: ok" "$out" || fail "e2e sentinel missing"

echo "e2e EP-032 priority-flood: ok"
cat "$out"

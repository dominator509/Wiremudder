#!/usr/bin/env sh
# EP-032 M3 integration test: the benchmark model's queue/fairness core is
# exercised through the real crate binary (not mocked): priority rings,
# bounded queues with overflow, session fairness, and degradation that
# always preserves raw text (WM-FEAT-0134/0135/0138/0141, WM-SPEC-004-R06
# .. R10).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

cat > /tmp/ep032_model_harness.rs <<'EOF'
use wiremudder_benchmarks::{
    BoundedQueue, Budget, DegradationState, FairnessGovernor, OverflowPolicy, PriorityRing,
    QueueSpec,
};

fn main() {
    // P0 outbound queue: bounded, process-oldest on overflow, budget 10ms.
    let mut outbound = BoundedQueue::new(QueueSpec::new(
        "outbound", "commands", PriorityRing::P0, 4, OverflowPolicy::Process,
        Budget::new(10_000, None, false),
    ));
    for i in 0..10 {
        outbound.push(i, 100);
    }
    assert_eq!(outbound.processed, 10);
    assert_eq!(outbound.pop(), Some(6), "oldest items evicted by process policy");

    // P3 renderer emits: coalesce on overflow, frame budget 6ms.
    let mut emits = BoundedQueue::new(QueueSpec::new(
        "renderer-emits", "renderer", PriorityRing::P3, 2, OverflowPolicy::Coalesce,
        Budget::new(6_000, None, true),
    ));
    emits.push(1, 10);
    emits.push(2, 10);
    emits.push(3, 10);
    assert_eq!(emits.coalesced, 1);
    assert_eq!(emits.pop(), Some(1));
    assert_eq!(emits.pop(), Some(3));

    // P1 trigger queue: slow rule quarantine (drop + quarantine count).
    let mut triggers = BoundedQueue::new(QueueSpec::new(
        "triggers", "parser", PriorityRing::P1, 1, OverflowPolicy::Quarantine,
        Budget::new(1_000, Some(1024), true),
    ));
    assert!(triggers.push(1, 10));
    assert!(!triggers.push(2, 10), "quarantine drops at capacity");
    assert_eq!(triggers.quarantined, 1);

    // Fairness: one busy session cannot starve another (R09).
    let mut governor = FairnessGovernor::new(2);
    assert!(governor.may_proceed("busy"));
    governor.record_work("busy");
    assert!(governor.may_proceed("busy"));
    governor.record_work("busy");
    assert!(!governor.may_proceed("busy"));
    assert!(governor.may_proceed("other"), "other session must not starve");
    governor.reset_round();
    assert!(governor.may_proceed("busy"), "round reset prevents starvation");

    // Degradation always preserves raw text (prime directive).
    for s in [DegradationState::Dropping, DegradationState::Frozen, DegradationState::Quarantined] {
        assert!(s.preserves_raw_text());
    }

    println!("integration model harness: ok");
}
EOF

rm -rf /tmp/ep032_model_src /tmp/ep032_model_target
mkdir -p /tmp/ep032_model_src/src
cat > /tmp/ep032_model_src/Cargo.toml <<EOF
[package]
name = "ep032_model"
version = "0.1.0"
edition = "2021"

[dependencies]
wiremudder-benchmarks = { path = "/root/wiremudder-repo/benchmarks/wiremudder" }
EOF
cp /tmp/ep032_model_harness.rs /tmp/ep032_model_src/src/main.rs
CARGO_TARGET_DIR=/tmp/ep032_model_target "$cargo_bin" run --quiet \
  --manifest-path /tmp/ep032_model_src/Cargo.toml 2>&1 | tail -3 || {
  echo "EP-032 model harness FAILED" >&2
  exit 1
}

echo "integration EP-032 model-core: ok"

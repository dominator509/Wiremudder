#!/usr/bin/env sh
# EP-032 M4 failure test: forced failures and abuse cases against the
# benchmark model — queue budget exhaustion, malicious overflow, quota
# denial, and fairness starvation attempts must all fail closed: P0 keeps
# its budget, no session is starved, degradation preserves raw text.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

cat > /tmp/ep032_failure_harness.rs <<'EOF'
use wiremudder_benchmarks::{BoundedQueue, Budget, DegradationState, FairnessGovernor, OverflowPolicy, PriorityRing, QueueSpec};

fn main() {
    // 1. Resource / queue budget exhaustion: an unbounded flood against a
    //    bounded P0 queue must not exceed the declared budget and must
    //    process-oldest rather than grow without limit.
    let mut outbound = BoundedQueue::new(QueueSpec::new(
        "outbound", "commands", PriorityRing::P0, 16, OverflowPolicy::Process,
        Budget::new(10_000, None, false),
    ));
    for i in 0..100_000 {
        outbound.push(i, 50);
    }
    assert_eq!(outbound.len(), 16, "queue must stay at capacity");
    assert_eq!(outbound.processed, 100_000, "all items processed via eviction");
    assert!(outbound.budget_met(), "P0 budget must hold under exhaustion");

    // 2. Malformed / oversized input: a queue with a tiny memory budget
    //    must not be able to admit work beyond it via the API (capacity
    //    bound enforced by overflow policy, no panic).
    let mut tight = BoundedQueue::new(QueueSpec::new(
        "triggers", "parser", PriorityRing::P1, 1, OverflowPolicy::Quarantine,
        Budget::new(1_000, Some(1024), true),
    ));
    for i in 0..10_000 {
        tight.push(i, 100);
    }
    assert_eq!(tight.len(), 1);
    assert_eq!(tight.quarantined, 9_999, "overflow must quarantine");

    // 3. Timeout and cancellation: P3 cancelable work is dropped at
    //    capacity rather than blocking; the drop count is observable.
    let mut voice = BoundedQueue::new(QueueSpec::new(
        "voice-jobs", "voice", PriorityRing::P3, 4, OverflowPolicy::Drop,
        Budget::new(5_000, None, true),
    ));
    for i in 0..100 {
        voice.push(i, 100);
    }
    assert_eq!(voice.dropped, 96, "overflow must drop");
    assert!(voice.budget_met());

    // 4. Duplicate / replayed request: repeated identical pushes are
    //    handled idempotently by the queue (capacity-bounded, no panic).
    let mut q = BoundedQueue::new(QueueSpec::new(
        "ipc", "ui", PriorityRing::P1, 8, OverflowPolicy::Drop,
        Budget::new(1_000, None, true),
    ));
    for _ in 0..3 {
        for i in 0..8 {
            q.push(i, 10);
        }
    }
    assert_eq!(q.processed, 8, "only the first bounded round is admitted");
    assert_eq!(q.dropped, 16, "replayed rounds drop at capacity");

    // 5. Denied permission / consent / policy: a session that has
    //    consumed its fair share is denied further work until the round
    //    resets — other sessions are never blocked.
    let mut g = FairnessGovernor::new(1);
    assert!(g.may_proceed("a"));
    g.record_work("a");
    assert!(!g.may_proceed("a"), "quota must deny the busy session");
    assert!(g.may_proceed("b"), "other session must proceed");

    // 6. Partial side effect and compensation: after a queue is drained,
    //    metrics remain accurate and the queue accepts new work.
    let mut q2 = BoundedQueue::new(QueueSpec::new(
        "soundscape", "soundscape", PriorityRing::P3, 4, OverflowPolicy::Coalesce,
        Budget::new(5_000, None, true),
    ));
    q2.push(1, 10);
    q2.push(2, 10);
    assert_eq!(q2.pop(), Some(1));
    assert_eq!(q2.pop(), Some(2));
    assert_eq!(q2.pop(), None);
    q2.push(3, 10);
    assert_eq!(q2.pop(), Some(3), "queue must accept work after drain");

    // 7. Unavailable dependency / worker: degraded subsystem still
    //    preserves raw text (fallback is invariant).
    for s in [DegradationState::Disabled, DegradationState::Frozen, DegradationState::Quarantined] {
        assert!(s.preserves_raw_text());
    }

    // 8. Preserved manual gameplay and data integrity: after all abuse,
    //    the P0 queue still has budget met and the fairness governor still
    //    admits new sessions.
    assert!(outbound.budget_met());
    assert!(g.may_proceed("c"));

    println!("failure benchmark-fail-closed: ok");
}
EOF

rm -rf /tmp/ep032_failure_src /tmp/ep032_failure_target
mkdir -p /tmp/ep032_failure_src/src
cat > /tmp/ep032_failure_src/Cargo.toml <<EOF
[package]
name = "ep032_failure"
version = "0.1.0"
edition = "2021"

[dependencies]
wiremudder-benchmarks = { path = "/root/wiremudder-repo/benchmarks/wiremudder" }
EOF
cp /tmp/ep032_failure_harness.rs /tmp/ep032_failure_src/src/main.rs
out=$(mktemp /tmp/ep032_failure_XXXX.log)
CARGO_TARGET_DIR=/tmp/ep032_failure_target "$cargo_bin" run --quiet \
  --manifest-path /tmp/ep032_failure_src/Cargo.toml >"$out" 2>&1 || {
  cat "$out" >&2
  echo "EP-032 failure harness FAILED" >&2
  exit 1
}
grep -q "failure benchmark-fail-closed: ok" "$out" || fail "failure sentinel missing"

echo "failure EP-032 benchmark-fail-closed: ok"

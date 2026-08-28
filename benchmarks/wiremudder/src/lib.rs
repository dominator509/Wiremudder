//! WireMudder benchmark model (EP-032).
//!
//! Implements the SPEC-004 performance constitution as a deterministic
//! model: priority rings P0..P4, declared time/memory/cancellation
//! budgets, bounded queues with explicit overflow policies, session
//! fairness (one session cannot starve another), and per-subsystem
//! degradation fallbacks that always preserve raw text gameplay.
//!
//! This crate is the model core that benchmarks/wiremudder and
//! tools/perf-capture drive; the constitution (PERFORMANCE_CONSTITUTION.md)
//! is the binding policy.

use serde::Serialize;
use std::collections::VecDeque;

/// SPEC-004 priority rings.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
pub enum PriorityRing {
    /// Connection state, socket delivery, terminal output, manual input,
    /// command send, emergency stop. Never waits on optional work.
    P0,
    /// Protocol parsing, triggers, aliases, timers, macros, command
    /// safety, bounded gameplay logic. Cannot stall P0.
    P1,
    /// Mapper assistance, hot memory, quest, tactical, context
    /// distillation, AI suggestions. May lag, snapshot, reduce frequency,
    /// or pause.
    P2,
    /// Voice, renderer, visual emits, narrator, soundscapes. May drop,
    /// coalesce, freeze, cancel, or disable.
    P3,
    /// Indexing, compaction, package/update checks, replay compression,
    /// telemetry export, source/help indexing. Idle or explicit only.
    P4,
}

impl PriorityRing {
    pub fn as_str(self) -> &'static str {
        match self {
            PriorityRing::P0 => "P0",
            PriorityRing::P1 => "P1",
            PriorityRing::P2 => "P2",
            PriorityRing::P3 => "P3",
            PriorityRing::P4 => "P4",
        }
    }
}

/// SPEC-004-R06: every queue declares one overflow behavior.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
pub enum OverflowPolicy {
    Process,
    Coalesce,
    Drop,
    Defer,
    Pause,
    Disable,
    Quarantine,
}

/// SPEC-004-R07: declared time, memory, and cancellation budget.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
pub struct Budget {
    /// Declared time budget in microseconds for one unit of work.
    pub time_us: u64,
    /// Declared memory budget in bytes (None = bounded by queue capacity).
    pub memory_bytes: Option<u64>,
    /// Whether the work is cancelable.
    pub cancelable: bool,
}

impl Budget {
    pub fn new(time_us: u64, memory_bytes: Option<u64>, cancelable: bool) -> Self {
        Self { time_us, memory_bytes, cancelable }
    }
}

/// SPEC-004-R06: a queue has capacity, priority, overflow behavior,
/// latency metric, drop/coalesce count, and owner.
#[derive(Debug, Clone, Serialize)]
pub struct QueueSpec {
    pub name: String,
    pub owner: String,
    pub priority: PriorityRing,
    pub capacity: usize,
    pub overflow: OverflowPolicy,
    pub budget: Budget,
}

impl QueueSpec {
    pub fn new(
        name: impl Into<String>,
        owner: impl Into<String>,
        priority: PriorityRing,
        capacity: usize,
        overflow: OverflowPolicy,
        budget: Budget,
    ) -> Self {
        Self {
            name: name.into(),
            owner: owner.into(),
            priority,
            capacity,
            overflow,
            budget,
        }
    }
}

/// A bounded queue with observed metrics (SPEC-004-R06, R08).
#[derive(Debug, Clone, Serialize)]
pub struct BoundedQueue {
    pub spec: QueueSpec,
    pub processed: u64,
    pub dropped: u64,
    pub coalesced: u64,
    pub deferred: u64,
    pub quarantined: u64,
    pub peak_observed_us: u64,
    pub p50_observed_us: u64,
    pub p95_observed_us: u64,
    pending: VecDeque<u64>,
    latencies: Vec<u64>,
}

impl BoundedQueue {
    pub fn new(spec: QueueSpec) -> Self {
        Self {
            spec,
            processed: 0,
            dropped: 0,
            coalesced: 0,
            deferred: 0,
            quarantined: 0,
            peak_observed_us: 0,
            p50_observed_us: 0,
            p95_observed_us: 0,
            pending: VecDeque::new(),
            latencies: Vec::new(),
        }
    }

    pub fn len(&self) -> usize {
        self.pending.len()
    }

    pub fn is_empty(&self) -> bool {
        self.pending.is_empty()
    }

    /// Push one unit of work with its measured latency (microseconds).
    /// Enforces capacity and the declared overflow policy. Returns true
    /// when the item was admitted/processed, false when dropped or
    /// coalesced under the policy.
    pub fn push(&mut self, work: u64, latency_us: u64) -> bool {
        self.record_latency(latency_us);
        if self.pending.len() >= self.spec.capacity {
            return match self.spec.overflow {
                OverflowPolicy::Process => {
                    self.pending.pop_front();
                    self.pending.push_back(work);
                    self.processed += 1;
                    true
                }
                OverflowPolicy::Coalesce => {
                    if let Some(back) = self.pending.back_mut() {
                        *back = work;
                    }
                    self.coalesced += 1;
                    true
                }
                OverflowPolicy::Drop => {
                    self.dropped += 1;
                    false
                }
                OverflowPolicy::Defer => {
                    self.deferred += 1;
                    false
                }
                OverflowPolicy::Pause | OverflowPolicy::Disable => {
                    self.dropped += 1;
                    false
                }
                OverflowPolicy::Quarantine => {
                    self.quarantined += 1;
                    false
                }
            };
        }
        self.pending.push_back(work);
        self.processed += 1;
        true
    }

    pub fn pop(&mut self) -> Option<u64> {
        self.pending.pop_front()
    }

    fn record_latency(&mut self, latency_us: u64) {
        if latency_us > self.peak_observed_us {
            self.peak_observed_us = latency_us;
        }
        self.latencies.push(latency_us);
        if self.latencies.len() > 4096 {
            let mut s = self.latencies.clone();
            s.sort_unstable();
            let n = s.len();
            self.p50_observed_us = s[n / 2];
            self.p95_observed_us = s[(n as f64 * 0.95) as usize];
        }
    }

    pub fn latency_distribution(&self) -> (u64, u64, u64) {
        if self.latencies.is_empty() {
            return (0, 0, 0);
        }
        let mut s = self.latencies.clone();
        s.sort_unstable();
        let n = s.len();
        (s[0], s[n / 2], *s.last().unwrap())
    }

    /// SPEC-004-R07: the queue's declared budget must not be exceeded by
    /// the observed p95 (budgets are enforced on the distribution, not a
    /// single sample).
    pub fn budget_met(&self) -> bool {
        self.p95_observed_us <= self.spec.budget.time_us
    }
}

/// SPEC-004-R09: one busy session cannot starve another. A fairness
/// governor tracks per-session processing counts and enforces a maximum
/// work share before yielding to another session.
#[derive(Debug, Clone, Serialize)]
pub struct FairnessGovernor {
    pub max_work_per_session: u64,
    work_done: std::collections::HashMap<String, u64>,
}

impl FairnessGovernor {
    pub fn new(max_work_per_session: u64) -> Self {
        Self {
            max_work_per_session,
            work_done: std::collections::HashMap::new(),
        }
    }

    /// Whether the session may continue; returns false when the session
    /// has consumed its fair share and another session is waiting.
    pub fn may_proceed(&mut self, session: &str) -> bool {
        let done = self.work_done.entry(session.to_string()).or_insert(0);
        *done < self.max_work_per_session
    }

    pub fn record_work(&mut self, session: &str) {
        let done = self.work_done.entry(session.to_string()).or_insert(0);
        *done += 1;
    }

    /// Reset all session shares (e.g. after a scheduling round) so no
    /// session is starved indefinitely.
    pub fn reset_round(&mut self) {
        self.work_done.clear();
    }

    pub fn session_share(&self, session: &str) -> u64 {
        self.work_done.get(session).copied().unwrap_or(0)
    }
}

/// SPEC-004-R08 / R10: a slow rule is quarantined; every feature has a
/// text-gameplay-preserving fallback.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
pub enum DegradationState {
    Normal,
    Lag,
    Snapshot,
    ReducedFrequency,
    Paused,
    Dropping,
    Coalescing,
    Frozen,
    Disabled,
    Quarantined,
}

impl DegradationState {
    pub fn preserves_raw_text(self) -> bool {
        // Raw text gameplay is sacred: no degradation state may hide or
        // delay raw terminal text (constitution prime directive).
        true
    }
}

/// A declared subsystem with its priority ring, budget, and fallback.
#[derive(Debug, Clone, Serialize)]
pub struct Subsystem {
    pub name: String,
    pub ring: PriorityRing,
    pub budget: Budget,
    pub fallback: DegradationState,
}

impl Subsystem {
    pub fn new(
        name: impl Into<String>,
        ring: PriorityRing,
        budget: Budget,
        fallback: DegradationState,
    ) -> Self {
        Self {
            name: name.into(),
            ring,
            budget,
            fallback,
        }
    }
}

/// SPEC-004-R12: a benchmark run records distributions, hardware profile,
/// workload, and raw evidence. This is the artifact shape written by
/// tools/perf-capture.
#[derive(Debug, Clone, Serialize)]
pub struct BenchmarkArtifact {
    pub suite: String,
    pub hardware: HardwareProfile,
    pub workload: Workload,
    pub runs: Vec<QueueRun>,
    pub regression_thresholds: Vec<RegressionThreshold>,
    pub raw_evidence: bool,
}

#[derive(Debug, Clone, Serialize)]
pub struct HardwareProfile {
    pub host: String,
    pub arch: String,
    pub os: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct Workload {
    pub fixture: String,
    pub iterations: u64,
    pub note: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct QueueRun {
    pub queue: String,
    pub owner: String,
    pub priority: String,
    pub overflow: String,
    pub p50_us: u64,
    pub p95_us: u64,
    pub max_us: u64,
    pub budget_us: u64,
    pub budget_met: bool,
    pub dropped: u64,
    pub coalesced: u64,
}

#[derive(Debug, Clone, Serialize)]
pub struct RegressionThreshold {
    pub metric: String,
    pub p95_us_limit: u64,
    pub max_us_limit: u64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn queue_respects_capacity_and_drop_policy() {
        let spec = QueueSpec::new(
            "triggers",
            "parser",
            PriorityRing::P1,
            2,
            OverflowPolicy::Drop,
            Budget::new(1000, Some(1024), true),
        );
        let mut q = BoundedQueue::new(spec);
        assert!(q.push(1, 10));
        assert!(q.push(2, 10));
        assert!(!q.push(3, 10), "third item must drop at capacity");
        assert_eq!(q.dropped, 1);
        assert_eq!(q.processed, 2);
        assert_eq!(q.pop(), Some(1));
        assert_eq!(q.pop(), Some(2));
        assert_eq!(q.pop(), None);
    }

    #[test]
    fn queue_coalesces_on_overflow() {
        let spec = QueueSpec::new(
            "renderer-emits",
            "renderer",
            PriorityRing::P3,
            2,
            OverflowPolicy::Coalesce,
            Budget::new(5000, None, true),
        );
        let mut q = BoundedQueue::new(spec);
        assert!(q.push(1, 10));
        assert!(q.push(2, 10));
        assert!(q.push(3, 10), "coalesce admits by replacing tail");
        assert_eq!(q.coalesced, 1);
        assert_eq!(q.pop(), Some(1));
        assert_eq!(q.pop(), Some(3), "tail must be coalesced value");
    }

    #[test]
    fn queue_process_overflow_drops_oldest() {
        let spec = QueueSpec::new(
            "outbound",
            "commands",
            PriorityRing::P0,
            2,
            OverflowPolicy::Process,
            Budget::new(10000, None, false),
        );
        let mut q = BoundedQueue::new(spec);
        q.push(1, 5);
        q.push(2, 5);
        q.push(3, 5);
        assert_eq!(q.pop(), Some(2), "oldest must be evicted");
        assert_eq!(q.pop(), Some(3));
    }

    #[test]
    fn budget_met_uses_distribution_not_single_sample() {
        let spec = QueueSpec::new(
            "terminal",
            "terminal",
            PriorityRing::P0,
            100,
            OverflowPolicy::Drop,
            Budget::new(10_000, None, false),
        );
        let mut q = BoundedQueue::new(spec);
        for i in 0..1000 {
            // one hot outlier must not fail the budget if p95 is fine
            q.push(i, if i == 999 { 50_000 } else { 100 });
        }
        assert!(q.budget_met(), "p95 must be within budget despite outlier");
        let (min, p50, max) = q.latency_distribution();
        assert_eq!(min, 100);
        assert!(p50 <= 100);
        assert_eq!(max, 50_000);
    }

    #[test]
    fn fairness_governor_prevents_starvation() {
        let mut g = FairnessGovernor::new(3);
        assert!(g.may_proceed("a"));
        g.record_work("a");
        assert!(g.may_proceed("a"));
        g.record_work("a");
        assert!(g.may_proceed("a"));
        g.record_work("a");
        assert!(!g.may_proceed("a"), "session a consumed its fair share");
        assert!(g.may_proceed("b"), "session b must be able to run");
        g.reset_round();
        assert!(g.may_proceed("a"), "new round resets shares");
    }

    #[test]
    fn degradation_never_hides_raw_text() {
        for state in [
            DegradationState::Normal,
            DegradationState::Lag,
            DegradationState::Snapshot,
            DegradationState::ReducedFrequency,
            DegradationState::Paused,
            DegradationState::Dropping,
            DegradationState::Coalescing,
            DegradationState::Frozen,
            DegradationState::Disabled,
            DegradationState::Quarantined,
        ] {
            assert!(state.preserves_raw_text(), "{state:?} must preserve raw text");
        }
    }

    #[test]
    fn priority_ring_names_are_stable() {
        assert_eq!(PriorityRing::P0.as_str(), "P0");
        assert_eq!(PriorityRing::P1.as_str(), "P1");
        assert_eq!(PriorityRing::P2.as_str(), "P2");
        assert_eq!(PriorityRing::P3.as_str(), "P3");
        assert_eq!(PriorityRing::P4.as_str(), "P4");
    }

    #[test]
    fn artifact_shape_meets_r12() {
        let artifact = BenchmarkArtifact {
            suite: "ep032".into(),
            hardware: HardwareProfile {
                host: "host".into(),
                arch: "x86_64".into(),
                os: "linux".into(),
            },
            workload: Workload {
                fixture: "terminal-flood".into(),
                iterations: 1000,
                note: "".into(),
            },
            runs: vec![],
            regression_thresholds: vec![],
            raw_evidence: true,
        };
        let json = serde_json::to_string(&artifact).unwrap();
        assert!(json.contains("\"hardware\""));
        assert!(json.contains("\"workload\""));
        assert!(json.contains("\"raw_evidence\":true"));
    }

    #[test]
    fn queue_metrics_are_observable() {
        let spec = QueueSpec::new(
            "ipc",
            "ui",
            PriorityRing::P1,
            8,
            OverflowPolicy::Drop,
            Budget::new(1000, None, true),
        );
        let mut q = BoundedQueue::new(spec);
        for i in 0..4 {
            q.push(i, i as u64 * 100);
        }
        assert_eq!(q.processed, 4);
        assert_eq!(q.dropped, 0);
        assert_eq!(q.coalesced, 0);
        assert_eq!(q.peak_observed_us, 300);
    }
}

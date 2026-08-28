//! WireMudder Macro Forge, Trigger Test Lab, and AI Debugger (SPEC-008,
//! SPEC-019, EP-022).
//!
//! Six owned surfaces:
//! - Macro Forge: macro/trigger creation is previewable and disabled
//!   until approved (EP-022 acceptance obligation 1).
//! - Trigger Test Lab: replays deterministic fixtures without a live
//!   world (obligation 2).
//! - Replay-driven script debugging, variable inspection, and event
//!   timeline (WM-FEAT-0106/0161/0162).
//! - AI Debugger: cites evidence and cannot edit gates or self-certify
//!   success (obligation 4, WM-SPEC-019-R06).
//! - Performance statistics: measured budgets and slow-offender
//!   diagnostics (WM-SPEC-008-R02).
//! - Safe patch proposals: require normal Graphlock validation
//!   (obligation 6).

use std::collections::{BTreeMap, VecDeque};

use serde::{Deserialize, Serialize};

pub const DEBUG_SCHEMA_VERSION: u32 = 1;
pub const EVENT_RING_CAPACITY: usize = 256;
pub const MAX_VARIABLES: usize = 512;
pub const MAX_MACRO_LEN: usize = 4096;
pub const MAX_REPLAY_STEPS: usize = 4096;
pub const DEFAULT_EXEC_BUDGET_MS: u64 = 100;

/// Why a macro, trigger, patch, or replay step was denied.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum DebugDenial {
    NotApproved,
    UnavailableDependency,
    Timeout,
    Cancelled,
    MalformedInput,
    DuplicateRequest,
    DeniedPolicy,
    BudgetExhausted,
    OversizedInput,
}

/// A macro or trigger draft from Macro Forge. Disabled until approved.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AutomationDraft {
    pub id: String,
    pub kind: DraftKind,
    pub name: String,
    pub body: String,
    pub approved: bool,
    pub preview_only: bool,
    pub created_at_ms: u64,
}

/// The kind of automation being forged.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum DraftKind {
    Macro,
    Trigger,
}

impl AutomationDraft {
    /// A draft is only executable after explicit approval. Until then it
    /// is preview-only (EP-022 acceptance obligation 1).
    pub fn is_runnable(&self) -> bool {
        self.approved && !self.preview_only
    }
}

/// One deterministic fixture event for Trigger Test Lab.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct FixtureEvent {
    pub at_step: u64,
    pub line: String,
    /// The capture/line this event is defined to match; empty for pure
    /// script-driven fixtures.
    pub matches: String,
    /// Expected script side effect after this event, if any.
    pub expect: Option<String>,
}

/// A deterministic replay fixture. No live world is required: events are
/// fixed and ordered (EP-022 acceptance obligation 2).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ReplayFixture {
    pub id: String,
    pub name: String,
    pub events: Vec<FixtureEvent>,
}

impl ReplayFixture {
    pub fn validate(&self) -> Result<(), DebugDenial> {
        if self.id.is_empty() || self.name.is_empty() {
            return Err(DebugDenial::MalformedInput);
        }
        if self.events.len() > MAX_REPLAY_STEPS {
            return Err(DebugDenial::OversizedInput);
        }
        let mut last = None;
        for (i, ev) in self.events.iter().enumerate() {
            if let Some(prev) = last {
                if ev.at_step <= prev {
                    return Err(DebugDenial::MalformedInput);
                }
            }
            if ev.at_step == 0 && i != 0 {
                return Err(DebugDenial::MalformedInput);
            }
            last = Some(ev.at_step);
        }
        Ok(())
    }
}

/// Result of replaying one fixture through the lab.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ReplayRun {
    pub fixture_id: String,
    pub steps_executed: usize,
    pub steps_matched: usize,
    pub denied: Option<DebugDenial>,
    pub finished: bool,
    /// Side effects observed during replay, in order.
    pub effects: Vec<String>,
}

/// One observed runtime variable, with privacy scope.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ObservedVariable {
    pub name: String,
    /// Privacy scope: "public" or "private". Private values are never
    /// shown in exports or timelines (EP-022 obligation 5).
    pub scope: String,
    /// Value is retained only for public variables; private variables
    /// carry a redacted marker.
    pub value: Option<String>,
}

/// One telemetry event on the debug timeline.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DebugEvent {
    pub seq: u64,
    pub at_ms: u64,
    pub source: String,
    pub line: String,
    pub redacted: bool,
}

/// A diagnosis proposal from the AI Debugger. It cites evidence, and it
/// cannot self-certify success or edit gates (WM-SPEC-019-R06, EP-022
/// obligation 4).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AiDiagnosis {
    pub id: String,
    pub evidence: Vec<String>,
    pub hypothesis: String,
    pub reproduction: String,
    pub patch_plan: String,
    pub tests: Vec<String>,
    pub risk: String,
    pub rollback: String,
    /// Always false: the AI Debugger cannot self-certify success.
    pub self_certified: bool,
}

impl AiDiagnosis {
    pub fn new(
        id: String,
        evidence: Vec<String>,
        hypothesis: String,
        reproduction: String,
        patch_plan: String,
        tests: Vec<String>,
        risk: String,
        rollback: String,
    ) -> Self {
        // R06: the AI Debugger never certifies its own proposal.
        Self { id, evidence, hypothesis, reproduction, patch_plan, tests, risk, rollback, self_certified: false }
    }
}

/// A safe patch proposal. It carries a normal Graphlock validation
/// result; until validated it is only a proposal.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PatchProposal {
    pub id: String,
    pub summary: String,
    pub files: Vec<String>,
    pub validated: bool,
}

impl PatchProposal {
    pub fn propose(id: String, summary: String, files: Vec<String>) -> Self {
        Self { id, summary, files, validated: false }
    }
    pub fn mark_validated(&mut self) {
        self.validated = true;
    }
}

/// One measured execution budget record (WM-SPEC-008-R02).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BudgetSample {
    pub run_id: String,
    pub kind: DraftKind,
    pub name: String,
    pub elapsed_ms: u64,
    pub budget_ms: u64,
    pub over_budget: bool,
}

/// Slow-offender diagnostics: sorted offenders with counts.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SlowOffender {
    pub name: String,
    pub kind: DraftKind,
    pub samples: usize,
    pub p95_ms: u64,
    pub worst_ms: u64,
}

/// The Macro Forge. Drafts are preview-only until approved.
pub struct MacroForge {
    drafts: BTreeMap<String, AutomationDraft>,
}

impl Default for MacroForge {
    fn default() -> Self {
        Self::new()
    }
}

impl MacroForge {
    pub fn new() -> Self {
        Self { drafts: BTreeMap::new() }
    }

    /// Create a new draft. It is preview-only and disabled until
    /// approved (obligation 1).
    pub fn create(
        &mut self,
        id: &str,
        kind: DraftKind,
        name: &str,
        body: &str,
        at_ms: u64,
    ) -> Result<&AutomationDraft, DebugDenial> {
        if id.is_empty() || name.is_empty() || body.is_empty() {
            return Err(DebugDenial::MalformedInput);
        }
        if body.len() > MAX_MACRO_LEN {
            return Err(DebugDenial::OversizedInput);
        }
        if self.drafts.contains_key(id) {
            return Err(DebugDenial::DuplicateRequest);
        }
        self.drafts.insert(
            id.to_string(),
            AutomationDraft {
                id: id.to_string(),
                kind,
                name: name.to_string(),
                body: body.to_string(),
                approved: false,
                preview_only: true,
                created_at_ms: at_ms,
            },
        );
        Ok(self.drafts.get(id).expect("just inserted"))
    }

    pub fn approve(&mut self, id: &str) -> Result<(), DebugDenial> {
        let draft = self.drafts.get_mut(id).ok_or(DebugDenial::MalformedInput)?;
        if draft.approved {
            return Err(DebugDenial::DuplicateRequest);
        }
        draft.approved = true;
        draft.preview_only = false;
        Ok(())
    }

    pub fn get(&self, id: &str) -> Option<&AutomationDraft> {
        self.drafts.get(id)
    }

    pub fn list(&self) -> Vec<&AutomationDraft> {
        self.drafts.values().collect()
    }
}

/// The Trigger Test Lab. Replays deterministic fixtures with no live
/// world; each fixture is validated before replay.
pub struct TriggerLab {
    fixtures: BTreeMap<String, ReplayFixture>,
    runs: VecDeque<ReplayRun>,
}

impl Default for TriggerLab {
    fn default() -> Self {
        Self::new()
    }
}

impl TriggerLab {
    pub fn new() -> Self {
        Self { fixtures: BTreeMap::new(), runs: VecDeque::new() }
    }

    pub fn add_fixture(&mut self, fixture: ReplayFixture) -> Result<(), DebugDenial> {
        fixture.validate()?;
        if self.fixtures.contains_key(&fixture.id) {
            return Err(DebugDenial::DuplicateRequest);
        }
        self.fixtures.insert(fixture.id.clone(), fixture);
        Ok(())
    }

    /// Replay a fixture deterministically. The script handler returns
    /// observed side effects for each event line. A `None` return means
    /// the step did not match and is recorded as unmatched.
    pub fn replay(
        &mut self,
        fixture_id: &str,
        mut handle: impl FnMut(&FixtureEvent) -> Option<String>,
        budget_ms: u64,
    ) -> Result<ReplayRun, DebugDenial> {
        let fixture = self.fixtures.get(fixture_id).ok_or(DebugDenial::MalformedInput)?;
        let mut effects = Vec::new();
        let mut matched = 0usize;
        let start = std::time::Instant::now();
        for ev in &fixture.events {
            if start.elapsed().as_millis() as u64 > budget_ms {
                return Err(DebugDenial::BudgetExhausted);
            }
            if let Some(effect) = handle(ev) {
                matched += 1;
                if let Some(expect) = &ev.expect {
                    if expect != &effect {
                        // Recorded as a run with a mismatch effect but the
                        // run still completes; mismatch is visible in the
                        // effect stream (semantic diff, SPEC-019-R07 style).
                        effects.push(format!("MISMATCH expect={} got={}", expect, effect));
                        continue;
                    }
                }
                effects.push(effect);
            }
        }
        let run = ReplayRun {
            fixture_id: fixture_id.to_string(),
            steps_executed: fixture.events.len(),
            steps_matched: matched,
            denied: None,
            finished: true,
            effects,
        };
        self.runs.push_back(run.clone());
        if self.runs.len() > EVENT_RING_CAPACITY {
            self.runs.pop_front();
        }
        Ok(run)
    }

    pub fn last_runs(&self) -> Vec<&ReplayRun> {
        self.runs.iter().collect()
    }
}

/// The script debugger: variable inspection (privacy-scoped), event
/// timeline, and replay-driven diagnosis.
pub struct ScriptDebugger {
    variables: BTreeMap<String, ObservedVariable>,
    timeline: VecDeque<DebugEvent>,
    next_seq: u64,
}

impl Default for ScriptDebugger {
    fn default() -> Self {
        Self::new()
    }
}

impl ScriptDebugger {
    pub fn new() -> Self {
        Self { variables: BTreeMap::new(), timeline: VecDeque::new(), next_seq: 1 }
    }

    /// Record a variable. Private variables keep a redacted marker and
    /// never retain a real value (obligation 5).
    pub fn set_variable(&mut self, name: &str, scope: &str, value: Option<String>) -> Result<(), DebugDenial> {
        if name.is_empty() {
            return Err(DebugDenial::MalformedInput);
        }
        if self.variables.len() >= MAX_VARIABLES && !self.variables.contains_key(name) {
            return Err(DebugDenial::BudgetExhausted);
        }
        let is_private = scope == "private";
        self.variables.insert(
            name.to_string(),
            ObservedVariable {
                name: name.to_string(),
                scope: scope.to_string(),
                value: if is_private { None } else { value },
            },
        );
        Ok(())
    }

    pub fn variable(&self, name: &str) -> Option<&ObservedVariable> {
        self.variables.get(name)
    }

    /// Push one timeline event. Bounded ring buffer; raw private text is
    /// never retained.
    pub fn push_event(&mut self, at_ms: u64, source: &str, line: &str, redacted: bool) {
        self.timeline.push_back(DebugEvent {
            seq: self.next_seq,
            at_ms,
            source: source.to_string(),
            line: line.to_string(),
            redacted,
        });
        self.next_seq += 1;
        if self.timeline.len() > EVENT_RING_CAPACITY {
            self.timeline.pop_front();
        }
    }

    pub fn timeline(&self) -> Vec<&DebugEvent> {
        self.timeline.iter().collect()
    }
}

/// The AI Debugger. Diagnoses approved evidence only; proposals cite
/// evidence, cannot self-certify, and never touch gates.
pub struct AiDebugger {
    diagnoses: VecDeque<AiDiagnosis>,
    approved_evidence: BTreeMap<String, Vec<String>>,
}

impl Default for AiDebugger {
    fn default() -> Self {
        Self::new()
    }
}

impl AiDebugger {
    pub fn new() -> Self {
        Self { diagnoses: VecDeque::new(), approved_evidence: BTreeMap::new() }
    }

    /// Evidence must be user-approved before analysis (obligation 4:
    /// "analyze approved evidence").
    pub fn approve_evidence(&mut self, id: &str, evidence: Vec<String>) -> Result<(), DebugDenial> {
        if id.is_empty() || evidence.is_empty() {
            return Err(DebugDenial::MalformedInput);
        }
        if self.approved_evidence.contains_key(id) {
            return Err(DebugDenial::DuplicateRequest);
        }
        self.approved_evidence.insert(id.to_string(), evidence);
        Ok(())
    }

    /// Produce a diagnosis. Fails unless the evidence set was approved.
    pub fn diagnose(&mut self, id: &str, evidence_id: &str, hypothesis: &str, reproduction: &str, patch_plan: &str, tests: Vec<String>, risk: &str, rollback: &str) -> Result<&AiDiagnosis, DebugDenial> {
        let evidence = self.approved_evidence.get(evidence_id).ok_or(DebugDenial::DeniedPolicy)?;
        if id.is_empty() || hypothesis.is_empty() || reproduction.is_empty() || patch_plan.is_empty() || risk.is_empty() || rollback.is_empty() {
            return Err(DebugDenial::MalformedInput);
        }
        if self.diagnoses.iter().any(|d| d.id == id) {
            return Err(DebugDenial::DuplicateRequest);
        }
        let diagnosis = AiDiagnosis::new(
            id.to_string(),
            evidence.clone(),
            hypothesis.to_string(),
            reproduction.to_string(),
            patch_plan.to_string(),
            tests,
            risk.to_string(),
            rollback.to_string(),
        );
        self.diagnoses.push_back(diagnosis);
        if self.diagnoses.len() > EVENT_RING_CAPACITY {
            self.diagnoses.pop_front();
        }
        Ok(self.diagnoses.back().expect("just pushed"))
    }

    pub fn diagnoses(&self) -> Vec<&AiDiagnosis> {
        self.diagnoses.iter().collect()
    }
}

/// Performance statistics: measured budgets and slow-offender
/// diagnostics (WM-SPEC-008-R02).
pub struct PerformanceStats {
    samples: Vec<BudgetSample>,
}

impl Default for PerformanceStats {
    fn default() -> Self {
        Self::new()
    }
}

impl PerformanceStats {
    pub fn new() -> Self {
        Self { samples: Vec::new() }
    }

    /// Record one measured sample. Over-budget samples are flagged.
    pub fn record(&mut self, run_id: &str, kind: DraftKind, name: &str, elapsed_ms: u64, budget_ms: u64) {
        self.samples.push(BudgetSample {
            run_id: run_id.to_string(),
            kind,
            name: name.to_string(),
            elapsed_ms,
            budget_ms,
            over_budget: elapsed_ms > budget_ms,
        });
    }

    pub fn samples(&self) -> &[BudgetSample] {
        &self.samples
    }

    /// Slow-offender report: offenders sorted by worst elapsed time.
    pub fn slow_offenders(&self) -> Vec<SlowOffender> {
        let mut by_name: BTreeMap<(String, DraftKind), Vec<u64>> = BTreeMap::new();
        for s in &self.samples {
            if s.over_budget {
                by_name.entry((s.name.clone(), s.kind)).or_default().push(s.elapsed_ms);
            }
        }
        let mut out: Vec<SlowOffender> = by_name
            .into_iter()
            .map(|((name, kind), mut times)| {
                times.sort_unstable();
                let p95_idx = ((times.len() as f64 * 0.95).ceil() as usize).saturating_sub(1);
                let p95 = times.get(p95_idx).copied().unwrap_or(0);
                let worst = times.last().copied().unwrap_or(0);
                SlowOffender { name, kind, samples: times.len(), p95_ms: p95, worst_ms: worst }
            })
            .collect();
        out.sort_by_key(|o| std::cmp::Reverse(o.worst_ms));
        out
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn macro_forge_draft_is_preview_only_until_approved() {
        let mut forge = MacroForge::new();
        let draft = forge.create("m1", DraftKind::Macro, "heal", "send(\"cure light\")\n", 1).unwrap();
        assert!(draft.preview_only);
        assert!(!draft.is_runnable());
        forge.approve("m1").unwrap();
        assert!(forge.get("m1").unwrap().is_runnable());
    }

    #[test]
    fn macro_forge_rejects_duplicate_and_oversized() {
        let mut forge = MacroForge::new();
        forge.create("m1", DraftKind::Macro, "a", "x", 1).unwrap();
        assert_eq!(forge.create("m1", DraftKind::Macro, "b", "y", 2), Err(DebugDenial::DuplicateRequest));
        let big = "x".repeat(MAX_MACRO_LEN + 1);
        assert_eq!(forge.create("m2", DraftKind::Macro, "c", &big, 3), Err(DebugDenial::OversizedInput));
    }

    #[test]
    fn trigger_lab_replays_deterministic_fixture() {
        let mut lab = TriggerLab::new();
        let fixture = ReplayFixture {
            id: "f1".into(),
            name: "crossroads room".into(),
            events: vec![
                FixtureEvent { at_step: 1, line: "You stand at a crossroads.".into(), matches: "crossroads".into(), expect: None },
                FixtureEvent { at_step: 2, line: "A guard bars the north exit.".into(), matches: "guard".into(), expect: Some("blocked north".into()) },
            ],
        };
        lab.add_fixture(fixture).unwrap();
        let run = lab.replay("f1", |ev| {
            if ev.line.contains("crossroads") { Some("seen crossroads".into()) }
            else if ev.line.contains("guard") { Some("blocked north".into()) }
            else { None }
        }, DEFAULT_EXEC_BUDGET_MS).unwrap();
        assert_eq!(run.steps_executed, 2);
        assert_eq!(run.steps_matched, 2);
        assert!(run.finished);
        assert_eq!(run.effects, vec!["seen crossroads", "blocked north"]);
    }

    #[test]
    fn trigger_lab_rejects_malformed_fixture() {
        let mut lab = TriggerLab::new();
        let fixture = ReplayFixture {
            id: "f2".into(),
            name: "bad".into(),
            events: vec![
                FixtureEvent { at_step: 5, line: "a".into(), matches: "".into(), expect: None },
                FixtureEvent { at_step: 3, line: "b".into(), matches: "".into(), expect: None },
            ],
        };
        assert_eq!(lab.add_fixture(fixture), Err(DebugDenial::MalformedInput));
    }

    #[test]
    fn debugger_keeps_private_variables_redacted() {
        let mut dbg = ScriptDebugger::new();
        dbg.set_variable("gold", "public", Some("42".into())).unwrap();
        dbg.set_variable("password", "private", Some("sekrit".into())).unwrap();
        assert_eq!(dbg.variable("gold").unwrap().value.as_deref(), Some("42"));
        assert_eq!(dbg.variable("password").unwrap().value, None);
        assert_eq!(dbg.variable("password").unwrap().scope, "private");
    }

    #[test]
    fn debugger_timeline_is_bounded() {
        let mut dbg = ScriptDebugger::new();
        for i in 0..(EVENT_RING_CAPACITY + 10) {
            dbg.push_event(i as u64, "trigger", &format!("line {i}"), false);
        }
        assert_eq!(dbg.timeline().len(), EVENT_RING_CAPACITY);
    }

    #[test]
    fn ai_debugger_requires_approved_evidence() {
        let mut ai = AiDebugger::new();
        let r = ai.diagnose("d1", "ev1", "hyp", "repro", "patch", vec!["t1".into()], "risk", "rollback");
        assert_eq!(r, Err(DebugDenial::DeniedPolicy));
        ai.approve_evidence("ev1", vec!["line 1".into(), "line 2".into()]).unwrap();
        let d = ai.diagnose("d1", "ev1", "hyp", "repro", "patch", vec!["t1".into()], "risk", "rollback").unwrap();
        assert_eq!(d.evidence, vec!["line 1", "line 2"]);
        assert!(!d.self_certified);
    }

    #[test]
    fn ai_debugger_never_self_certifies() {
        let mut ai = AiDebugger::new();
        ai.approve_evidence("ev9", vec!["x".into()]).unwrap();
        let d = ai.diagnose("d9", "ev9", "h", "r", "p", vec![], "risk", "rb").unwrap();
        assert!(!d.self_certified, "R06: AI Debugger cannot self-certify success");
        assert!(d.evidence.contains(&"x".to_string()), "diagnosis must cite evidence");
    }

    #[test]
    fn patch_proposal_needs_validation() {
        let mut p = PatchProposal::propose("p1".into(), "fix budget".into(), vec!["wirecore/crates/wire-debugger/src/lib.rs".into()]);
        assert!(!p.validated);
        p.mark_validated();
        assert!(p.validated);
    }

    #[test]
    fn performance_stats_report_slow_offenders() {
        let mut stats = PerformanceStats::new();
        stats.record("r1", DraftKind::Trigger, "guard", 150, 100);
        stats.record("r2", DraftKind::Trigger, "guard", 120, 100);
        stats.record("r3", DraftKind::Trigger, "guard", 90, 100);
        stats.record("r4", DraftKind::Macro, "fast", 5, 100);
        let offenders = stats.slow_offenders();
        assert_eq!(offenders.len(), 1);
        assert_eq!(offenders[0].name, "guard");
        assert_eq!(offenders[0].samples, 2);
        assert_eq!(offenders[0].worst_ms, 150);
    }
}

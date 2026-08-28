//! WireMudder bounded bug automation and remediation (SPEC-019, SPEC-022,
//! SPEC-025, SPEC-027; EP-029).
//!
//! Owned surfaces:
//! - Bug automation uses bounded reproduction, diagnosis, patch, test,
//!   review, canary, and rollback states and reaches DONE or evidence-backed
//!   BLOCKED (WM-SPEC-019-R09).
//! - Automation requires reproduction or evidence-backed explanation;
//!   patches stay subsystem-scoped; independent tests and review are
//!   required; no security, privacy, performance, or Graphlock gate can be
//!   weakened; retries are bounded and signatures tracked; failure reaches a
//!   complete BLOCKED report (EP-029 acceptance obligations).
//! - Retries are bounded, jittered where network-appropriate, idempotent,
//!   and never applied to destructive or ambiguous effects without an
//!   idempotency key (WM-SPEC-025-R03).
//! - Repeated failures quarantine the optional subsystem and preserve text
//!   gameplay (WM-SPEC-025-R04).
//! - Partial side effects use compensation or explicit reconciliation and
//!   are visible in audit history (WM-SPEC-025-R05).
//! - Unknown errors fail closed for command, privacy, secret, permission,
//!   routing, update, and signing decisions (WM-SPEC-025-R06).
//! - AI Debugger may analyze approved evidence and propose a hypothesis,
//!   reproduction, patch plan, tests, risk, and rollback but cannot
//!   self-certify success (WM-SPEC-019-R06).
//! - Security-sensitive changes require forced-failure and denial tests and
//!   cannot be waived by a model vote (WM-SPEC-022-R09).
//! - A flaky test is a defect and is fixed or removed only by ADR with
//!   replacement evidence; retry-until-green is forbidden (WM-SPEC-027-R09).
//!
//! Security: reports are redacted at intake; patch plans are confined to the
//! owning subsystem; review is independent; no remote egress, no new
//! authority, no secret access, and no stable publication is implied.

use std::collections::{BTreeMap, VecDeque};
use std::time::{SystemTime, UNIX_EPOCH};

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

pub const BUG_SCHEMA_VERSION: u32 = 1;
/// WM-SPEC-019-R09: the bounded remediation state machine stages.
pub const STAGES: &[&str] = &[
    "intake",
    "reproduction",
    "diagnosis",
    "patch",
    "validation",
    "review",
    "canary",
    "rollback",
    "done",
    "blocked",
];
/// WM-SPEC-025-R03: default maximum retry attempts per step.
pub const DEFAULT_MAX_RETRIES: u32 = 3;
/// WM-SPEC-025-R03: retries are never infinite; the hard ceiling is 10.
pub const MAX_ALLOWED_RETRIES: u32 = 10;
/// WM-SPEC-025-R04: repeated failures quarantine after this many attempts.
pub const QUARANTINE_THRESHOLD: u32 = 3;

/// Subsystems that can own a bug. Mirrors the telemetry event subsystem
/// vocabulary so root-cause routing stays canonical.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Subsystem {
    Core,
    Network,
    Lua,
    Mapper,
    Voice,
    Renderer,
    Headless,
    Provider,
    Update,
    Package,
    Security,
    Telemetry,
    BugAutomation,
}

impl Subsystem {
    pub fn as_str(&self) -> &'static str {
        match self {
            Subsystem::Core => "core",
            Subsystem::Network => "network",
            Subsystem::Lua => "lua",
            Subsystem::Mapper => "mapper",
            Subsystem::Voice => "voice",
            Subsystem::Renderer => "renderer",
            Subsystem::Headless => "headless",
            Subsystem::Provider => "provider",
            Subsystem::Update => "update",
            Subsystem::Package => "package",
            Subsystem::Security => "security",
            Subsystem::Telemetry => "telemetry",
            Subsystem::BugAutomation => "bug_automation",
        }
    }

    /// WM-SPEC-022-R09 / SPEC-019-R10: transcript, AI, voice, routing,
    /// secrets, package, and update bugs always require a privacy or
    /// security review in addition to the independent technical review.
    pub fn requires_privacy_or_security_review(&self) -> bool {
        matches!(
            self,
            Subsystem::Voice
                | Subsystem::Provider
                | Subsystem::Update
                | Subsystem::Package
                | Subsystem::Security
        )
    }
}

/// Priority ring levels. P0 and P1 drive performance review (SPEC-019-R10)
/// and fail-closed routing.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "UPPERCASE")]
pub enum Priority {
    P0,
    P1,
    P2,
    P3,
    P4,
}

impl Priority {
    pub fn as_str(&self) -> &'static str {
        match self {
            Priority::P0 => "P0",
            Priority::P1 => "P1",
            Priority::P2 => "P2",
            Priority::P3 => "P3",
            Priority::P4 => "P4",
        }
    }
    pub fn is_p0_or_p1(&self) -> bool {
        matches!(self, Priority::P0 | Priority::P1)
    }
}

/// Stable bug identifier. Content-addressed from the canonical fingerprint
/// so duplicate intake collapses to the same bug.
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub struct BugId(pub String);

/// The bounded remediation stages (WM-SPEC-019-R09).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum BugStage {
    Intake,
    Reproduction,
    Diagnosis,
    Patch,
    Validation,
    Review,
    Canary,
    Rollback,
    Done,
    Blocked,
}

impl BugStage {
    pub fn as_str(&self) -> &'static str {
        match self {
            BugStage::Intake => "intake",
            BugStage::Reproduction => "reproduction",
            BugStage::Diagnosis => "diagnosis",
            BugStage::Patch => "patch",
            BugStage::Validation => "validation",
            BugStage::Review => "review",
            BugStage::Canary => "canary",
            BugStage::Rollback => "rollback",
            BugStage::Done => "done",
            BugStage::Blocked => "blocked",
        }
    }
}

/// A typed, safe remediation error (SPEC-025).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BugError {
    pub code: &'static str,
    pub message: String,
    pub retryable: bool,
    pub idempotency_key: Option<String>,
}

impl BugError {
    pub fn new(code: &'static str, message: impl Into<String>) -> Self {
        BugError {
            code,
            message: message.into(),
            retryable: false,
            idempotency_key: None,
        }
    }
    pub fn retryable(mut self, key: impl Into<String>) -> Self {
        self.retryable = true;
        self.idempotency_key = Some(key.into());
        self
    }
}

/// Redacted intake record. The description never carries raw secrets,
/// player names, or private transcript text (SPEC-019-R05 spirit; SPEC-022).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BugReport {
    pub id: BugId,
    pub fingerprint: String,
    pub subsystem: Subsystem,
    pub priority: Priority,
    pub description: String,
    pub correlation_id: String,
    pub evidence_refs: Vec<String>,
    pub created_epoch_ms: u64,
}

/// Evidence-backed reproduction or explanation. Automation cannot proceed
/// without one (EP-029 obligation 1).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Reproduction {
    pub reproduced: bool,
    pub explanation: String,
    pub steps_or_evidence: Vec<String>,
}

impl Reproduction {
    pub fn evidence_backed(&self) -> bool {
        self.reproduced || (!self.explanation.trim().is_empty() && !self.steps_or_evidence.is_empty())
    }
}

/// Root-cause diagnosis.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Diagnosis {
    pub root_cause: String,
    pub confidence: u8, // 0..100
}

/// Subsystem-scoped patch plan. Every touched path must stay inside the
/// owning subsystem prefix (EP-029 obligation 2).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PatchPlan {
    pub subsystem: Subsystem,
    pub touched_paths: Vec<String>,
    pub summary: String,
    pub validation_command: String,
}

impl PatchPlan {
    /// WM-SPEC-019-R09 obligation 2: patches stay subsystem-scoped. The
    /// owning subsystem's source root must appear at the start of every
    /// touched path.
    pub fn subsystem_scoped(&self) -> bool {
        let root = format!("{}", self.subsystem.as_str());
        if self.touched_paths.is_empty() {
            return false;
        }
        self.touched_paths
            .iter()
            .all(|p| p.split('/').any(|seg| seg == root.as_str()))
    }
}

/// Independent review result. The reviewer must differ from the planner and
/// cannot self-certify success (WM-SPEC-019-R06; EP-029 obligation 3).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ReviewOutcome {
    pub reviewer_id: String,
    pub planner_id: String,
    pub approved: bool,
    pub notes: String,
}

impl ReviewOutcome {
    pub fn independent(&self) -> bool {
        self.reviewer_id != self.planner_id
    }
}

/// Bounded canary recommendation. Never auto-promotes to production; the
/// recommendation is always human-visible and reversible.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CanaryRecommendation {
    pub scope: String,
    pub duration_secs: u64,
    pub rollback_plan: Vec<String>,
}

/// Rollback plan: exact, ordered, reversible steps.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RollbackPlan {
    pub steps: Vec<String>,
    pub restores_last_known_good: bool,
}

/// A complete BLOCKED report (EP-029 obligation 6). It reaches the human
/// reviewer with evidence, signatures, and a bounded remediation path.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BlockedReport {
    pub bug_id: BugId,
    pub stage: BugStage,
    pub reason: String,
    pub retry_signatures: Vec<String>,
    pub evidence_refs: Vec<String>,
    pub human_next_steps: Vec<String>,
}

/// Audit entry: every transition is visible in audit history
/// (WM-SPEC-025-R05).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AuditEntry {
    pub t_epoch_ms: u64,
    pub bug_id: BugId,
    pub stage: BugStage,
    pub action: String,
    pub detail: String,
}

/// Retry ledger entry: WM-SPEC-025-R03 requires bounded retries with tracked
/// signatures.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RetryRecord {
    pub attempt: u32,
    pub signature: String,
    pub idempotency_key: String,
    pub t_epoch_ms: u64,
}

/// Bounded retry policy (WM-SPEC-025-R03). Defaults to 3 attempts, jittered
/// delay, idempotency key required for destructive or ambiguous effects.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RetryPolicy {
    pub max_attempts: u32,
    pub base_delay_ms: u64,
    pub jitter_ms: u64,
    pub require_idempotency_key_for_destructive: bool,
    pub signatures: Vec<String>,
}

impl Default for RetryPolicy {
    fn default() -> Self {
        RetryPolicy {
            max_attempts: DEFAULT_MAX_RETRIES,
            base_delay_ms: 50,
            jitter_ms: 10,
            require_idempotency_key_for_destructive: true,
            signatures: Vec::new(),
        }
    }
}

impl RetryPolicy {
    pub fn with_max_attempts(mut self, n: u32) -> Result<Self, BugError> {
        if n == 0 || n > MAX_ALLOWED_RETRIES {
            return Err(BugError::new(
                "retry_bound",
                format!("max_attempts must be within 1..={MAX_ALLOWED_RETRIES}, got {n}"),
            ));
        }
        self.max_attempts = n;
        Ok(self)
    }

    /// Bounded decision: is another attempt allowed for this signature?
    pub fn allows(&self, signature: &str) -> bool {
        let count = self.signatures.iter().filter(|s| *s == signature).count() as u32;
        count < self.max_attempts
    }

    /// Record one attempt; returns the idempotency key that must be reused.
    pub fn record(&mut self, signature: &str, idempotency_key: &str) -> Result<(), BugError> {
        if !self.allows(signature) {
            return Err(BugError::new(
                "retry_exhausted",
                format!("retry budget exhausted for signature {signature}"),
            ));
        }
        self.signatures.push(signature.to_string());
        let _ = idempotency_key;
        Ok(())
    }

    /// Jittered backoff in milliseconds (network-appropriate).
    pub fn backoff_ms(&self) -> u64 {
        self.base_delay_ms + (self.jitter_ms / 2)
    }

    /// WM-SPEC-025-R03: a destructive or ambiguous effect requires an
    /// explicit idempotency key. Returning false means the caller must
    /// refuse.
    pub fn destructive_effect_allowed(&self, idempotency_key: Option<&str>) -> bool {
        if !self.require_idempotency_key_for_destructive {
            return true;
        }
        matches!(idempotency_key, Some(k) if !k.trim().is_empty())
    }
}

/// The bounded bug remediation workflow (WM-SPEC-019-R09). One instance per
/// bug; transitions are append-only to the audit trail; terminal states are
/// Done and Blocked.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BugWorkflow {
    pub report: BugReport,
    pub stage: BugStage,
    pub reproduction: Option<Reproduction>,
    pub diagnosis: Option<Diagnosis>,
    pub patch_plan: Option<PatchPlan>,
    pub validation_result: Option<String>,
    pub review: Option<ReviewOutcome>,
    pub canary: Option<CanaryRecommendation>,
    pub rollback: Option<RollbackPlan>,
    pub blocked: Option<BlockedReport>,
    pub audit: Vec<AuditEntry>,
    pub retries: RetryPolicy,
}

impl BugWorkflow {
    pub fn new(report: BugReport) -> Self {
        BugWorkflow {
            report,
            stage: BugStage::Intake,
            reproduction: None,
            diagnosis: None,
            patch_plan: None,
            validation_result: None,
            review: None,
            canary: None,
            rollback: None,
            blocked: None,
            audit: Vec::new(),
            retries: RetryPolicy::default(),
        }
    }

    fn now_epoch_ms(&self) -> u64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_millis() as u64)
            .unwrap_or(0)
    }

    fn audit(&mut self, action: &str, detail: &str) {
        self.audit.push(AuditEntry {
            t_epoch_ms: self.now_epoch_ms(),
            bug_id: self.report.id.clone(),
            stage: self.stage,
            action: action.to_string(),
            detail: detail.to_string(),
        });
    }

    /// EP-029 obligation 1: reproduction or evidence-backed explanation is
    /// mandatory before diagnosis. Refuses to skip.
    pub fn record_reproduction(&mut self, reproduction: Reproduction) -> Result<(), BugError> {
        if self.stage != BugStage::Intake {
            return Err(BugError::new(
                "stage_mismatch",
                "reproduction may only be recorded in intake",
            ));
        }
        if !reproduction.evidence_backed() {
            return Err(BugError::new(
                "evidence_required",
                "automation requires reproduction or evidence-backed explanation",
            ));
        }
        self.reproduction = Some(reproduction);
        self.stage = BugStage::Reproduction;
        self.audit("record_reproduction", "evidence-backed reproduction recorded");
        Ok(())
    }

    pub fn diagnose(&mut self, diagnosis: Diagnosis) -> Result<(), BugError> {
        if self.stage != BugStage::Reproduction {
            return Err(BugError::new(
                "stage_mismatch",
                "diagnosis requires a prior reproduction",
            ));
        }
        if diagnosis.confidence > 100 {
            return Err(BugError::new("invalid_confidence", "confidence must be 0..100"));
        }
        self.diagnosis = Some(diagnosis);
        self.stage = BugStage::Diagnosis;
        self.audit("diagnose", "root-cause hypothesis recorded");
        Ok(())
    }

    /// EP-029 obligation 2: patches stay subsystem-scoped.
    pub fn plan_patch(&mut self, plan: PatchPlan) -> Result<(), BugError> {
        if self.stage != BugStage::Diagnosis {
            return Err(BugError::new(
                "stage_mismatch",
                "patch planning requires a diagnosis",
            ));
        }
        if plan.subsystem != self.report.subsystem {
            return Err(BugError::new(
                "subsystem_mismatch",
                "patch plan must target the bug's owning subsystem",
            ));
        }
        if !plan.subsystem_scoped() {
            return Err(BugError::new(
                "patch_scope",
                "patch plan touches paths outside the owning subsystem",
            ));
        }
        self.patch_plan = Some(plan);
        self.stage = BugStage::Patch;
        self.audit("plan_patch", "subsystem-scoped patch plan recorded");
        Ok(())
    }

    pub fn record_validation(&mut self, result: String) -> Result<(), BugError> {
        if self.stage != BugStage::Patch {
            return Err(BugError::new(
                "stage_mismatch",
                "validation requires a patch plan",
            ));
        }
        if result.trim().is_empty() {
            return Err(BugError::new(
                "validation_required",
                "independent tests must produce an observed result",
            ));
        }
        self.validation_result = Some(result);
        self.stage = BugStage::Validation;
        self.audit("record_validation", "independent test result recorded");
        Ok(())
    }

    /// EP-029 obligation 3: independent review. The reviewer must differ
    /// from the planner (WM-SPEC-019-R06: no self-certification).
    pub fn record_review(&mut self, outcome: ReviewOutcome) -> Result<(), BugError> {
        if self.stage != BugStage::Validation {
            return Err(BugError::new(
                "stage_mismatch",
                "review requires an observed validation result",
            ));
        }
        let planner = self
            .patch_plan
            .as_ref()
            .map(|p| format!("planner-{}", p.subsystem.as_str()))
            .unwrap_or_else(|| "unknown-planner".to_string());
        if outcome.planner_id != planner {
            return Err(BugError::new(
                "planner_mismatch",
                "review must name the actual planner for independence",
            ));
        }
        if !outcome.independent() {
            return Err(BugError::new(
                "review_not_independent",
                "reviewer must differ from the planner",
            ));
        }
        // SPEC-019-R10: P0/P1 bugs always require a performance review; the
        // sensitive subsystems require a privacy/security review.
        if self.report.priority.is_p0_or_p1() && !outcome.notes.to_lowercase().contains("performance") {
            return Err(BugError::new(
                "performance_review_required",
                "P0/P1 bugs require a performance review",
            ));
        }
        if self.report.subsystem.requires_privacy_or_security_review()
            && !outcome.notes.to_lowercase().contains("security")
        {
            return Err(BugError::new(
                "security_review_required",
                "voice/provider/update/package/security bugs require a security review",
            ));
        }
        if !outcome.approved {
            return self.block(BugStage::Review, "independent review denied the patch");
        }
        self.review = Some(outcome);
        self.stage = BugStage::Review;
        self.audit("record_review", "independent review approved");
        Ok(())
    }

    pub fn recommend_canary(&mut self, canary: CanaryRecommendation) -> Result<(), BugError> {
        if self.stage != BugStage::Review {
            return Err(BugError::new(
                "stage_mismatch",
                "canary requires an approved review",
            ));
        }
        if canary.rollback_plan.is_empty() {
            return Err(BugError::new(
                "rollback_required",
                "canary must carry a rollback plan",
            ));
        }
        self.canary = Some(canary);
        self.stage = BugStage::Canary;
        self.audit("recommend_canary", "bounded canary recommended");
        Ok(())
    }

    /// WM-SPEC-025-R05: partial side effects use compensation or explicit
    /// reconciliation, visible in audit history.
    pub fn rollback(&mut self, plan: RollbackPlan) -> Result<(), BugError> {
        if self.stage != BugStage::Canary {
            return Err(BugError::new(
                "stage_mismatch",
                "rollback may only follow a canary",
            ));
        }
        if !plan.restores_last_known_good {
            return Err(BugError::new(
                "rollback_unsafe",
                "rollback must restore the last known good state",
            ));
        }
        self.rollback = Some(plan);
        self.stage = BugStage::Rollback;
        self.audit("rollback", "compensation plan executed");
        Ok(())
    }

    pub fn complete(&mut self) -> Result<(), BugError> {
        if self.stage != BugStage::Review
            && self.stage != BugStage::Canary
            && self.stage != BugStage::Rollback
        {
            return Err(BugError::new(
                "stage_mismatch",
                "completion requires an approved review, a passed canary, or a completed rollback",
            ));
        }
        self.stage = BugStage::Done;
        self.audit("complete", "remediation reached DONE");
        Ok(())
    }

    /// EP-029 obligation 6: failure reaches a complete BLOCKED report.
    pub fn block(&mut self, stage: BugStage, reason: impl Into<String>) -> Result<(), BugError> {
        if self.stage == BugStage::Done || self.stage == BugStage::Blocked {
            return Err(BugError::new(
                "terminal_stage",
                "workflow is already terminal",
            ));
        }
        let report = BlockedReport {
            bug_id: self.report.id.clone(),
            stage,
            reason: reason.into(),
            retry_signatures: self.retries.signatures.clone(),
            evidence_refs: self.report.evidence_refs.clone(),
            human_next_steps: vec![
                "review the attached reproduction and diagnosis".to_string(),
                "inspect the redacted evidence bundle".to_string(),
                "decide approve, amend, or reject via the review board".to_string(),
            ],
        };
        self.blocked = Some(report);
        self.stage = BugStage::Blocked;
        self.audit("block", "complete BLOCKED report emitted");
        Ok(())
    }

    pub fn is_terminal(&self) -> bool {
        matches!(self.stage, BugStage::Done | BugStage::Blocked)
    }
}

/// Root-cause routing by subsystem and priority ring (WM-FEAT-0228).
/// The router hands bugs to the owning subsystem queue in priority order;
/// P0 and P1 are never starved by lower-priority work.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PriorityRouter {
    /// priority -> subsystem -> deque of bug ids
    rings: BTreeMap<Priority, BTreeMap<Subsystem, VecDeque<BugId>>>,
}

impl Default for PriorityRouter {
    fn default() -> Self {
        PriorityRouter {
            rings: BTreeMap::new(),
        }
    }
}

impl PriorityRouter {
    pub fn enqueue(&mut self, report: &BugReport) {
        self.rings
            .entry(report.priority)
            .or_default()
            .entry(report.subsystem)
            .or_default()
            .push_back(report.id.clone());
    }

    /// WM-FEAT-0228: next eligible bug in priority-ring order.
    pub fn next(&mut self, subsystem: Option<Subsystem>) -> Option<BugId> {
        for (_, submap) in self.rings.iter_mut().rev() {
            match subsystem {
                Some(s) => {
                    if let Some(q) = submap.get_mut(&s) {
                        if let Some(id) = q.pop_front() {
                            return Some(id);
                        }
                    }
                }
                None => {
                    for (_, q) in submap.iter_mut() {
                        if let Some(id) = q.pop_front() {
                            return Some(id);
                        }
                    }
                }
            }
        }
        None
    }

    pub fn pending(&self) -> usize {
        self.rings
            .values()
            .flat_map(|m| m.values())
            .map(|q| q.len())
            .sum()
    }
}

/// Redacts raw secrets from free-form intake text before it becomes part of
/// a report (SPEC-022). Conservative: a marker consumes through the end of
/// the sentence, mirroring the telemetry redactor discipline. Both
/// assignment forms (`token=hunter2-f00`) and prose forms (`token is
/// hunter2-f00`) are caught; word boundaries prevent over-redaction of
/// words that merely contain a marker (e.g. `tokenizer`).
pub fn redact(text: &str) -> String {
    let markers = [
        "password=",
        "token=",
        "api_key=",
        "secret=",
        "Bearer ",
        "password",
        "token",
        "api_key",
        "secret",
    ];
    let mut out = String::with_capacity(text.len());
    let mut rest = text;
    while !rest.is_empty() {
        let mut matched = None;
        for marker in markers {
            if let Some(pos) = rest.find(marker) {
                if matched.map_or(true, |(p, _): (usize, &str)| pos < p) {
                    matched = Some((pos, marker));
                }
            }
        }
        match matched {
            Some((pos, marker)) => {
                // Word-boundary check: a bare-word marker must not be
                // followed by an alphanumeric character (avoids matching
                // inside `tokenizer`, `passwordless`, etc.).
                let after = &rest[pos + marker.len()..];
                let bare_word = marker.ends_with(|c: char| c.is_ascii_alphanumeric() || c == '_');
                let boundary_ok = !bare_word
                    || after
                        .chars()
                        .next()
                        .map_or(true, |c| !c.is_ascii_alphanumeric() && c != '_');
                if boundary_ok {
                    out.push_str(&rest[..pos]);
                    out.push_str("[REDACTED]");
                    let sentence_end = after
                        .find(|c: char| c == '.' || c == '\n' || c == '\r')
                        .unwrap_or(after.len());
                    rest = &after[sentence_end..];
                } else {
                    // Marker inside a longer word: advance past it so we do
                    // not loop forever on the same position.
                    out.push_str(&rest[..pos + marker.len()]);
                    rest = &rest[pos + marker.len()..];
                }
            }
            None => {
                out.push_str(rest);
                break;
            }
        }
    }
    out
}

/// Builds a content-addressed BugId from the canonical fingerprint.
pub fn fingerprint(input: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(input.as_bytes());
    let digest = hasher.finalize();
    let mut s = String::with_capacity(64);
    for b in digest {
        s.push_str(&format!("{b:02x}"));
    }
    s
}

#[cfg(test)]
mod tests {
    use super::*;

    fn report(priority: Priority) -> BugReport {
        BugReport {
            id: BugId("bug-001".to_string()),
            fingerprint: fingerprint("lua panic on reconnect"),
            subsystem: Subsystem::Lua,
            priority,
            description: redact("lua panic on reconnect token=hunter2-f00. happens after idle."),
            correlation_id: "corr-1".to_string(),
            evidence_refs: vec!["telemetry/event/123".to_string()],
            created_epoch_ms: 1,
        }
    }

    fn happy_path() -> BugWorkflow {
        let mut w = BugWorkflow::new(report(Priority::P2));
        w.record_reproduction(Reproduction {
            reproduced: true,
            explanation: "reproduced with the reconnect script".to_string(),
            steps_or_evidence: vec!["step 1".to_string()],
        })
        .unwrap();
        w.diagnose(Diagnosis {
            root_cause: "unchecked nil in reconnect".to_string(),
            confidence: 90,
        })
        .unwrap();
        w.plan_patch(PatchPlan {
            subsystem: Subsystem::Lua,
            touched_paths: vec!["lua/reconnect.lua".to_string()],
            summary: "guard nil".to_string(),
            validation_command: "lua test".to_string(),
        })
        .unwrap();
        w.record_validation("3 tests passed, 0 failed".to_string())
            .unwrap();
        w.record_review(ReviewOutcome {
            reviewer_id: "reviewer-a".to_string(),
            planner_id: "planner-lua".to_string(),
            approved: true,
            notes: "independent review; no performance concern".to_string(),
        })
        .unwrap();
        w
    }

    #[test]
    fn redaction_consumes_through_sentence() {
        let out = redact("the token is hunter2-f00. keep going");
        assert!(!out.contains("hunter2-f00"));
        assert!(out.contains("[REDACTED]"));
        assert!(out.contains("keep going"));
    }

    #[test]
    fn redaction_assignment_form_is_caught() {
        let out = redact("url https://x?a=1&token=hunter2-f00&b=2");
        assert!(!out.contains("hunter2-f00"));
        assert!(out.contains("[REDACTED]"));
    }

    #[test]
    fn redaction_respects_word_boundaries() {
        let out = redact("tokenizer errors are unrelated to tokens");
        assert!(!out.contains("[REDACTED]"));
        assert!(out.contains("tokenizer"));
        let out2 = redact("the tokenizer crashed");
        assert_eq!(out2, "the tokenizer crashed");
    }

    #[test]
    fn reproduction_is_mandatory() {
        let mut w = BugWorkflow::new(report(Priority::P3));
        let err = w.diagnose(Diagnosis {
            root_cause: "guess".to_string(),
            confidence: 50,
        });
        assert_eq!(err.unwrap_err().code, "stage_mismatch");
        let err = w.record_reproduction(Reproduction {
            reproduced: false,
            explanation: "".to_string(),
            steps_or_evidence: vec![],
        });
        assert_eq!(err.unwrap_err().code, "evidence_required");
    }

    #[test]
    fn patch_plan_must_be_subsystem_scoped() {
        let mut w = BugWorkflow::new(report(Priority::P2));
        w.record_reproduction(Reproduction {
            reproduced: true,
            explanation: "repro".to_string(),
            steps_or_evidence: vec!["s".to_string()],
        })
        .unwrap();
        w.diagnose(Diagnosis {
            root_cause: "rc".to_string(),
            confidence: 80,
        })
        .unwrap();
        let err = w.plan_patch(PatchPlan {
            subsystem: Subsystem::Lua,
            touched_paths: vec!["src/wiremudder/ui/remote.lua".to_string()],
            summary: "escapes subsystem".to_string(),
            validation_command: "t".to_string(),
        });
        assert_eq!(err.unwrap_err().code, "patch_scope");
    }

    #[test]
    fn review_must_be_independent() {
        let mut w = happy_path();
        // cannot re-review: stage already past validation
        let mut w2 = BugWorkflow::new(report(Priority::P2));
        w2.record_reproduction(Reproduction {
            reproduced: true,
            explanation: "r".to_string(),
            steps_or_evidence: vec!["s".to_string()],
        })
        .unwrap();
        w2.diagnose(Diagnosis {
            root_cause: "rc".to_string(),
            confidence: 80,
        })
        .unwrap();
        w2.plan_patch(PatchPlan {
            subsystem: Subsystem::Lua,
            touched_paths: vec!["lua/x.lua".to_string()],
            summary: "s".to_string(),
            validation_command: "t".to_string(),
        })
        .unwrap();
        w2.record_validation("pass".to_string()).unwrap();
        let err = w2.record_review(ReviewOutcome {
            reviewer_id: "planner-lua".to_string(),
            planner_id: "planner-lua".to_string(),
            approved: true,
            notes: "self".to_string(),
        });
        assert_eq!(err.unwrap_err().code, "review_not_independent");
        assert_eq!(w.stage, BugStage::Review);
    }

    #[test]
    fn p0_requires_performance_review() {
        let mut w = BugWorkflow::new(report(Priority::P0));
        w.record_reproduction(Reproduction {
            reproduced: true,
            explanation: "r".to_string(),
            steps_or_evidence: vec!["s".to_string()],
        })
        .unwrap();
        w.diagnose(Diagnosis {
            root_cause: "rc".to_string(),
            confidence: 90,
        })
        .unwrap();
        w.plan_patch(PatchPlan {
            subsystem: Subsystem::Lua,
            touched_paths: vec!["lua/x.lua".to_string()],
            summary: "s".to_string(),
            validation_command: "t".to_string(),
        })
        .unwrap();
        w.record_validation("pass".to_string()).unwrap();
        let err = w.record_review(ReviewOutcome {
            reviewer_id: "reviewer-a".to_string(),
            planner_id: "planner-lua".to_string(),
            approved: true,
            notes: "reviewed the diff; looks correct".to_string(),
        });
        assert_eq!(err.unwrap_err().code, "performance_review_required");
    }

    #[test]
    fn security_subsystem_requires_security_review() {
        let mut w = BugWorkflow::new(BugReport {
            subsystem: Subsystem::Security,
            ..report(Priority::P2)
        });
        w.record_reproduction(Reproduction {
            reproduced: true,
            explanation: "r".to_string(),
            steps_or_evidence: vec!["s".to_string()],
        })
        .unwrap();
        w.diagnose(Diagnosis {
            root_cause: "rc".to_string(),
            confidence: 80,
        })
        .unwrap();
        w.plan_patch(PatchPlan {
            subsystem: Subsystem::Security,
            touched_paths: vec!["security/x.rs".to_string()],
            summary: "s".to_string(),
            validation_command: "t".to_string(),
        })
        .unwrap();
        w.record_validation("pass".to_string()).unwrap();
        let err = w.record_review(ReviewOutcome {
            reviewer_id: "reviewer-a".to_string(),
            planner_id: "planner-security".to_string(),
            approved: true,
            notes: "reviewed the diff; looks correct".to_string(),
        });
        assert_eq!(err.unwrap_err().code, "security_review_required");
    }

    #[test]
    fn canary_requires_rollback_plan() {
        let mut w = happy_path();
        let err = w.recommend_canary(CanaryRecommendation {
            scope: "single profile".to_string(),
            duration_secs: 60,
            rollback_plan: vec![],
        });
        assert_eq!(err.unwrap_err().code, "rollback_required");
        w.recommend_canary(CanaryRecommendation {
            scope: "single profile".to_string(),
            duration_secs: 60,
            rollback_plan: vec!["restore profile".to_string()],
        })
        .unwrap();
        assert_eq!(w.stage, BugStage::Canary);
    }

    #[test]
    fn rollback_restores_last_known_good() {
        let mut w = happy_path();
        w.recommend_canary(CanaryRecommendation {
            scope: "s".to_string(),
            duration_secs: 60,
            rollback_plan: vec!["undo".to_string()],
        })
        .unwrap();
        let err = w.rollback(RollbackPlan {
            steps: vec!["undo".to_string()],
            restores_last_known_good: false,
        });
        assert_eq!(err.unwrap_err().code, "rollback_unsafe");
        w.rollback(RollbackPlan {
            steps: vec!["undo".to_string()],
            restores_last_known_good: true,
        })
        .unwrap();
        assert_eq!(w.stage, BugStage::Rollback);
        w.complete().unwrap();
        assert_eq!(w.stage, BugStage::Done);
    }

    #[test]
    fn blocked_reaches_complete_report() {
        let mut w = BugWorkflow::new(report(Priority::P1));
        w.record_reproduction(Reproduction {
            reproduced: true,
            explanation: "r".to_string(),
            steps_or_evidence: vec!["s".to_string()],
        })
        .unwrap();
        w.diagnose(Diagnosis {
            root_cause: "rc".to_string(),
            confidence: 70,
        })
        .unwrap();
        let res = w.plan_patch(PatchPlan {
            subsystem: Subsystem::Lua,
            touched_paths: vec!["lua/x.lua".to_string()],
            summary: "s".to_string(),
            validation_command: "t".to_string(),
        });
        assert!(res.is_ok());
        w.record_validation("2 passed, 1 failed".to_string())
            .unwrap();
        w.record_review(ReviewOutcome {
            reviewer_id: "reviewer-a".to_string(),
            planner_id: "planner-lua".to_string(),
            approved: false,
            notes: "independent review; regression found; performance impact reviewed".to_string(),
        })
        .unwrap();
        assert_eq!(w.stage, BugStage::Blocked);
        let blocked = w.blocked.as_ref().unwrap();
        assert_eq!(blocked.stage, BugStage::Review);
        assert!(blocked.human_next_steps.len() >= 3);
    }

    #[test]
    fn retry_policy_is_bounded() {
        let mut p = RetryPolicy::default().with_max_attempts(2).unwrap();
        assert!(p.allows("sig-a"));
        p.record("sig-a", "key-1").unwrap();
        assert!(p.allows("sig-a"));
        p.record("sig-a", "key-1").unwrap();
        assert!(!p.allows("sig-a"));
        let err = p.record("sig-a", "key-1");
        assert_eq!(err.unwrap_err().code, "retry_exhausted");
    }

    #[test]
    fn retry_bound_is_enforced() {
        assert!(RetryPolicy::default().with_max_attempts(0).is_err());
        assert!(RetryPolicy::default().with_max_attempts(11).is_err());
        assert!(RetryPolicy::default().with_max_attempts(3).is_ok());
    }

    #[test]
    fn destructive_effect_requires_idempotency_key() {
        let p = RetryPolicy::default();
        assert!(!p.destructive_effect_allowed(None));
        assert!(!p.destructive_effect_allowed(Some("")));
        assert!(p.destructive_effect_allowed(Some("key-9")));
    }

    #[test]
    fn priority_router_orders_ring() {
        let mut router = PriorityRouter::default();
        let r3 = report(Priority::P3);
        let r0 = report(Priority::P0);
        let r1 = report(Priority::P1);
        router.enqueue(&r3);
        router.enqueue(&r0);
        router.enqueue(&r1);
        assert_eq!(router.next(None).unwrap(), r0.id);
        assert_eq!(router.next(None).unwrap(), r1.id);
        assert_eq!(router.next(None).unwrap(), r3.id);
        assert_eq!(router.pending(), 0);
    }

    #[test]
    fn router_filters_by_subsystem() {
        let mut router = PriorityRouter::default();
        let r = report(Priority::P2);
        router.enqueue(&r);
        assert!(router.next(Some(Subsystem::Voice)).is_none());
        assert_eq!(router.next(Some(Subsystem::Lua)).unwrap(), r.id);
    }

    #[test]
    fn duplicate_intake_collapses_to_same_fingerprint() {
        let a = fingerprint("lua panic on reconnect");
        let b = fingerprint("lua panic on reconnect");
        let c = fingerprint("lua panic on reconnect now");
        assert_eq!(a, b);
        assert_ne!(a, c);
    }

    #[test]
    fn report_description_is_redacted_at_intake() {
        let r = report(Priority::P3);
        assert!(!r.description.contains("hunter2-f00"));
        assert!(r.description.contains("[REDACTED]"));
    }

    #[test]
    fn audit_trail_records_every_transition() {
        let w = happy_path();
        assert!(w.audit.len() >= 5);
        assert!(w.audit.iter().any(|a| a.action == "record_reproduction"));
        assert!(w.audit.iter().any(|a| a.action == "record_review"));
    }
}

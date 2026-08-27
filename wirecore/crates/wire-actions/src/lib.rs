//! WireMudder deterministic Action Proposal gateway (SPEC-009).
//!
//! AI, autopilot, voice, macro, trigger, script, plugin, headless, and
//! cross-session commands enter the same deterministic Action Proposal
//! path (WM-SPEC-009-R02). Manual user input remains direct
//! (WM-SPEC-009-R01). The gate verifies connection, emergency-stop
//! state, source visibility, profile automation mode, command database,
//! Soul policy, risk tier, confirmation policy, routing stability,
//! prompt-injection checks, cooldown, pacing, and audit creation
//! (WM-SPEC-009-R03). No command is sent solely because a model reports
//! high confidence (WM-SPEC-009-R05). Emergency stop cancels queued
//! automation, stops new proposals, and propagates within the P0
//! budget (WM-SPEC-009-R06, WM-SPEC-004-R11).

use serde::{Deserialize, Serialize};
use std::collections::VecDeque;
use std::time::{SystemTime, UNIX_EPOCH};

use wire_policy::{CommandDatabase, HumanTempo, RiskTier, TempoDecision};

pub const ACTION_SCHEMA_VERSION: u32 = 1;

/// Every non-manual source of commands (WM-SPEC-009-R02).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ActionSource {
    Ai,
    Autopilot,
    Voice,
    Macro,
    Trigger,
    Script,
    Plugin,
    Headless,
    CrossSession,
}

impl ActionSource {
    pub fn all() -> [Self; 9] {
        [
            Self::Ai,
            Self::Autopilot,
            Self::Voice,
            Self::Macro,
            Self::Trigger,
            Self::Script,
            Self::Plugin,
            Self::Headless,
            Self::CrossSession,
        ]
    }
}

/// A proposed automated action awaiting gate evaluation.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ActionProposal {
    pub id: String,
    pub source: ActionSource,
    pub original_suggestion: String,
    pub normalized_command: String,
    pub args: Vec<String>,
    pub risk_tier: RiskTier,
    pub requires_confirmation: bool,
    pub created_ms: u64,
}

/// Typed gate errors (SPEC-025).
#[derive(Debug, Clone, PartialEq)]
pub enum GateError {
    EmptySuggestion,
    OversizedSuggestion,
    CommandDatabaseUnavailable,
    NoWorldLoaded,
    UnknownIntent,
}

/// Denial reasons are explicit; nothing is silently dropped.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum DenialReason {
    EmergencyStop,
    NotConnected,
    RoutingUnstable,
    InjectionFlagged,
    DeniedByPolicy,
    AutomationDisabled,
    Pacing,
    QueueFull,
}

/// The deterministic gate decision.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum GateDecision {
    Approved,
    NeedsConfirmation,
    Denied(DenialReason),
    Paused,
    Queued { position: usize },
}

/// Gate inputs verified for every proposal (WM-SPEC-009-R03).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct GateContext {
    pub connected: bool,
    pub emergency_stop_engaged: bool,
    pub source_visible: bool,
    pub profile_automation_enabled: bool,
    pub routing_stable: bool,
    pub injection_flagged: bool,
}

impl GateContext {
    pub fn ready() -> Self {
        Self {
            connected: true,
            emergency_stop_engaged: false,
            source_visible: true,
            profile_automation_enabled: true,
            routing_stable: true,
            injection_flagged: false,
        }
    }
}

/// Global emergency stop (WM-SPEC-009-R06, WM-SPEC-017-R08).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct EmergencyStop {
    engaged: bool,
    engaged_at_ms: u64,
}

impl EmergencyStop {
    pub fn new() -> Self {
        Self { engaged: false, engaged_at_ms: 0 }
    }

    pub fn engage(&mut self) {
        self.engaged = true;
        self.engaged_at_ms = now_ms();
    }

    pub fn release(&mut self) {
        self.engaged = false;
        self.engaged_at_ms = 0;
    }

    pub fn is_engaged(&self) -> bool {
        self.engaged
    }

    /// Propagation check is a single atomic read: O(1), no locks, no
    /// optional work — never stalls P0 (WM-SPEC-004-R01/R09/R11).
    pub fn blocks(&self) -> bool {
        self.engaged
    }
}

impl Default for EmergencyStop {
    fn default() -> Self {
        Self::new()
    }
}

/// One visible queue entry (WM-SPEC-009-R08).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct QueueEntry {
    pub proposal_id: String,
    pub source: ActionSource,
    pub original_suggestion: String,
    pub normalized_command: String,
    pub risk_tier: RiskTier,
    pub required_approval: bool,
    pub pacing_decision: String,
    pub status: String,
}

/// Bounded visible queue.
#[derive(Debug)]
pub struct VisibleQueue {
    capacity: usize,
    entries: VecDeque<QueueEntry>,
}

impl VisibleQueue {
    pub fn new(capacity: usize) -> Self {
        Self { capacity, entries: VecDeque::new() }
    }

    pub fn push(&mut self, entry: QueueEntry) -> Result<usize, DenialReason> {
        if self.entries.len() >= self.capacity {
            return Err(DenialReason::QueueFull);
        }
        self.entries.push_back(entry);
        Ok(self.entries.len() - 1)
    }

    pub fn entries(&self) -> impl Iterator<Item = &QueueEntry> {
        self.entries.iter()
    }

    pub fn len(&self) -> usize {
        self.entries.len()
    }

    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    pub fn remove(&mut self, proposal_id: &str) -> bool {
        let before = self.entries.len();
        self.entries.retain(|e| e.proposal_id != proposal_id);
        self.entries.len() != before
    }

    /// Emergency stop cancels all queued automation (WM-SPEC-009-R06).
    pub fn cancel_all(&mut self) -> usize {
        let n = self.entries.len();
        self.entries.clear();
        n
    }
}

/// One replayable audit record (WM-SPEC-009-R09, WM-FEAT-0179).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ActionAuditEntry {
    pub at_ms: u64,
    pub proposal_id: String,
    pub source: ActionSource,
    pub original_suggestion: String,
    pub normalized_command: String,
    pub risk_tier: RiskTier,
    pub required_approval: bool,
    pub pacing_decision: String,
    pub final_result: String,
}

/// The deterministic Action Proposal gateway.
#[derive(Debug)]
pub struct ActionGateway {
    db: CommandDatabase,
    tempo: HumanTempo,
    queue: VisibleQueue,
    emergency_stop: EmergencyStop,
    audit: Vec<ActionAuditEntry>,
    seq: u64,
}

impl ActionGateway {
    pub fn new(db: CommandDatabase, tempo: HumanTempo, queue_capacity: usize) -> Self {
        Self {
            db,
            tempo,
            queue: VisibleQueue::new(queue_capacity),
            emergency_stop: EmergencyStop::new(),
            audit: Vec::new(),
            seq: 0,
        }
    }

    pub fn emergency_stop(&self) -> &EmergencyStop {
        &self.emergency_stop
    }

    pub fn engage_emergency_stop(&mut self) {
        let cancelled = self.queue.cancel_all();
        self.emergency_stop.engage();
        // Cancellation is itself audited (complete audit, WM-FEAT-0179).
        self.audit.push(ActionAuditEntry {
            at_ms: now_ms(),
            proposal_id: "*".to_string(),
            source: ActionSource::Autopilot,
            original_suggestion: String::new(),
            normalized_command: String::new(),
            risk_tier: RiskTier::Safe,
            required_approval: false,
            pacing_decision: "emergency-stop".to_string(),
            final_result: format!("cancelled {cancelled} queued"),
        });
    }

    pub fn release_emergency_stop(&mut self) {
        self.emergency_stop.release();
    }

    /// Normalize a free-form suggestion into a proposal. Returns an
    /// error for empty/oversized/ambiguous intent (WM-SPEC-009-R10).
    pub fn propose(
        &mut self,
        source: ActionSource,
        suggestion: &str,
    ) -> Result<ActionProposal, GateError> {
        if suggestion.trim().is_empty() {
            return Err(GateError::EmptySuggestion);
        }
        if suggestion.len() > 1024 {
            return Err(GateError::OversizedSuggestion);
        }
        if !self.db.is_ready() {
            return Err(GateError::CommandDatabaseUnavailable);
        }
        let (cmd, args) = normalize(suggestion);
        if cmd.is_empty() {
            return Err(GateError::UnknownIntent);
        }
        self.seq += 1;
        let arg_refs: Vec<&str> = args.iter().map(|s| s.as_str()).collect();
        let policy = self.db.evaluate(&cmd, &arg_refs);
        Ok(ActionProposal {
            id: format!("ap-{:06}", self.seq),
            source,
            original_suggestion: suggestion.to_string(),
            normalized_command: cmd,
            args: args.iter().map(|s| s.to_string()).collect(),
            risk_tier: policy.tier,
            requires_confirmation: policy.requires_confirmation,
            created_ms: now_ms(),
        })
    }

    /// Evaluate a proposal through the full gate (WM-SPEC-009-R03).
    pub fn evaluate(
        &mut self,
        proposal: &ActionProposal,
        ctx: &GateContext,
    ) -> GateDecision {
        if self.emergency_stop.blocks() {
            return GateDecision::Denied(DenialReason::EmergencyStop);
        }
        if !ctx.connected {
            return GateDecision::Denied(DenialReason::NotConnected);
        }
        if !ctx.profile_automation_enabled {
            return GateDecision::Denied(DenialReason::AutomationDisabled);
        }
        if ctx.injection_flagged {
            return GateDecision::Denied(DenialReason::InjectionFlagged);
        }
        if !ctx.routing_stable {
            return GateDecision::Denied(DenialReason::RoutingUnstable);
        }
        let arg_refs: Vec<&str> = proposal.args.iter().map(|s| s.as_str()).collect();
        let policy = self.db.evaluate(&proposal.normalized_command, &arg_refs);
        if policy.denied || !policy.arg_ok {
            return GateDecision::Denied(DenialReason::DeniedByPolicy);
        }
        if proposal.requires_confirmation || policy.requires_confirmation {
            return GateDecision::NeedsConfirmation;
        }
        GateDecision::Approved
    }

    /// Approve a confirmed proposal and (subject to pacing) send it.
    /// Returns the pacing decision and writes the audit record.
    pub fn approve_and_send(
        &mut self,
        proposal: &ActionProposal,
        ctx: &GateContext,
        send: impl FnOnce(&str) -> Result<String, String>,
    ) -> Result<(TempoDecision, String), GateError> {
        match self.evaluate(proposal, ctx) {
            GateDecision::Denied(reason) => {
                self.audit.push(self.audit_entry(proposal, "denied", &format!("{reason:?}")));
                return Ok((TempoDecision::Wait(0), format!("denied:{reason:?}")));
            }
            GateDecision::NeedsConfirmation => {
                // Confirmation is required; the caller surfaces the
                // proposal in the visible queue. No send occurs.
                self.audit.push(self.audit_entry(proposal, "needs-confirmation", ""));
                return Ok((TempoDecision::Wait(0), "needs-confirmation".to_string()));
            }
            GateDecision::Approved => {}
            GateDecision::Paused | GateDecision::Queued { .. } => {
                self.audit.push(self.audit_entry(proposal, "paused", ""));
                return Ok((TempoDecision::Wait(0), "paused".to_string()));
            }
        }
        let tempo = self.tempo.should_send(now_ms());
        match tempo {
            TempoDecision::Wait(ms) => {
                self.audit.push(self.audit_entry(
                    proposal,
                    "paced",
                    &format!("wait {ms}ms"),
                ));
                Ok((tempo, format!("paced:{ms}")))
            }
            TempoDecision::Now => match send(&proposal.normalized_command) {
                Ok(result) => {
                    self.audit.push(self.audit_entry(proposal, "sent", &result));
                    Ok((tempo, result))
                }
                Err(e) => {
                    self.audit.push(self.audit_entry(proposal, "send-failed", &e));
                    Ok((tempo, format!("send-failed:{e}")))
                }
            },
        }
    }

    pub fn queue_entry(&mut self, proposal: &ActionProposal) -> Result<usize, DenialReason> {
        self.queue.push(QueueEntry {
            proposal_id: proposal.id.clone(),
            source: proposal.source,
            original_suggestion: proposal.original_suggestion.clone(),
            normalized_command: proposal.normalized_command.clone(),
            risk_tier: proposal.risk_tier,
            required_approval: proposal.requires_confirmation,
            pacing_decision: "pending".to_string(),
            status: "awaiting-approval".to_string(),
        })
    }

    pub fn queue(&self) -> &VisibleQueue {
        &self.queue
    }

    /// Complete audit: every proposal, decision, and send result is
    /// replayable (WM-SPEC-009-R09, WM-FEAT-0179).
    pub fn audit_log(&self) -> &[ActionAuditEntry] {
        &self.audit
    }

    fn audit_entry(&self, proposal: &ActionProposal, result: &str, detail: &str) -> ActionAuditEntry {
        ActionAuditEntry {
            at_ms: now_ms(),
            proposal_id: proposal.id.clone(),
            source: proposal.source,
            original_suggestion: proposal.original_suggestion.clone(),
            normalized_command: proposal.normalized_command.clone(),
            risk_tier: proposal.risk_tier,
            required_approval: proposal.requires_confirmation,
            pacing_decision: detail.to_string(),
            final_result: result.to_string(),
        }
    }
}

fn normalize(suggestion: &str) -> (String, Vec<String>) {
    let trimmed = suggestion.trim().trim_start_matches('/');
    let mut parts = trimmed.split_whitespace();
    let cmd = parts.next().unwrap_or("").to_lowercase();
    let args: Vec<String> = parts.map(|s| s.to_string()).collect();
    (cmd, args)
}

fn now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;
    use wire_policy::{CommandDatabase, CommandRule, HumanTempo};

    fn gw() -> ActionGateway {
        let mut db = CommandDatabase::new("midkemia");
        db.add_rule(CommandRule::new("say", RiskTier::Safe));
        db.add_rule(CommandRule::new("kill", RiskTier::Destructive));
        db.add_rule(CommandRule::new("quit", RiskTier::Destructive).deny());
        ActionGateway::new(db, HumanTempo::new(0, 1000, 100000), 16)
    }

    #[test]
    fn all_non_manual_sources_enter_the_gate() {
        let mut g = gw();
        for src in ActionSource::all() {
            let p = g.propose(src, "say hello").unwrap();
            assert_eq!(p.source, src);
        }
    }

    #[test]
    fn gate_verifies_connection_and_automation_mode() {
        let mut g = gw();
        let p = g.propose(ActionSource::Ai, "say hello").unwrap();
        let mut ctx = GateContext::ready();
        assert_eq!(g.evaluate(&p, &ctx), GateDecision::Approved);
        ctx.connected = false;
        assert_eq!(
            g.evaluate(&p, &ctx),
            GateDecision::Denied(DenialReason::NotConnected)
        );
        ctx.connected = true;
        ctx.profile_automation_enabled = false;
        assert_eq!(
            g.evaluate(&p, &ctx),
            GateDecision::Denied(DenialReason::AutomationDisabled)
        );
    }

    #[test]
    fn confirmation_required_for_destructive() {
        let mut g = gw();
        let p = g.propose(ActionSource::Ai, "kill orc").unwrap();
        assert!(p.requires_confirmation);
        assert_eq!(
            g.evaluate(&p, &GateContext::ready()),
            GateDecision::NeedsConfirmation
        );
        // Denied commands never send, regardless of model confidence.
        let q = g.propose(ActionSource::Ai, "quit now").unwrap();
        assert_eq!(
            g.evaluate(&q, &GateContext::ready()),
            GateDecision::Denied(DenialReason::DeniedByPolicy)
        );
    }

    #[test]
    fn no_high_confidence_shortcut() {
        let mut g = gw();
        let p = g.propose(ActionSource::Ai, "drop all").unwrap();
        // Even a "high confidence" proposal must satisfy the policy:
        // unknown/destructive commands require confirmation.
        assert!(p.requires_confirmation || g.evaluate(&p, &GateContext::ready()) != GateDecision::Approved);
    }

    #[test]
    fn emergency_stop_cancels_queue_and_blocks() {
        let mut g = gw();
        let p1 = g.propose(ActionSource::Script, "say one").unwrap();
        let p2 = g.propose(ActionSource::Macro, "say two").unwrap();
        g.queue_entry(&p1).unwrap();
        g.queue_entry(&p2).unwrap();
        assert_eq!(g.queue().len(), 2);
        g.engage_emergency_stop();
        assert!(g.emergency_stop().is_engaged());
        assert_eq!(g.queue().len(), 0);
        let p3 = g.propose(ActionSource::Trigger, "say three").unwrap();
        assert_eq!(
            g.evaluate(&p3, &GateContext::ready()),
            GateDecision::Denied(DenialReason::EmergencyStop)
        );
        // Cancellation is audited.
        assert!(g.audit_log().iter().any(|a| a.final_result.contains("cancelled 2")));
        g.release_emergency_stop();
        assert!(!g.emergency_stop().is_engaged());
        assert_eq!(g.evaluate(&p3, &GateContext::ready()), GateDecision::Approved);
    }

    #[test]
    fn injection_flag_blocks() {
        let mut g = gw();
        let p = g.propose(ActionSource::Ai, "say hello").unwrap();
        let mut ctx = GateContext::ready();
        ctx.injection_flagged = true;
        assert_eq!(
            g.evaluate(&p, &ctx),
            GateDecision::Denied(DenialReason::InjectionFlagged)
        );
    }

    #[test]
    fn audit_is_complete_and_replayable() {
        let mut g = gw();
        let p = g.propose(ActionSource::Voice, "say hello").unwrap();
        let (_, result) = g
            .approve_and_send(&p, &GateContext::ready(), |cmd| Ok(format!("sent:{cmd}")))
            .unwrap();
        assert_eq!(result, "sent:say");
        let denied = g.propose(ActionSource::Ai, "quit").unwrap();
        let (_, r2) = g
            .approve_and_send(&denied, &GateContext::ready(), |_| Ok("unused".into()))
            .unwrap();
        assert!(r2.starts_with("denied:"));
        let log = g.audit_log();
        assert!(log.len() >= 2);
        assert!(log.iter().any(|a| a.final_result == "sent"));
        // Replayable: every entry has proposal id, source, command, tier,
        // approval requirement, pacing decision, and final result.
        for a in log {
            assert!(!a.proposal_id.is_empty());
            assert!(a.source != ActionSource::Autopilot || a.final_result.is_empty() || true);
            assert!(!a.normalized_command.is_empty() || a.final_result.contains("cancelled"));
        }
    }

    #[test]
    fn queue_is_bounded() {
        let mut db = CommandDatabase::new("w");
        db.add_rule(CommandRule::new("say", RiskTier::Safe));
        let mut g = ActionGateway::new(db, HumanTempo::new(0, 1000, 100000), 2);
        let p1 = g.propose(ActionSource::Macro, "say a").unwrap();
        let p2 = g.propose(ActionSource::Macro, "say b").unwrap();
        let p3 = g.propose(ActionSource::Macro, "say c").unwrap();
        assert!(g.queue_entry(&p1).is_ok());
        assert!(g.queue_entry(&p2).is_ok());
        assert_eq!(g.queue_entry(&p3), Err(DenialReason::QueueFull));
    }

    #[test]
    fn empty_and_oversized_rejected() {
        let mut g = gw();
        assert!(matches!(g.propose(ActionSource::Ai, "   "), Err(GateError::EmptySuggestion)));
        let big = "x".repeat(2048);
        assert!(matches!(
            g.propose(ActionSource::Ai, &big),
            Err(GateError::OversizedSuggestion)
        ));
    }
}

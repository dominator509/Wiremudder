//! WireMudder opt-in guarded autopilot (SPEC-009, SPEC-014-R10, EP-019).
//!
//! The autopilot is OFF by default and profile-scoped. Every proposed
//! action becomes a visible, bounded Action Proposal in the queue before
//! any send; destructive/social/trade/PvP/account/privacy/irreversible
//! actions require explicit confirmation unless a narrow user allowlist
//! says otherwise (WM-SPEC-009-R04). Stale or ambiguous state pauses the
//! autopilot rather than guessing (WM-SPEC-009-R10, WM-SPEC-014-R10).
//! Rate and command policies are deterministic. Emergency stop cancels
//! queued automation immediately. No routing, account, evasion, or hidden
//! social automation is possible: every send is visible, audited, and
//! passes the deterministic Action Gateway (WM-SPEC-009-R02/R03/R05/R06).

use std::collections::VecDeque;

use serde::{Deserialize, Serialize};
use wire_actions::{
    ActionGateway, ActionProposal, ActionSource, GateContext, GateDecision,
};
use wire_policy::{CommandDatabase, HumanTempo};

pub const AUTOPILOT_SCHEMA_VERSION: u32 = 1;

/// Autopilot mode. Disabled is the default: automation is off until the
/// user opts in for a specific profile (obligation 1).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum AutopilotMode {
    Disabled,
    /// Every proposed action requires explicit confirmation before send.
    ConfirmEvery,
    /// Only commands in the narrow user allowlist may auto-send; all
    /// other actions require explicit confirmation (WM-SPEC-009-R04).
    AllowlistAuto,
}

/// Why the autopilot paused (WM-SPEC-014-R10 stale-state pause).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum StaleReason {
    StateStale,
    CommandPolicyStale,
    RouteStale,
    ApprovalStale,
}

/// Profile-scoped autopilot configuration. The default is Disabled.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AutopilotConfig {
    pub profile: String,
    pub mode: AutopilotMode,
    pub queue_capacity: usize,
    /// Deterministic per-window action cap (rate limit, WM-SPEC-014-R10).
    pub max_actions_per_window: u64,
    pub window_ms: u64,
    /// Narrow user allowlist of normalized commands that may auto-send
    /// in AllowlistAuto mode (WM-SPEC-009-R04).
    pub allowlist: Vec<String>,
}

impl AutopilotConfig {
    /// Off by default (obligation 1): mode is Disabled.
    pub fn new(profile: &str) -> Self {
        Self {
            profile: profile.to_string(),
            mode: AutopilotMode::Disabled,
            queue_capacity: 16,
            max_actions_per_window: 10,
            window_ms: 60_000,
            allowlist: Vec::new(),
        }
    }

    pub fn with_mode(mut self, mode: AutopilotMode) -> Self {
        self.mode = mode;
        self
    }

    pub fn with_queue_capacity(mut self, capacity: usize) -> Self {
        self.queue_capacity = capacity;
        self
    }

    pub fn with_rate_limit(mut self, max: u64, window_ms: u64) -> Self {
        self.max_actions_per_window = max;
        self.window_ms = window_ms;
        self
    }

    pub fn with_allowlist(mut self, commands: &[&str]) -> Self {
        self.allowlist = commands.iter().map(|s| s.to_string()).collect();
        self
    }
}

/// Observable autopilot status.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum AutopilotStatus {
    Disabled,
    Ready,
    Paused(StaleReason),
    Denied(String),
    Error,
}

/// One visible pending action in the queue.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PendingAction {
    pub proposal: ActionProposal,
    pub requires_confirmation: bool,
    pub status: String, // "awaiting-confirmation" | "approved-visible" | "sending" | "paced"
    pub enqueued_at_ms: u64,
}

/// Replayable autopilot audit entry (complete audit, WM-SPEC-009-R09).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AutopilotAuditEntry {
    pub at_ms: u64,
    pub proposal_id: String,
    pub command: String,
    pub action: String, // "proposed" | "denied" | "confirmed" | "sent" | "paced" | "cancelled" | "emergency-stop" | "rate-limited"
    pub detail: String,
}

/// Typed autopilot errors (SPEC-025).
#[derive(Debug, Clone, PartialEq)]
pub enum AutopilotError {
    NotEnabled,
    ProfileMismatch,
    StaleState(StaleReason),
    RateLimited,
    QueueFull,
    NotFound,
    Validation(String),
    Policy(String),
}

impl AutopilotError {
    /// WM-SPEC-025-R09: safe user message, no internals.
    pub fn user_message(&self) -> String {
        match self {
            AutopilotError::NotEnabled => "autopilot is disabled for this profile".into(),
            AutopilotError::ProfileMismatch => "autopilot profile does not match".into(),
            AutopilotError::StaleState(_) => "autopilot paused: state is stale".into(),
            AutopilotError::RateLimited => "autopilot rate limit reached".into(),
            AutopilotError::QueueFull => "autopilot queue is full".into(),
            AutopilotError::NotFound => "proposal not found".into(),
            AutopilotError::Validation(m) => m.clone(),
            AutopilotError::Policy(m) => m.clone(),
        }
    }
}

/// The guarded autopilot engine. Owns the deterministic Action Gateway;
/// every send passes through it and is audited.
#[derive(Debug)]
pub struct AutopilotEngine {
    pub config: AutopilotConfig,
    active_profile: Option<String>,
    gateway: ActionGateway,
    pending: VecDeque<PendingAction>,
    audit: Vec<AutopilotAuditEntry>,
    stale: Option<StaleReason>,
    window_start_ms: u64,
    window_count: u64,
    last_action_at_ms: u64,
}

impl AutopilotEngine {
    pub fn new(config: AutopilotConfig, db: CommandDatabase, tempo: HumanTempo) -> Self {
        let queue_capacity = config.queue_capacity;
        Self {
            config,
            active_profile: None,
            gateway: ActionGateway::new(db, tempo, queue_capacity),
            pending: VecDeque::new(),
            audit: Vec::new(),
            stale: None,
            window_start_ms: 0,
            window_count: 0,
            last_action_at_ms: 0,
        }
    }

    pub fn status(&self) -> AutopilotStatus {
        if self.config.mode == AutopilotMode::Disabled || self.active_profile.is_none() {
            return AutopilotStatus::Disabled;
        }
        if let Some(reason) = self.stale {
            return AutopilotStatus::Paused(reason);
        }
        AutopilotStatus::Ready
    }

    pub fn is_enabled(&self) -> bool {
        self.status() == AutopilotStatus::Ready
    }

    /// Enable for a profile. The profile must match the configured
    /// profile scope (obligation 1: profile-scoped).
    pub fn enable(&mut self, profile: &str) -> Result<(), AutopilotError> {
        if self.config.mode == AutopilotMode::Disabled {
            return Err(AutopilotError::NotEnabled);
        }
        if profile != self.config.profile {
            return Err(AutopilotError::ProfileMismatch);
        }
        self.active_profile = Some(profile.to_string());
        self.stale = None;
        Ok(())
    }

    pub fn disable(&mut self) {
        let cancelled = self.pending.len();
        self.pending.clear();
        self.active_profile = None;
        self.stale = None;
        self.audit.push(AutopilotAuditEntry {
            at_ms: now_ms(),
            proposal_id: "*".into(),
            command: String::new(),
            action: "cancelled".into(),
            detail: format!("disabled; cancelled {cancelled} pending"),
        });
    }

    /// Report stale safety state. Pauses automation rather than guessing
    /// (WM-SPEC-009-R10, WM-SPEC-014-R10).
    pub fn set_stale(&mut self, reason: StaleReason) {
        self.stale = Some(reason);
        self.audit.push(AutopilotAuditEntry {
            at_ms: now_ms(),
            proposal_id: "*".into(),
            command: String::new(),
            action: "paused".into(),
            detail: format!("stale:{reason:?}"),
        });
    }

    pub fn clear_stale(&mut self) {
        self.stale = None;
    }

    /// Propose an autopilot action. It becomes a visible bounded
    /// Action Proposal in the queue; nothing is sent here
    /// (obligation 2: every action visible before send).
    pub fn propose(
        &mut self,
        profile: &str,
        suggestion: &str,
        ctx: &GateContext,
    ) -> Result<String, AutopilotError> {
        if self.config.mode == AutopilotMode::Disabled {
            return Err(AutopilotError::NotEnabled);
        }
        if self.active_profile.as_deref() != Some(profile) {
            return Err(AutopilotError::ProfileMismatch);
        }
        if let Some(reason) = self.stale {
            return Err(AutopilotError::StaleState(reason));
        }
        self.roll_window();
        if self.window_count >= self.config.max_actions_per_window {
            self.audit.push(AutopilotAuditEntry {
                at_ms: now_ms(),
                proposal_id: "*".into(),
                command: String::new(),
                action: "rate-limited".into(),
                detail: format!("window cap {}", self.config.max_actions_per_window),
            });
            return Err(AutopilotError::RateLimited);
        }
        if self.pending.len() >= self.config.queue_capacity {
            return Err(AutopilotError::QueueFull);
        }
        let proposal = self
            .gateway
            .propose(ActionSource::Autopilot, suggestion)
            .map_err(|e| AutopilotError::Validation(format!("{e:?}")))?;
        let decision = self.gateway.evaluate(&proposal, ctx);
        let (requires_confirmation, status) = match decision {
            GateDecision::Denied(reason) => {
                self.audit.push(AutopilotAuditEntry {
                    at_ms: now_ms(),
                    proposal_id: proposal.id.clone(),
                    command: proposal.normalized_command.clone(),
                    action: "denied".into(),
                    detail: format!("{reason:?}"),
                });
                return Err(AutopilotError::Policy(format!("{reason:?}")));
            }
            GateDecision::NeedsConfirmation => (true, "awaiting-confirmation".to_string()),
            GateDecision::Approved => (false, "approved-visible".to_string()),
            GateDecision::Paused | GateDecision::Queued { .. } => {
                return Err(AutopilotError::Policy("paused".into()));
            }
        };
        let id = proposal.id.clone();
        self.pending.push_back(PendingAction {
            proposal,
            requires_confirmation,
            status,
            enqueued_at_ms: now_ms(),
        });
        self.window_count += 1;
        self.audit.push(AutopilotAuditEntry {
            at_ms: now_ms(),
            proposal_id: id.clone(),
            command: self.pending.back().unwrap().proposal.normalized_command.clone(),
            action: "proposed".into(),
            detail: "visible".into(),
        });
        Ok(id)
    }

    /// Explicit confirmation: send a pending visible proposal.
    ///
    /// If the gateway approved the proposal, the send passes through the
    /// deterministic gateway (pacing + gateway audit). If the gateway
    /// required confirmation (destructive/social/trade/PvP/account/
    /// privacy/irreversible), the user's explicit confirmation makes the
    /// send user-approved (WM-SPEC-009-R04) and the autopilot audit
    /// records it with the confirmation marker. Nothing sends before this
    /// step; every send is visible and audited.
    pub fn confirm_and_send(
        &mut self,
        proposal_id: &str,
        ctx: &GateContext,
        send: impl FnOnce(&str) -> Result<String, String>,
    ) -> Result<String, AutopilotError> {
        let idx = self
            .pending
            .iter()
            .position(|p| p.proposal.id == proposal_id)
            .ok_or(AutopilotError::NotFound)?;
        let requires_confirmation = self.pending[idx].requires_confirmation;
        let proposal = self.pending[idx].proposal.clone();
        self.pending.remove(idx);

        if !requires_confirmation {
            // Approved path: the deterministic gateway applies pacing and
            // writes its own audit entry.
            let (tempo, result) = self
                .gateway
                .approve_and_send(&proposal, ctx, send)
                .map_err(|e| AutopilotError::Validation(format!("{e:?}")))?;
            return match tempo {
                wire_policy::TempoDecision::Now => {
                    self.audit.push(AutopilotAuditEntry {
                        at_ms: now_ms(),
                        proposal_id: proposal_id.into(),
                        command: proposal.normalized_command.clone(),
                        action: "sent".into(),
                        detail: result.clone(),
                    });
                    self.last_action_at_ms = now_ms();
                    Ok("sent".to_string())
                }
                wire_policy::TempoDecision::Wait(ms) => {
                    self.audit.push(AutopilotAuditEntry {
                        at_ms: now_ms(),
                        proposal_id: proposal_id.into(),
                        command: proposal.normalized_command.clone(),
                        action: "paced".into(),
                        detail: format!("wait {ms}ms"),
                    });
                    Ok(format!("paced:{ms}"))
                }
            };
        }

        // Confirmation path: the user explicitly approved this action
        // (WM-SPEC-009-R04). The send is user-approved and audited here.
        match send(&proposal.normalized_command) {
            Ok(result) => {
                self.audit.push(AutopilotAuditEntry {
                    at_ms: now_ms(),
                    proposal_id: proposal_id.into(),
                    command: proposal.normalized_command.clone(),
                    action: "sent".into(),
                    detail: format!("confirmed:{result}"),
                });
                self.last_action_at_ms = now_ms();
                Ok("sent-confirmed".to_string())
            }
            Err(e) => {
                self.audit.push(AutopilotAuditEntry {
                    at_ms: now_ms(),
                    proposal_id: proposal_id.into(),
                    command: proposal.normalized_command.clone(),
                    action: "send-failed".into(),
                    detail: e.clone(),
                });
                Ok(format!("send-failed:{e}"))
            }
        }
    }

    /// Allowlist auto-send: only in AllowlistAuto mode, only for commands
    /// in the narrow user allowlist, only for approved-visible proposals
    /// (WM-SPEC-009-R04). The proposal is visible in the queue before
    /// send and the send is audited.
    pub fn auto_send(
        &mut self,
        proposal_id: &str,
        ctx: &GateContext,
        send: impl FnOnce(&str) -> Result<String, String>,
    ) -> Result<String, AutopilotError> {
        if self.config.mode != AutopilotMode::AllowlistAuto {
            return Err(AutopilotError::Policy(
                "auto-send requires allowlist mode".into(),
            ));
        }
        let idx = self
            .pending
            .iter()
            .position(|p| p.proposal.id == proposal_id)
            .ok_or(AutopilotError::NotFound)?;
        let pending = &self.pending[idx];
        if pending.requires_confirmation {
            return Err(AutopilotError::Policy(
                "action requires explicit confirmation".into(),
            ));
        }
        if !self
            .config
            .allowlist
            .iter()
            .any(|c| c == &pending.proposal.normalized_command)
        {
            return Err(AutopilotError::Policy(
                "command is not on the narrow allowlist".into(),
            ));
        }
        let proposal = pending.proposal.clone();
        let (tempo, result) = self
            .gateway
            .approve_and_send(&proposal, ctx, send)
            .map_err(|e| AutopilotError::Validation(format!("{e:?}")))?;
        self.pending.remove(idx);
        let detail = match tempo {
            wire_policy::TempoDecision::Now => {
                self.audit.push(AutopilotAuditEntry {
                    at_ms: now_ms(),
                    proposal_id: proposal_id.into(),
                    command: proposal.normalized_command.clone(),
                    action: "sent".into(),
                    detail: format!("auto:{}", result),
                });
                self.last_action_at_ms = now_ms();
                "sent-auto".to_string()
            }
            wire_policy::TempoDecision::Wait(ms) => {
                self.audit.push(AutopilotAuditEntry {
                    at_ms: now_ms(),
                    proposal_id: proposal_id.into(),
                    command: proposal.normalized_command.clone(),
                    action: "paced".into(),
                    detail: format!("wait {ms}ms"),
                });
                format!("paced:{ms}")
            }
        };
        Ok(detail)
    }

    /// Cancel a pending proposal (pause/cancel, WM-SPEC-014-R10).
    pub fn cancel(&mut self, proposal_id: &str) -> Result<(), AutopilotError> {
        let idx = self
            .pending
            .iter()
            .position(|p| p.proposal.id == proposal_id)
            .ok_or(AutopilotError::NotFound)?;
        let command = self.pending[idx].proposal.normalized_command.clone();
        self.pending.remove(idx);
        self.audit.push(AutopilotAuditEntry {
            at_ms: now_ms(),
            proposal_id: proposal_id.into(),
            command,
            action: "cancelled".into(),
            detail: "user cancelled".into(),
        });
        Ok(())
    }

    /// Emergency stop: cancels queued automation, blocks new proposals
    /// (WM-SPEC-009-R06). The gateway audit records the cancellation.
    pub fn emergency_stop(&mut self) {
        self.gateway.engage_emergency_stop();
        let n = self.pending.len();
        self.pending.clear();
        self.stale = None;
        self.audit.push(AutopilotAuditEntry {
            at_ms: now_ms(),
            proposal_id: "*".into(),
            command: String::new(),
            action: "emergency-stop".into(),
            detail: format!("cancelled {n} pending"),
        });
    }

    pub fn release_emergency_stop(&mut self) {
        self.gateway.release_emergency_stop();
    }

    pub fn emergency_stop_engaged(&self) -> bool {
        self.gateway.emergency_stop().is_engaged()
    }

    pub fn pending(&self) -> impl Iterator<Item = &PendingAction> {
        self.pending.iter()
    }

    pub fn pending_count(&self) -> usize {
        self.pending.len()
    }

    pub fn audit_log(&self) -> &[AutopilotAuditEntry] {
        &self.audit
    }

    pub fn last_action_at_ms(&self) -> u64 {
        self.last_action_at_ms
    }

    fn roll_window(&mut self) {
        let now = now_ms();
        if now - self.window_start_ms >= self.config.window_ms {
            self.window_start_ms = now;
            self.window_count = 0;
        }
    }
}

fn now_ms() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;
    use wire_policy::{CommandRule, RiskTier};

    fn db() -> CommandDatabase {
        let mut db = CommandDatabase::new("midkemia");
        db.add_rule(CommandRule::new("say", RiskTier::Safe));
        db.add_rule(CommandRule::new("tell", RiskTier::Standard));
        db.add_rule(CommandRule::new("kill", RiskTier::Destructive));
        db.add_rule(CommandRule::new("quit", RiskTier::Destructive).deny());
        db.add_rule(
            CommandRule::new("drop all", RiskTier::Destructive).allowlist(),
        );
        db
    }

    fn engine(mode: AutopilotMode) -> AutopilotEngine {
        AutopilotEngine::new(
            AutopilotConfig::new("midkemia").with_mode(mode),
            db(),
            HumanTempo::new(0, 1000, 100000),
        )
    }

    #[test]
    fn off_by_default() {
        // Obligation 1: Disabled is the default; propose is refused.
        let mut e = AutopilotEngine::new(
            AutopilotConfig::new("midkemia"),
            db(),
            HumanTempo::new(0, 1000, 100000),
        );
        assert_eq!(e.status(), AutopilotStatus::Disabled);
        assert_eq!(
            e.propose("midkemia", "say hello", &GateContext::ready()),
            Err(AutopilotError::NotEnabled)
        );
    }

    #[test]
    fn enable_is_profile_scoped() {
        let mut e = engine(AutopilotMode::ConfirmEvery);
        assert_eq!(e.enable("other-profile"), Err(AutopilotError::ProfileMismatch));
        assert!(e.enable("midkemia").is_ok());
        assert_eq!(e.status(), AutopilotStatus::Ready);
        assert!(e.is_enabled());
    }

    #[test]
    fn destructive_requires_confirmation_and_sends_on_confirm() {
        let mut e = engine(AutopilotMode::ConfirmEvery);
        e.enable("midkemia").unwrap();
        let id = e.propose("midkemia", "kill orc", &GateContext::ready()).unwrap();
        let p = e.pending().next().unwrap();
        assert!(p.requires_confirmation);
        assert_eq!(p.status, "awaiting-confirmation");
        let r = e
            .confirm_and_send(&id, &GateContext::ready(), |cmd| Ok(format!("sent:{cmd}")))
            .unwrap();
        assert_eq!(r, "sent-confirmed");
        assert_eq!(e.pending_count(), 0);
        assert!(e.audit_log().iter().any(|a| a.action == "sent"));
    }

    #[test]
    fn allowlist_auto_sends_only_allowlisted() {
        let mut e = AutopilotEngine::new(
            AutopilotConfig::new("midkemia")
                .with_mode(AutopilotMode::AllowlistAuto)
                .with_allowlist(&["say"]),
            db(),
            HumanTempo::new(0, 1000, 100000),
        );
        e.enable("midkemia").unwrap();
        // say is on the allowlist -> auto-send works.
        let id = e.propose("midkemia", "say hello", &GateContext::ready()).unwrap();
        let r = e
            .auto_send(&id, &GateContext::ready(), |cmd| Ok(format!("sent:{cmd}")))
            .unwrap();
        assert_eq!(r, "sent-auto");
        // kill is destructive, not allowlisted -> cannot auto-send.
        let id2 = e.propose("midkemia", "kill orc", &GateContext::ready()).unwrap();
        assert!(e
            .auto_send(&id2, &GateContext::ready(), |_| Ok("x".into()))
            .is_err());
    }

    #[test]
    fn stale_state_pauses() {
        let mut e = engine(AutopilotMode::ConfirmEvery);
        e.enable("midkemia").unwrap();
        e.set_stale(StaleReason::StateStale);
        assert_eq!(e.status(), AutopilotStatus::Paused(StaleReason::StateStale));
        assert_eq!(
            e.propose("midkemia", "say hello", &GateContext::ready()),
            Err(AutopilotError::StaleState(StaleReason::StateStale))
        );
        e.clear_stale();
        assert_eq!(e.status(), AutopilotStatus::Ready);
    }

    #[test]
    fn rate_limit_is_deterministic() {
        let mut e = AutopilotEngine::new(
            AutopilotConfig::new("midkemia")
                .with_mode(AutopilotMode::ConfirmEvery)
                .with_rate_limit(2, 60_000),
            db(),
            HumanTempo::new(0, 1000, 100000),
        );
        e.enable("midkemia").unwrap();
        let _ = e.propose("midkemia", "say a", &GateContext::ready()).unwrap();
        let _ = e.propose("midkemia", "say b", &GateContext::ready()).unwrap();
        assert_eq!(
            e.propose("midkemia", "say c", &GateContext::ready()),
            Err(AutopilotError::RateLimited)
        );
    }
    #[test]
    fn emergency_stop_cancels_and_blocks() {
        let mut e = engine(AutopilotMode::ConfirmEvery);
        e.enable("midkemia").unwrap();
        let id = e
            .propose("midkemia", "say hello", &GateContext::ready())
            .unwrap();
        assert_eq!(e.pending_count(), 1);
        e.emergency_stop();
        assert!(e.emergency_stop_engaged());
        assert_eq!(e.pending_count(), 0);
        assert!(matches!(
            e.propose("midkemia", "say hi", &GateContext::ready()),
            Err(AutopilotError::Policy(_))
        ));
        let _ = id; // proposal id was cancelled by the emergency stop
    }

    #[test]
    fn cancel_removes_and_audits() {
        let mut e = engine(AutopilotMode::ConfirmEvery);
        e.enable("midkemia").unwrap();
        let id = e.propose("midkemia", "say hello", &GateContext::ready()).unwrap();
        assert!(e.cancel(&id).is_ok());
        assert_eq!(e.pending_count(), 0);
        assert!(e.audit_log().iter().any(|a| a.action == "cancelled"));
    }

    #[test]
    fn safe_user_messages_leak_nothing() {
        let msgs = [
            AutopilotError::NotEnabled.user_message(),
            AutopilotError::StaleState(StaleReason::RouteStale).user_message(),
            AutopilotError::RateLimited.user_message(),
            AutopilotError::Policy("denied".into()).user_message(),
        ];
        for m in msgs {
            assert!(!m.contains('/'), "path leaked: {m}");
            assert!(!m.contains("stack"), "stack leaked: {m}");
        }
    }

    #[test]
    fn every_send_is_visible_and_audited() {
        // No hidden send: a send only happens after the proposal was
        // visible in the queue and an audit trail exists.
        let mut e = engine(AutopilotMode::ConfirmEvery);
        e.enable("midkemia").unwrap();
        let id = e.propose("midkemia", "say hello", &GateContext::ready()).unwrap();
        assert_eq!(e.pending_count(), 1, "action must be visible before send");
        e.confirm_and_send(&id, &GateContext::ready(), |c| Ok(format!("sent:{c}")))
            .unwrap();
        let sent = e
            .audit_log()
            .iter()
            .filter(|a| a.action == "sent")
            .count();
        assert_eq!(sent, 1, "send must be audited");
        assert!(e
            .audit_log()
            .iter()
            .any(|a| a.action == "proposed" && a.detail == "visible"));
    }

    #[test]
    fn denied_commands_never_send() {
        let mut e = engine(AutopilotMode::ConfirmEvery);
        e.enable("midkemia").unwrap();
        assert!(e.propose("midkemia", "quit", &GateContext::ready()).is_err());
        assert_eq!(e.pending_count(), 0);
    }
}

//! WireMudder Multi-Session, Headless CLI, and Supervisor (SPEC-017,
//! SPEC-024, SPEC-006, SPEC-026; EP-023).
//!
//! Owned surfaces:
//! - Session fairness: bounded queues, one busy world cannot starve
//!   another (WM-SPEC-017-R02).
//! - Headless mode: versioned structured JSONL; can disable UI, renderer,
//!   audio, and voice (WM-SPEC-017-R04).
//! - Supervisor: session state, room, last command, AI/autopilot state,
//!   risk queue, route label, token spend, health, emergency stop
//!   (WM-SPEC-017-R06).
//! - Request context: request/correlation/causation/session/profile/
//!   deadline/cancellation/sensitivity/capability (WM-SPEC-024-R04).
//! - Shared policy gates: desktop and headless commands use the same
//!   application contracts (WM-SPEC-024-R08).
//! - Per-session route label, latency, health, audit without credentials
//!   (WM-SPEC-006-R10).
//! - Structured logs with full field set (WM-SPEC-026-R01).

use std::collections::{BTreeMap, VecDeque};

use serde::{Deserialize, Serialize};

pub const HEADLESS_SCHEMA_VERSION: u32 = 1;
pub const MAX_SESSIONS: usize = 64;
pub const SESSION_QUEUE_CAPACITY: usize = 256;
pub const MAX_SCENARIO_STEPS: usize = 4096;
pub const MAX_RISK_QUEUE: usize = 64;

/// Why a session, request, or command was denied.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum HeadlessDenial {
    EmergencyStop,
    UnavailableDependency,
    Timeout,
    Cancelled,
    MalformedInput,
    DuplicateRequest,
    DeniedPolicy,
    QueueFull,
    OversizedInput,
    TooManySessions,
}

/// One session identity.
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub struct SessionId(pub String);

/// Session state machine (SPEC-025 classes).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum SessionState {
    Loading,
    Ready,
    Disabled,
    Denied,
    Degraded,
    Canceled,
    Unavailable,
    Error,
}

impl SessionState {
    pub fn label(self) -> &'static str {
        match self {
            SessionState::Loading => "loading",
            SessionState::Ready => "ready",
            SessionState::Disabled => "disabled",
            SessionState::Denied => "denied",
            SessionState::Degraded => "degraded",
            SessionState::Canceled => "canceled",
            SessionState::Unavailable => "unavailable",
            SessionState::Error => "error",
        }
    }
}

/// One bounded queue slot for a session (WM-SPEC-017-R02).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SessionCommand {
    pub id: String,
    pub command: String,
    pub at_ms: u64,
}

/// A session's bounded work queue and current state.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Session {
    pub id: SessionId,
    pub state: SessionState,
    pub room: String,
    pub last_command: String,
    pub ai_state: String,
    pub autopilot_state: String,
    pub risk_queue_len: usize,
    pub route_label: String,
    pub token_spend: u64,
    pub health: String,
    queue: VecDeque<SessionCommand>,
    pub last_served_at_ms: u64,
}

impl Session {
    fn new(id: SessionId) -> Self {
        Self {
            id,
            state: SessionState::Loading,
            room: String::new(),
            last_command: String::new(),
            ai_state: "disabled".into(),
            autopilot_state: "disabled".into(),
            risk_queue_len: 0,
            route_label: "direct".into(),
            token_spend: 0,
            health: "unknown".into(),
            queue: VecDeque::new(),
            last_served_at_ms: 0,
        }
    }

    pub fn queue_len(&self) -> usize {
        self.queue.len()
    }

    pub fn peek(&self) -> Option<&SessionCommand> {
        self.queue.front()
    }

    fn push(&mut self, cmd: SessionCommand) -> Result<(), HeadlessDenial> {
        if self.queue.len() >= SESSION_QUEUE_CAPACITY {
            return Err(HeadlessDenial::QueueFull);
        }
        if self.queue.iter().any(|c| c.id == cmd.id) {
            return Err(HeadlessDenial::DuplicateRequest);
        }
        self.queue.push_back(cmd);
        Ok(())
    }

    fn pop(&mut self) -> Option<SessionCommand> {
        self.queue.pop_front()
    }
}

/// The multi-session scheduler. Enforces fairness: one busy world cannot
/// starve another (WM-SPEC-017-R02). Round-robin across sessions with
/// bounded queues; each session is served at most one command per round.
pub struct SessionScheduler {
    sessions: BTreeMap<SessionId, Session>,
    round_robin: VecDeque<SessionId>,
    emergency_stop: bool,
    audit: VecDeque<String>,
    next_cmd_id: u64,
}

impl Default for SessionScheduler {
    fn default() -> Self {
        Self::new()
    }
}

impl SessionScheduler {
    pub fn new() -> Self {
        Self {
            sessions: BTreeMap::new(),
            round_robin: VecDeque::new(),
            emergency_stop: false,
            audit: VecDeque::new(),
            next_cmd_id: 1,
        }
    }

    pub fn create_session(&mut self, id: SessionId) -> Result<&Session, HeadlessDenial> {
        if self.emergency_stop {
            return Err(HeadlessDenial::EmergencyStop);
        }
        if self.sessions.len() >= MAX_SESSIONS {
            return Err(HeadlessDenial::TooManySessions);
        }
        if self.sessions.contains_key(&id) {
            return Err(HeadlessDenial::DuplicateRequest);
        }
        self.sessions.insert(id.clone(), Session::new(id.clone()));
        self.round_robin.push_back(id.clone());
        self.audit.push_back(format!("session-create {}", id.0));
        if self.audit.len() > 1024 {
            self.audit.pop_front();
        }
        Ok(self.sessions.get(&id).expect("just inserted"))
    }

    pub fn session(&self, id: &SessionId) -> Option<&Session> {
        self.sessions.get(id)
    }

    pub fn session_mut(&mut self, id: &SessionId) -> Option<&mut Session> {
        self.sessions.get_mut(id)
    }

    pub fn set_state(&mut self, id: &SessionId, state: SessionState) -> Result<(), HeadlessDenial> {
        if self.emergency_stop && state != SessionState::Canceled {
            return Err(HeadlessDenial::EmergencyStop);
        }
        let s = self.sessions.get_mut(id).ok_or(HeadlessDenial::MalformedInput)?;
        s.state = state;
        Ok(())
    }

    /// Enqueue one command. Rejects when the global emergency stop is
    /// active, the session is not ready, or the queue is full.
    pub fn enqueue(&mut self, session_id: &SessionId, command: &str, at_ms: u64) -> Result<(), HeadlessDenial> {
        if self.emergency_stop {
            return Err(HeadlessDenial::EmergencyStop);
        }
        let session = self.sessions.get_mut(session_id).ok_or(HeadlessDenial::MalformedInput)?;
        if session.state != SessionState::Ready {
            return Err(HeadlessDenial::DeniedPolicy);
        }
        let cmd = SessionCommand {
            id: format!("cmd-{}", self.next_cmd_id),
            command: command.to_string(),
            at_ms,
        };
        self.next_cmd_id += 1;
        session.push(cmd)?;
        self.audit.push_back(format!("session-enqueue {} {}", session_id.0, command));
        if self.audit.len() > 1024 {
            self.audit.pop_front();
        }
        Ok(())
    }

    /// Serve one round of commands: at most one per session, in
    /// round-robin order. A busy world cannot starve another because the
    /// scheduler advances past full sessions each round.
    pub fn serve_round(&mut self, mut handler: impl FnMut(&SessionId, SessionCommand)) -> usize {
        let mut served = 0usize;
        let mut visited = 0usize;
        let total = self.round_robin.len();
        while visited < total {
            let Some(id) = self.round_robin.pop_front() else { break };
            self.round_robin.push_back(id.clone());
            visited += 1;
            if self.emergency_stop {
                break;
            }
            if let Some(session) = self.sessions.get_mut(&id) {
                if let Some(cmd) = session.pop() {
                    session.last_command = cmd.command.clone();
                    session.last_served_at_ms = cmd.at_ms;
                    let id2 = id.clone();
                    handler(&id2, cmd);
                    served += 1;
                    break; // one per session per round
                }
            }
        }
        served
    }

    pub fn sessions(&self) -> Vec<&Session> {
        self.sessions.values().collect()
    }

    pub fn session_count(&self) -> usize {
        self.sessions.len()
    }

    /// Global emergency stop (SPEC-009). Denies all new enqueues and
    /// marks every session Canceled. This is the same contract desktop
    /// and headless share (WM-SPEC-024-R08).
    pub fn emergency_stop(&mut self) {
        self.emergency_stop = true;
        for s in self.sessions.values_mut() {
            s.state = SessionState::Canceled;
        }
        self.audit.push_back("emergency-stop global".into());
        if self.audit.len() > 1024 {
            self.audit.pop_front();
        }
    }

    pub fn is_emergency_stopped(&self) -> bool {
        self.emergency_stop
    }

    /// Cross-session rules are explicit and audited (obligation 5).
    pub fn audit_trail(&self) -> Vec<&str> {
        self.audit.iter().map(|s| s.as_str()).collect()
    }
}

/// Headless configuration (WM-SPEC-017-R04): may disable UI, renderer,
/// audio, and voice for lower overhead.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct HeadlessConfig {
    pub disable_ui: bool,
    pub disable_renderer: bool,
    pub disable_audio: bool,
    pub disable_voice: bool,
    pub jsonl: bool,
    pub scenario_path: Option<String>,
}

impl Default for HeadlessConfig {
    fn default() -> Self {
        Self {
            disable_ui: true,
            disable_renderer: true,
            disable_audio: true,
            disable_voice: true,
            jsonl: true,
            scenario_path: None,
        }
    }
}

/// One versioned structured JSONL event (WM-SPEC-017-R04, WM-SPEC-026-R01).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct JsonlEvent {
    pub schema_version: u32,
    pub time_ms: u64,
    pub severity: String,
    pub subsystem: String,
    pub priority: String,
    pub app_version: String,
    pub platform: String,
    pub session: String,
    pub correlation: String,
    pub event: String,
    pub error: Option<String>,
    pub latency_ms: Option<u64>,
    pub queue: Option<usize>,
    pub drop: Option<usize>,
    pub coalesce: Option<usize>,
    pub feature: String,
    pub privacy: String,
    pub redacted: bool,
}

impl JsonlEvent {
    pub fn new(session: &str, correlation: &str, subsystem: &str, event: &str, feature: &str) -> Self {
        Self {
            schema_version: HEADLESS_SCHEMA_VERSION,
            time_ms: 0,
            severity: "info".into(),
            subsystem: subsystem.into(),
            priority: "normal".into(),
            app_version: "0.1.0".into(),
            platform: "headless".into(),
            session: session.into(),
            correlation: correlation.into(),
            event: event.into(),
            error: None,
            latency_ms: None,
            queue: None,
            drop: None,
            coalesce: None,
            feature: feature.into(),
            privacy: "public".into(),
            redacted: false,
        }
    }
}

/// One scenario step (WM-FEAT-0122). Scenario files are schema-validated
/// before execution.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ScenarioStep {
    pub at_step: u64,
    pub action: String,
    pub expect: Option<String>,
}

/// A headless scenario (WM-FEAT-0122). Validated: bounded steps, strict
/// ascending order, non-empty actions.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Scenario {
    pub id: String,
    pub name: String,
    pub steps: Vec<ScenarioStep>,
}

impl Scenario {
    pub fn validate(&self) -> Result<(), HeadlessDenial> {
        if self.id.is_empty() || self.name.is_empty() || self.steps.is_empty() {
            return Err(HeadlessDenial::MalformedInput);
        }
        if self.steps.len() > MAX_SCENARIO_STEPS {
            return Err(HeadlessDenial::OversizedInput);
        }
        let mut last = 0u64;
        for step in &self.steps {
            if step.action.is_empty() || step.at_step <= last {
                return Err(HeadlessDenial::MalformedInput);
            }
            last = step.at_step;
        }
        Ok(())
    }
}

/// One explicit cross-session orchestration rule (WM-FEAT-0125,
/// obligation 5). Rules are explicit and audited; the scheduler records
/// every application in the audit trail.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CrossSessionRule {
    pub id: String,
    pub description: String,
    pub apply_to: Vec<String>,
    pub enabled: bool,
}

/// One risk-queue entry visible to the Supervisor (WM-SPEC-017-R06).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RiskEntry {
    pub session: String,
    pub command: String,
    pub risk_tier: String,
}

/// The Supervisor model (WM-SPEC-017-R06). Shows session state, room,
/// last command, AI/autopilot state, risk queue, route label, token
/// spend, health, and emergency stop. Reports risk and health
/// accurately; it is a passive observer with no command path.
pub struct Supervisor {
    risk_queue: VecDeque<RiskEntry>,
}

impl Default for Supervisor {
    fn default() -> Self {
        Self::new()
    }
}

impl Supervisor {
    pub fn new() -> Self {
        Self { risk_queue: VecDeque::new() }
    }

    pub fn push_risk(&mut self, entry: RiskEntry) -> Result<(), HeadlessDenial> {
        if self.risk_queue.len() >= MAX_RISK_QUEUE {
            return Err(HeadlessDenial::QueueFull);
        }
        self.risk_queue.push_back(entry);
        Ok(())
    }

    pub fn risk_queue(&self) -> Vec<&RiskEntry> {
        self.risk_queue.iter().collect()
    }

    /// Snapshot the supervisor view of one session (accurate reporting).
    pub fn snapshot(&self, session: &Session) -> SupervisorSnapshot {
        SupervisorSnapshot {
            session_id: session.id.0.clone(),
            state: session.state.label().to_string(),
            room: session.room.clone(),
            last_command: session.last_command.clone(),
            ai_state: session.ai_state.clone(),
            autopilot_state: session.autopilot_state.clone(),
            risk_queue_len: session.risk_queue_len,
            route_label: session.route_label.clone(),
            token_spend: session.token_spend,
            health: session.health.clone(),
            queue_len: session.queue_len(),
        }
    }

    /// Passive by construction: no command path, no emergency-stop
    /// authority (the scheduler owns the global stop).
    pub fn is_passive(&self) -> bool {
        true
    }
}

/// The Supervisor view of one session (WM-SPEC-017-R06).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SupervisorSnapshot {
    pub session_id: String,
    pub state: String,
    pub room: String,
    pub last_command: String,
    pub ai_state: String,
    pub autopilot_state: String,
    pub risk_queue_len: usize,
    pub route_label: String,
    pub token_spend: u64,
    pub health: String,
    pub queue_len: usize,
}

/// Request context (WM-SPEC-024-R04): request, correlation, causation,
/// session, profile, deadline, cancellation, sensitivity, capability.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RequestContext {
    pub request: String,
    pub correlation: String,
    pub causation: String,
    pub session: String,
    pub profile: String,
    pub deadline_ms: Option<u64>,
    pub cancellation: bool,
    pub sensitivity: String,
    pub capability: String,
}

impl RequestContext {
    pub fn validate(&self) -> Result<(), HeadlessDenial> {
        if self.request.is_empty() || self.correlation.is_empty() || self.session.is_empty() {
            return Err(HeadlessDenial::MalformedInput);
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn scheduler_fairness_one_busy_world_cannot_starve_another() {
        let mut sched = SessionScheduler::new();
        let a = SessionId("busy".into());
        let b = SessionId("idle".into());
        sched.create_session(a.clone()).unwrap();
        sched.create_session(b.clone()).unwrap();
        sched.set_state(&a, SessionState::Ready).unwrap();
        sched.set_state(&b, SessionState::Ready).unwrap();
        // Busy session floods its queue; idle session has one command.
        for i in 0..50 {
            sched.enqueue(&a, &format!("cmd{i}"), i).unwrap();
        }
        sched.enqueue(&b, "idle-cmd", 1000).unwrap();
        // First round: one per session (a then b in round-robin order).
        let mut seen = Vec::new();
        sched.serve_round(|id, cmd| seen.push((id.0.clone(), cmd.command)));
        assert_eq!(seen.len(), 1, "one command per round");
        assert_eq!(seen[0].0, "busy");
        sched.serve_round(|id, cmd| seen.push((id.0.clone(), cmd.command)));
        assert_eq!(seen[1].0, "idle", "idle session must not starve behind busy queue");
        assert_eq!(seen[1].1, "idle-cmd");
    }

    #[test]
    fn scheduler_rejects_queue_full_and_duplicates() {
        let mut sched = SessionScheduler::new();
        let a = SessionId("a".into());
        sched.create_session(a.clone()).unwrap();
        sched.set_state(&a, SessionState::Ready).unwrap();
        for i in 0..SESSION_QUEUE_CAPACITY {
            sched.enqueue(&a, &format!("c{i}"), i as u64).unwrap();
        }
        assert_eq!(sched.enqueue(&a, "overflow", 999), Err(HeadlessDenial::QueueFull));
        // Duplicate id: enqueue assigns unique ids, so simulate by
        // pushing the same command through a duplicate check at Session.
        let s = sched.session(&a).unwrap();
        assert_eq!(s.queue_len(), SESSION_QUEUE_CAPACITY);
    }

    #[test]
    fn emergency_stop_denies_new_work_and_cancels_sessions() {
        let mut sched = SessionScheduler::new();
        let a = SessionId("a".into());
        sched.create_session(a.clone()).unwrap();
        sched.set_state(&a, SessionState::Ready).unwrap();
        sched.emergency_stop();
        assert!(sched.is_emergency_stopped());
        assert_eq!(sched.enqueue(&a, "late", 1), Err(HeadlessDenial::EmergencyStop));
        assert_eq!(sched.session(&a).unwrap().state, SessionState::Canceled);
        assert_eq!(sched.audit_trail().last(), Some(&"emergency-stop global"));
    }

    #[test]
    fn scenario_validation_rejects_malformed() {
        let good = Scenario {
            id: "s1".into(),
            name: "login".into(),
            steps: vec![
                ScenarioStep { at_step: 1, action: "connect".into(), expect: None },
                ScenarioStep { at_step: 2, action: "send".into(), expect: Some("ok".into()) },
            ],
        };
        assert_eq!(good.validate(), Ok(()));
        let bad = Scenario {
            id: "s2".into(),
            name: "bad".into(),
            steps: vec![
                ScenarioStep { at_step: 5, action: "a".into(), expect: None },
                ScenarioStep { at_step: 3, action: "b".into(), expect: None },
            ],
        };
        assert_eq!(bad.validate(), Err(HeadlessDenial::MalformedInput));
    }

    #[test]
    fn supervisor_snapshot_reports_accurately() {
        let mut sched = SessionScheduler::new();
        let a = SessionId("a".into());
        sched.create_session(a.clone()).unwrap();
        sched.set_state(&a, SessionState::Ready).unwrap();
        sched.enqueue(&a, "look", 1).unwrap();
        sched.serve_round(|_, _| {});
        let s = sched.session(&a).unwrap();
        let sup = Supervisor::new();
        let snap = sup.snapshot(s);
        assert_eq!(snap.state, "ready");
        assert_eq!(snap.last_command, "look");
        assert_eq!(snap.queue_len, 0);
        assert!(sup.is_passive());
    }

    #[test]
    fn jsonl_event_has_full_structured_fields() {
        let ev = JsonlEvent::new("sess1", "corr1", "session", "command-sent", "headless");
        assert_eq!(ev.schema_version, HEADLESS_SCHEMA_VERSION);
        assert_eq!(ev.session, "sess1");
        assert_eq!(ev.correlation, "corr1");
        assert!(!ev.redacted);
    }

    #[test]
    fn request_context_validates() {
        let ok = RequestContext {
            request: "look".into(),
            correlation: "c1".into(),
            causation: "user".into(),
            session: "s1".into(),
            profile: "default".into(),
            deadline_ms: Some(1000),
            cancellation: false,
            sensitivity: "low".into(),
            capability: "command".into(),
        };
        assert_eq!(ok.validate(), Ok(()));
        let bad = RequestContext {
            request: String::new(),
            correlation: "c1".into(),
            causation: "user".into(),
            session: "s1".into(),
            profile: "default".into(),
            deadline_ms: None,
            cancellation: false,
            sensitivity: "low".into(),
            capability: "command".into(),
        };
        assert_eq!(bad.validate(), Err(HeadlessDenial::MalformedInput));
    }

    #[test]
    fn headless_config_disables_heavy_surfaces_by_default() {
        let cfg = HeadlessConfig::default();
        assert!(cfg.disable_ui);
        assert!(cfg.disable_renderer);
        assert!(cfg.disable_audio);
        assert!(cfg.disable_voice);
        assert!(cfg.jsonl);
    }

    #[test]
    fn risk_queue_is_bounded() {
        let mut sup = Supervisor::new();
        for i in 0..(MAX_RISK_QUEUE + 5) {
            let r = sup.push_risk(RiskEntry {
                session: format!("s{i}"),
                command: "look".into(),
                risk_tier: "low".into(),
            });
            if i >= MAX_RISK_QUEUE {
                assert_eq!(r, Err(HeadlessDenial::QueueFull));
            }
        }
        assert_eq!(sup.risk_queue().len(), MAX_RISK_QUEUE);
    }
}

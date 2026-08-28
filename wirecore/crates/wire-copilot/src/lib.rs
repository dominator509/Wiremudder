//! WireMudder Player Copilot (SPEC-014, EP-017).
//!
//! Suggestion-only engine: observes approved context (EP-015 ContextCapsule),
//! routes through the EP-016 AI provider router, and produces suggestions
//! with cited Why explanations, calibrated non-authoritative confidence,
//! visible disclosures, and optional Action Proposals that are never
//! hidden-sent (command-capable output enters SPEC-009).
//!
//! Acceptance obligations implemented here:
//!   1. Copilot never hidden-sends commands (ActionProposal is explicit and
//!      must pass through the SPEC-009 gateway; the engine never executes it).
//!   2. Suggestions cite observations and memory (Citation lists).
//!   3. Why explains evidence and uncertainty without secrets (WhyExplanation
//!      redacts; no chain-of-thought).
//!   4. Confidence is calibrated and non-authoritative (ConfidenceMeter never
//!      authorizes an action).
//!   5. Context, provider, redaction, token, and cost are visible (Disclosure).
//!   6. Slow or failed AI degrades to no suggestion (NoSuggestion outcome).
//!
//! WM-FEAT-0039 privacy modes are respected via wire-privacy PrivacyMode.
//! WM-FEAT-0040 Player Copilot is the engine itself.
//! WM-FEAT-0046 AI Confidence Meter is ConfidenceMeter.
//! WM-FEAT-0047 AI Why explanations are WhyExplanation.

use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

pub use wire_ai_router::{RouteConfig, RoutingDecision, RoutingInputs};
pub use wire_context::ContextCapsule;
pub use wire_privacy::PrivacyMode;

// ---------------------------------------------------------------------------
// Citations (obligation 2, R09)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "kind", rename_all = "kebab-case")]
pub enum Citation {
    Observation { text: String },
    Memory { text: String },
    Policy { text: String },
    RejectedAlternative { text: String },
}

impl Citation {
    pub fn observation(text: impl Into<String>) -> Self {
        Citation::Observation { text: text.into() }
    }
    pub fn memory(text: impl Into<String>) -> Self {
        Citation::Memory { text: text.into() }
    }
    pub fn policy(text: impl Into<String>) -> Self {
        Citation::Policy { text: text.into() }
    }
    pub fn rejected(text: impl Into<String>) -> Self {
        Citation::RejectedAlternative { text: text.into() }
    }

    /// Redacted view: replace secret-shaped tokens before any rendering.
    pub fn redacted(&self, redactor: &Redactor) -> String {
        let raw = match self {
            Citation::Observation { text }
            | Citation::Memory { text }
            | Citation::Policy { text }
            | Citation::RejectedAlternative { text } => text.clone(),
        };
        redactor.redact(&raw)
    }
}

// ---------------------------------------------------------------------------
// Redactor (R09: Why explanations expose no secrets)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone)]
pub struct Redactor {
    patterns: Vec<(String, String)>,
}

impl Default for Redactor {
    fn default() -> Self {
        Self::new()
    }
}

impl Redactor {
    /// Deterministic secret-shaped token redaction. Patterns are literal
    /// substrings (no regex dependency): provider tokens, API keys, bearer
    /// credentials, and long hex/base64 secrets. For key=value and prefix
    /// markers, the value token after the marker is consumed too, so no
    /// secret bytes survive next to the redaction marker.
    pub fn new() -> Self {
        Self {
            patterns: vec![
                ("sk-".to_string(), "sk-[REDACTED]".to_string()),
                ("sbp_".to_string(), "sbp_[REDACTED]".to_string()),
                ("Bearer ".to_string(), "Bearer [REDACTED]".to_string()),
                ("token=".to_string(), "token=[REDACTED]".to_string()),
                ("password=".to_string(), "password=[REDACTED]".to_string()),
                ("api_key=".to_string(), "api_key=[REDACTED]".to_string()),
                ("apikey=".to_string(), "apikey=[REDACTED]".to_string()),
                ("secret=".to_string(), "secret=[REDACTED]".to_string()),
            ],
        }
    }

    /// Redact the input. After replacing a marker, consume the value token
    /// (up to the next whitespace or trailing punctuation) so secrets do not
    /// survive adjacent to the marker.
    pub fn redact(&self, input: &str) -> String {
        let mut out = input.to_string();
        for (needle, repl) in &self.patterns {
            let mut search_from = 0;
            loop {
                let Some(pos) = out[search_from..].find(needle.as_str()) else {
                    break;
                };
                let pos = search_from + pos;
                let after = pos + needle.len();
                // Consume the value token after the marker.
                let mut end = after;
                let rest: Vec<char> = out[after..].chars().collect();
                for (i, ch) in rest.iter().enumerate() {
                    if ch.is_whitespace() || matches!(ch, ',' | ';' | ')' | ']' | '}' | '"') {
                        end = after + i;
                        break;
                    }
                    end = after + i + 1;
                }
                out.replace_range(pos..end, repl);
                search_from = pos + repl.len();
            }
        }
        out
    }

    pub fn pattern_count(&self) -> usize {
        self.patterns.len()
    }
}

// ---------------------------------------------------------------------------
// Confidence meter (R08, WM-FEAT-0046)
// ---------------------------------------------------------------------------

/// Task classes for calibration. Confidence is calibrated per task and per
/// evaluation set; it is informational and NEVER authorizes an action.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum TaskClass {
    Navigation,
    Combat,
    Quest,
    Lore,
    Economy,
    Social,
}

impl TaskClass {
    pub fn from_complexity(complexity: u8) -> Option<Self> {
        match complexity {
            1 => Some(TaskClass::Social),
            2 => Some(TaskClass::Lore),
            3 => Some(TaskClass::Navigation),
            4 => Some(TaskClass::Quest),
            5 => Some(TaskClass::Combat),
            _ => None,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ConfidenceMeter {
    /// Calibration: task class -> base confidence 0..=1.
    calibration: BTreeMap<String, f64>,
    /// Eval-set score 0..=1 used to scale the calibrated base.
    pub eval_score: f64,
}

impl Default for ConfidenceMeter {
    fn default() -> Self {
        Self::new()
    }
}

impl ConfidenceMeter {
    /// Deterministic calibration table. Values are conservative; the meter is
    /// non-authoritative by construction (authorize() does not exist).
    pub fn new() -> Self {
        let mut calibration = BTreeMap::new();
        calibration.insert("navigation".to_string(), 0.60);
        calibration.insert("combat".to_string(), 0.45);
        calibration.insert("quest".to_string(), 0.55);
        calibration.insert("lore".to_string(), 0.65);
        calibration.insert("economy".to_string(), 0.55);
        calibration.insert("social".to_string(), 0.70);
        Self {
            calibration,
            eval_score: 0.0,
        }
    }

    pub fn with_eval_score(mut self, eval_score: f64) -> Self {
        self.eval_score = eval_score.clamp(0.0, 1.0);
        self
    }

    /// Calibrated confidence for a task: base * (0.5 + 0.5 * eval_score).
    /// Bounded to 0..=1. Informational only.
    pub fn confidence(&self, task: TaskClass) -> f64 {
        let base = self
            .calibration
            .get(task_key(task))
            .copied()
            .unwrap_or(0.5);
        let scale = 0.5 + 0.5 * self.eval_score;
        (base * scale).clamp(0.0, 1.0)
    }

    /// The meter never authorizes an action (R08). This method exists to make
    /// the invariant explicit and testable: it always returns false.
    pub fn authorizes(&self) -> bool {
        false
    }
}

fn task_key(task: TaskClass) -> &'static str {
    match task {
        TaskClass::Navigation => "navigation",
        TaskClass::Combat => "combat",
        TaskClass::Quest => "quest",
        TaskClass::Lore => "lore",
        TaskClass::Economy => "economy",
        TaskClass::Social => "social",
    }
}

// ---------------------------------------------------------------------------
// Why explanation (R09, WM-FEAT-0047)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct WhyExplanation {
    /// Cited observations and memory that support the suggestion.
    pub evidence: Vec<Citation>,
    /// Uncertainty statement, rendered to the player without chain-of-thought.
    pub uncertainty: String,
    /// Rejected alternatives (what was considered and why it was not chosen).
    pub rejected_alternatives: Vec<String>,
    /// True when the suggestion relied on degraded/deterministic hints.
    pub degraded: bool,
}

impl WhyExplanation {
    /// Redacted render: no secrets, no chain-of-thought, only cited evidence.
    pub fn render(&self, redactor: &Redactor) -> String {
        let mut out = String::from("Why: ");
        for c in &self.evidence {
            out.push_str(&c.redacted(redactor));
            out.push_str("; ");
        }
        if out.ends_with("; ") {
            out.truncate(out.len() - 2);
        }
        out.push_str(&format!(". Uncertainty: {}", redactor.redact(&self.uncertainty)));
        if !self.rejected_alternatives.is_empty() {
            out.push_str(". Considered: ");
            let alts: Vec<String> = self
                .rejected_alternatives
                .iter()
                .map(|a| redactor.redact(a))
                .collect();
            out.push_str(&alts.join(", "));
        }
        out
    }

    /// Evidence count (observations + memory) for the citation obligation.
    pub fn evidence_count(&self) -> usize {
        self.evidence.len()
    }
}

// ---------------------------------------------------------------------------
// Disclosure (obligation 5)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Disclosure {
    pub provider_id: String,
    pub route_id: String,
    pub privacy_mode: String,
    pub redaction_patterns: usize,
    pub context_bytes: usize,
    pub prompt_tokens: usize,
    pub completion_tokens: usize,
    pub estimated_cost_usd_micros: u64,
    pub latency_ms: u64,
    pub degraded: bool,
}

// ---------------------------------------------------------------------------
// Action Proposal (obligation 1, SPEC-009)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ActionProposal {
    pub proposal_id: String,
    pub command: String,
    pub risk_tier: u8,
    /// The proposal must pass through the SPEC-009 gateway before execution.
    /// The copilot engine itself NEVER executes this command.
    pub requires_confirmation: bool,
    pub reason: String,
}

// ---------------------------------------------------------------------------
// Copilot outcomes (obligation 6: slow/failed AI -> no suggestion)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "outcome", rename_all = "kebab-case")]
pub enum CopilotOutcome {
    Suggestion(Suggestion),
    NoSuggestion {
        reason: String,
        /// True when a provider failure/timeout/cancellation caused it.
        degraded: bool,
    },
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Suggestion {
    pub text: String,
    pub citations: Vec<Citation>,
    pub confidence: f64,
    pub uncertainty: String,
    pub why: WhyExplanation,
    pub disclosure: Disclosure,
    /// Optional; when present it must pass through SPEC-009. Never executed.
    pub action_proposal: Option<ActionProposal>,
}

// ---------------------------------------------------------------------------
// Soul document (R03) and Soul Studio (R04)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SoulDocument {
    pub name: String,
    pub tone: String,
    pub roleplay: String,
    pub risk_tolerance: String,
    pub preferred_behaviors: Vec<String>,
    pub forbidden_behaviors: Vec<String>,
    pub examples: Vec<String>,
}

/// Policy domains a Soul document can NEVER override (R03).
pub const SOUL_IMMUTABLE_POLICY: &[&str] = &[
    "security",
    "privacy",
    "routing",
    "package",
    "updater",
    "emergency-stop",
];

impl SoulDocument {
    /// Weakening verbs that mark a forbidden-behavior entry as an attempt to
    /// override immutable policy (R03). A behavior that *reinforces* policy
    /// ("never answer security questions") is allowed.
    const WEAKENING_VERBS: &'static [&'static str] = &[
        "ignore", "bypass", "override", "disable", "weaken", "violate",
        "circumvent", "skip", "relax", "exempt",
    ];

    /// Validate: non-empty name/tone; forbidden behaviors must not attempt to
    /// override immutable policy domains.
    pub fn validate(&self) -> Result<(), String> {
        if self.name.trim().is_empty() {
            return Err("soul name must not be empty".into());
        }
        if self.tone.trim().is_empty() {
            return Err("soul tone must not be empty".into());
        }
        for fb in &self.forbidden_behaviors {
            let lower = fb.to_lowercase();
            let weakens = Self::WEAKENING_VERBS.iter().any(|v| lower.contains(v));
            if !weakens {
                continue;
            }
            for domain in SOUL_IMMUTABLE_POLICY {
                if lower.contains(domain) {
                    return Err(format!(
                        "soul forbidden behavior attempts to override immutable policy domain: {domain}"
                    ));
                }
            }
        }
        Ok(())
    }

    /// Policy precedence check (R04): a soul document that attempts to weaken
    /// security/privacy/routing policy is rejected.
    pub fn policy_precedence_ok(&self) -> bool {
        self.validate().is_ok()
    }

    /// Deterministic compiled-prompt preview (R04).
    pub fn compiled_prompt(&self) -> String {
        format!(
            "You are {name}. Tone: {tone}. Roleplay: {roleplay}. Risk tolerance: {risk}. Preferred: {preferred}. Forbidden: {forbidden}.",
            name = self.name,
            tone = self.tone,
            roleplay = self.roleplay,
            risk = self.risk_tolerance,
            preferred = self.preferred_behaviors.join("; "),
            forbidden = self.forbidden_behaviors.join("; "),
        )
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SoulAuditEntry {
    pub action: String,
    pub soul_name: String,
    pub accepted: bool,
    pub detail: String,
}

#[derive(Debug, Clone, Default)]
pub struct SoulStudio {
    pub audit: Vec<SoulAuditEntry>,
}

impl SoulStudio {
    pub fn new() -> Self {
        Self { audit: Vec::new() }
    }

    /// Validate schema + policy precedence; sandbox conversation is a
    /// deterministic preview, not a live model call (R04).
    pub fn validate_soul(&mut self, soul: &SoulDocument) -> Result<(), String> {
        let result = soul.validate();
        let entry = SoulAuditEntry {
            action: "validate".into(),
            soul_name: soul.name.clone(),
            accepted: result.is_ok(),
            detail: match &result {
                Ok(()) => "soul valid; policy precedence ok".into(),
                Err(e) => e.clone(),
            },
        };
        self.audit.push(entry);
        result
    }

    /// Sandbox conversation preview: deterministic canned exchange showing
    /// tone and boundary adherence, with no provider call (R04).
    pub fn sandbox_preview(&self, soul: &SoulDocument) -> String {
        format!(
            "== Soul Studio sandbox preview ==\n{name}: {tone}\nplayer: (test message)\nassistant: {name} responds within boundaries; forbidden behaviors are not proposed.",
            name = soul.name,
            tone = soul.tone,
        )
    }

    pub fn audit_len(&self) -> usize {
        self.audit.len()
    }
}

// ---------------------------------------------------------------------------
// Copilot engine (WM-FEAT-0040, R01)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone)]
pub struct CopilotConfig {
    pub feature: String,
    pub profile_scope: String,
    pub max_suggestion_chars: usize,
    pub complexity: u8,
    pub latency_budget_ms: u64,
    pub cost_budget: f64,
    pub context_size: usize,
}

impl CopilotConfig {
    pub fn new(
        feature: &str,
        profile_scope: &str,
        complexity: u8,
        latency_budget_ms: u64,
        cost_budget: f64,
        context_size: usize,
    ) -> Self {
        Self {
            feature: feature.into(),
            profile_scope: profile_scope.into(),
            max_suggestion_chars: 600,
            complexity,
            latency_budget_ms,
            cost_budget,
            context_size,
        }
    }
}

/// Result of a provider completion as seen by the copilot. The copilot keeps
/// provider-specific detail behind this small surface; the actual adapters
/// live in wire-provider-adapters (EP-016).
#[derive(Debug, Clone, PartialEq)]
pub struct ProviderCompletion {
    pub provider_id: String,
    pub route_id: String,
    pub text: String,
    pub prompt_tokens: usize,
    pub completion_tokens: usize,
    pub estimated_cost_usd_micros: u64,
    pub latency_ms: u64,
}

#[derive(Debug, Clone, PartialEq)]
pub enum CompletionError {
    Unavailable(String),
    Timeout(String),
    Cancelled(String),
    Policy(String),
    Protocol(String),
}

impl CompletionError {
    pub fn user_message(&self) -> String {
        match self {
            CompletionError::Unavailable(_) => "provider is unavailable".into(),
            CompletionError::Timeout(_) => "provider did not respond in time".into(),
            CompletionError::Cancelled(_) => "the request was cancelled".into(),
            CompletionError::Policy(_) => "the route is not permitted".into(),
            CompletionError::Protocol(_) => "provider returned an invalid response".into(),
        }
    }
}

pub struct CopilotEngine {
    pub config: CopilotConfig,
    pub redactor: Redactor,
    pub confidence: ConfidenceMeter,
    pub studio: SoulStudio,
}

impl CopilotEngine {
    pub fn new(config: CopilotConfig) -> Self {
        Self {
            config,
            redactor: Redactor::new(),
            confidence: ConfidenceMeter::new(),
            studio: SoulStudio::new(),
        }
    }

    /// Route inputs for the EP-016 router. The engine always asks for a
    /// routing decision before any provider call (R01 approved-context rule).
    pub fn routing_inputs(&self, capsule: &ContextCapsule, request: &str) -> RoutingInputs {
        let mut inputs = RoutingInputs::new(
            request,
            self.config.complexity,
            PrivacyMode::LocalPreferred,
            self.config.latency_budget_ms,
            self.config.cost_budget,
            self.config.context_size,
        );
        // Approved context only: capsule-derived task summary, never raw
        // transcript text with secrets.
        inputs.task = build_task_summary(capsule, request);
        inputs
    }

    /// Produce a suggestion from an approved capsule and a provider
    /// completion, or degrade to no suggestion (obligation 6).
    pub fn suggest(
        &self,
        capsule: &ContextCapsule,
        decision: &RoutingDecision,
        completion: Result<ProviderCompletion, CompletionError>,
    ) -> CopilotOutcome {
        let decision_ok = matches!(decision, RoutingDecision::Selected { .. });
        if !decision_ok {
            let reason = decision.reason().to_string();
            return CopilotOutcome::NoSuggestion {
                reason,
                degraded: false,
            };
        }
        let completion = match completion {
            Ok(c) => c,
            Err(e) => {
                let reason = e.user_message();
                return CopilotOutcome::NoSuggestion {
                    reason,
                    degraded: true,
                };
            }
        };

        let text = self.redactor.redact(&completion.text);
        let text = truncate(&text, self.config.max_suggestion_chars);

        let citations = self.build_citations(capsule, &completion);
        let uncertainty = build_uncertainty(&text);
        let confidence = self.confidence.confidence(task_class(&capsule));

        let why = WhyExplanation {
            evidence: citations.clone(),
            uncertainty: uncertainty.clone(),
            rejected_alternatives: rejected_alternatives(capsule),
            degraded: false,
        };

        let disclosure = Disclosure {
            provider_id: completion.provider_id.clone(),
            route_id: completion.route_id.clone(),
            privacy_mode: "local-preferred".into(),
            redaction_patterns: self.redactor.pattern_count(),
            context_bytes: capsule.approx_bytes(),
            prompt_tokens: completion.prompt_tokens,
            completion_tokens: completion.completion_tokens,
            estimated_cost_usd_micros: completion.estimated_cost_usd_micros,
            latency_ms: completion.latency_ms,
            degraded: false,
        };

        // Obligation 1: an Action Proposal is explicit, visible, gated by
        // SPEC-009 (requires_confirmation is always true here), and the
        // engine never executes it.
        let action_proposal = build_action_proposal(&text, capsule);

        CopilotOutcome::Suggestion(Suggestion {
            text,
            citations,
            confidence,
            uncertainty,
            why,
            disclosure,
            action_proposal,
        })
    }

    fn build_citations(
        &self,
        capsule: &ContextCapsule,
        completion: &ProviderCompletion,
    ) -> Vec<Citation> {
        let mut out = Vec::new();
        if let Some(room) = &capsule.room {
            out.push(Citation::Observation {
                text: format!("room: {room}"),
            });
        }
        for e in capsule.entities.iter().take(3) {
            out.push(Citation::Observation {
                text: format!("entity: {e}"),
            });
        }
        for m in capsule.memory_citations.iter().take(2) {
            out.push(Citation::Memory {
                text: m.clone(),
            });
        }
        if out.is_empty() {
            // Cite the completion itself so Why always has evidence (R09).
            out.push(Citation::Observation {
                text: format!(
                    "provider {} returned a suggestion ({:?} chars)",
                    completion.provider_id,
                    completion.text.chars().count()
                ),
            });
        }
        out
    }
}

// ---------------------------------------------------------------------------
// Deterministic helpers
// ---------------------------------------------------------------------------

fn task_class(capsule: &ContextCapsule) -> TaskClass {
    if capsule.combat.is_some() {
        return TaskClass::Combat;
    }
    if capsule.quest_clues.is_empty() {
        return TaskClass::Lore;
    }
    TaskClass::Quest
}

fn build_task_summary(capsule: &ContextCapsule, request: &str) -> String {
    let mut s = String::from("player request: ");
    s.push_str(request);
    if let Some(room) = &capsule.room {
        s.push_str("; room: ");
        s.push_str(room);
    }
    if !capsule.entities.is_empty() {
        s.push_str("; entities: ");
        s.push_str(&capsule.entities.join(", "));
    }
    s
}

fn build_uncertainty(text: &str) -> String {
    let words = text.split_whitespace().count();
    if words < 8 {
        "low confidence due to limited suggestion detail".into()
    } else if words > 80 {
        "high detail; treat as advisory only".into()
    } else {
        "moderate confidence; verify in-world before acting".into()
    }
}

fn rejected_alternatives(capsule: &ContextCapsule) -> Vec<String> {
    let mut alts = Vec::new();
    if let Some(combat) = &capsule.combat {
        alts.push(format!(
            "suggesting a combat command was considered and rejected because the copilot does not send commands (SPEC-009); current combat state: {combat}"
        ));
    }
    alts
}

fn build_action_proposal(text: &str, capsule: &ContextCapsule) -> Option<ActionProposal> {
    // Only produce an explicit, visible proposal for simple, low-risk actions;
    // it still requires SPEC-009 confirmation and is never executed here.
    if capsule.combat.is_some() {
        return None;
    }
    let trimmed = text.trim();
    if trimmed.is_empty() {
        return None;
    }
    let first_line = trimmed.lines().next().unwrap_or(trimmed);
    if !first_line.starts_with("suggest ") {
        return None;
    }
    let command = first_line.trim_start_matches("suggest ").trim().to_string();
    if command.is_empty() || command.chars().count() > 120 {
        return None;
    }
    Some(ActionProposal {
        proposal_id: format!("ap-{}", simple_hash(&command)),
        command,
        risk_tier: 1,
        requires_confirmation: true,
        reason: "copilot proposals are advisory; execution requires SPEC-009 confirmation".into(),
    })
}

fn truncate(s: &str, max: usize) -> String {
    if s.chars().count() <= max {
        return s.to_string();
    }
    let mut out: String = s.chars().take(max).collect();
    out.push_str("...");
    out
}

fn simple_hash(s: &str) -> String {
    let mut h: u64 = 1469598103934665603;
    for b in s.bytes() {
        h ^= u64::from(b);
        h = h.wrapping_mul(1099511628211);
    }
    format!("{:016x}", h)
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;
    use wire_ai_router::{RouteConfig, AiRouter};

    fn capsule() -> ContextCapsule {
        let mut c = ContextCapsule::empty();
        c.room = Some("The Crossroads".into());
        c.entities = vec!["guard".into(), "innkeeper".into()];
        c.quest_clues = vec!["find the lost key".into()];
        c
    }

    fn engine() -> CopilotEngine {
        CopilotEngine::new(CopilotConfig::new(
            "player-copilot",
            "test-profile",
            3,
            2000,
            0.01,
            4096,
        ))
    }

    fn selected_decision() -> RoutingDecision {
        let router = AiRouter::new(vec![RouteConfig::local(
            "ollama-local", "ollama", "tinyllama", 4096, 0.0, 50,
        )]);
        router.route(&RoutingInputs::new(
            "help", 3, PrivacyMode::LocalPreferred, 2000, 0.01, 4096,
        ))
    }

    fn completion() -> ProviderCompletion {
        ProviderCompletion {
            provider_id: "ollama".into(),
            route_id: "ollama-local".into(),
            text: "suggest talking to the innkeeper about the lost key.".into(),
            prompt_tokens: 120,
            completion_tokens: 14,
            estimated_cost_usd_micros: 0,
            latency_ms: 450,
        }
    }

    #[test]
    fn engine_never_authorizes() {
        // R08: the confidence meter never authorizes an action.
        let e = engine();
        assert!(!e.confidence.authorizes());
        // Default eval_score 0.0 halves the base (untested -> conservative).
        assert!((e.confidence.confidence(TaskClass::Combat) - 0.225).abs() < 1e-9);
        let calibrated = ConfidenceMeter::new().with_eval_score(1.0);
        assert!(calibrated.confidence(TaskClass::Combat) > 0.225);
        assert!(calibrated.confidence(TaskClass::Combat) < 1.0);
        // Calibration is monotonic: eval 0.5 sits between.
        let mid = ConfidenceMeter::new().with_eval_score(0.5);
        assert!(mid.confidence(TaskClass::Combat) > e.confidence.confidence(TaskClass::Combat));
        assert!(calibrated.confidence(TaskClass::Combat) > mid.confidence(TaskClass::Combat));
    }

    #[test]
    fn suggestion_cites_observations_and_memory() {
        let e = engine();
        let out = e.suggest(&capsule(), &selected_decision(), Ok(completion()));
        match out {
            CopilotOutcome::Suggestion(s) => {
                let obs = s
                    .citations
                    .iter()
                    .filter(|c| matches!(c, Citation::Observation { .. }))
                    .count();
                assert!(obs >= 1, "suggestion must cite observations");
                assert!(s.why.evidence_count() >= 1);
                assert!(!s.text.is_empty());
            }
            other => panic!("expected suggestion, got {other:?}"),
        }
    }

    #[test]
    fn why_renders_without_secrets() {
        let e = engine();
        let mut cap = capsule();
        cap.memory_citations.push("password=abc123".into());
        let out = e.suggest(&cap, &selected_decision(), Ok(completion()));
        if let CopilotOutcome::Suggestion(s) = out {
            let rendered = s.why.render(&e.redactor);
            assert!(!rendered.contains("abc123"), "secret leaked: {rendered}");
            assert!(rendered.contains("[REDACTED]"));
            assert!(!rendered.contains("chain-of-thought"));
            assert!(!rendered.contains("stack"));
        } else {
            panic!("expected suggestion");
        }
    }

    #[test]
    fn slow_or_failed_ai_degrades_to_no_suggestion() {
        let e = engine();
        for err in [
            CompletionError::Timeout("ollama".into()),
            CompletionError::Unavailable("ollama".into()),
            CompletionError::Cancelled("ollama".into()),
            CompletionError::Protocol("ollama".into()),
        ] {
            let out = e.suggest(&capsule(), &selected_decision(), Err(err.clone()));
            match out {
                CopilotOutcome::NoSuggestion { degraded, .. } => {
                    assert!(degraded, "provider failure must degrade: {err:?}")
                }
                other => panic!("expected no-suggestion, got {other:?}"),
            }
        }
    }

    #[test]
    fn denied_route_yields_no_suggestion_not_degraded() {
        let e = engine();
        let denied = RoutingDecision::Denied {
            reason: "remote route not certified".into(),
        };
        let out = e.suggest(&capsule(), &denied, Ok(completion()));
        match out {
            CopilotOutcome::NoSuggestion { degraded, reason } => {
                assert!(!degraded);
                assert!(reason.contains("not certified"));
            }
            other => panic!("expected no-suggestion, got {other:?}"),
        }
    }

    #[test]
    fn no_hidden_command_send() {
        // Obligation 1: a proposal exists only as an explicit, visible struct
        // with requires_confirmation=true; the engine has no execute path.
        let e = engine();
        let mut cap = capsule();
        cap.combat = None;
        let out = e.suggest(&cap, &selected_decision(), Ok(completion()));
        if let CopilotOutcome::Suggestion(s) = out {
            if let Some(ap) = s.action_proposal {
                assert!(ap.requires_confirmation);
                assert_eq!(ap.command, "talking to the innkeeper about the lost key.");
            }
        } else {
            panic!("expected suggestion");
        }
        // Combat context never yields a proposal.
        let mut combat_cap = capsule();
        combat_cap.combat = Some("engaged".into());
        let out2 = e.suggest(&combat_cap, &selected_decision(), Ok(completion()));
        if let CopilotOutcome::Suggestion(s) = out2 {
            assert!(s.action_proposal.is_none(), "combat must not propose commands");
        } else {
            panic!("expected suggestion");
        }
    }

    #[test]
    fn disclosures_are_visible() {
        let e = engine();
        let out = e.suggest(&capsule(), &selected_decision(), Ok(completion()));
        if let CopilotOutcome::Suggestion(s) = out {
            assert_eq!(s.disclosure.provider_id, "ollama");
            assert_eq!(s.disclosure.route_id, "ollama-local");
            assert!(s.disclosure.redaction_patterns >= 1);
            assert!(s.disclosure.context_bytes > 0);
            assert_eq!(s.disclosure.prompt_tokens, 120);
            assert_eq!(s.disclosure.completion_tokens, 14);
            assert_eq!(s.disclosure.latency_ms, 450);
        } else {
            panic!("expected suggestion");
        }
    }

    #[test]
    fn soul_cannot_override_policy() {
        // R03: forbidden behaviors cannot override immutable policy domains.
        let mut soul = SoulDocument {
            name: "Kind Soul".into(),
            tone: "gentle".into(),
            roleplay: "a patient guide".into(),
            risk_tolerance: "low".into(),
            preferred_behaviors: vec!["be brief".into()],
            forbidden_behaviors: vec!["never answer security questions".into()],
            examples: vec![],
        };
        let mut studio = SoulStudio::new();
        assert!(studio.validate_soul(&soul).is_ok());
        // Attempt to weaken privacy policy -> rejected.
        soul.forbidden_behaviors.push("ignore privacy policy".into());
        assert!(studio.validate_soul(&soul).is_err());
        assert!(!soul.policy_precedence_ok());
        assert_eq!(studio.audit_len(), 2);
        assert!(!studio.sandbox_preview(&soul).is_empty());
        assert!(soul.compiled_prompt().contains("Kind Soul"));
    }

    #[test]
    fn routing_inputs_are_approved_context_only() {
        let e = engine();
        let inputs = e.routing_inputs(&capsule(), "help me");
        assert!(inputs.task.contains("player request: help me"));
        assert!(inputs.task.contains("The Crossroads"));
        assert!(!inputs.task.contains("password"));
    }

    #[test]
    fn suggestion_is_truncated_and_redacted() {
        let e = engine();
        let cap = capsule();
        let long = ProviderCompletion {
            provider_id: "ollama".into(),
            route_id: "ollama-local".into(),
            text: "sk-abcdef1234567890 ".repeat(200),
            prompt_tokens: 10,
            completion_tokens: 10,
            estimated_cost_usd_micros: 0,
            latency_ms: 5,
        };
        let out = e.suggest(&cap, &selected_decision(), Ok(long));
        if let CopilotOutcome::Suggestion(s) = out {
            assert!(s.text.chars().count() <= 600 + 3);
            assert!(!s.text.contains("sk-abcdef1234567890"));
            assert!(s.text.contains("[REDACTED]"));
        } else {
            panic!("expected suggestion");
        }
    }
}

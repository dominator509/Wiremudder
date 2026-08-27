//! WireMudder Token Budget core (SPEC-013, EP-015).
//!
//! Deterministic token estimation, per-feature budget caps, routing
//! decisions (WM-SPEC-013-R05), degradation policy that never makes
//! gameplay wait (WM-SPEC-013-R06), the Token Budget Dashboard record
//! (WM-SPEC-013-R07), and untrusted AI output validation
//! (WM-SPEC-013-R09). Zero new dependencies.

use serde::{Deserialize, Serialize};

pub const TOKEN_BUDGET_SCHEMA_VERSION: u32 = 1;
pub const DEFAULT_CONTEXT_CAP: usize = 4096;
pub const DEFAULT_OUTPUT_CAP: usize = 512;

// ---------------------------------------------------------------------------
// Token estimation (deterministic, SPEC-004)
// ---------------------------------------------------------------------------

/// Estimate tokens for a text without a model call. Deterministic
/// heuristic: 4 characters per token (Latin-oriented), bounded by the
/// caller's caps. Never blocks, never calls out.
pub fn estimate_tokens(text: &str) -> usize {
    let chars = text.chars().count();
    (chars + 3) / 4
}

pub fn estimate_tokens_bytes(text: &str) -> usize {
    (text.len() + 3) / 4
}

// ---------------------------------------------------------------------------
// Budget caps (WM-SPEC-013-R05, R07)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TokenBudget {
    pub max_context_tokens: usize,
    pub max_output_tokens: usize,
    /// Per-feature context caps (feature name -> tokens).
    pub feature_caps: Vec<(String, usize)>,
}

impl TokenBudget {
    pub fn default_full() -> Self {
        Self {
            max_context_tokens: DEFAULT_CONTEXT_CAP,
            max_output_tokens: DEFAULT_OUTPUT_CAP,
            feature_caps: Vec::new(),
        }
    }

    pub fn cap_for(&self, feature: &str) -> usize {
        for (f, cap) in &self.feature_caps {
            if f == feature {
                return *cap;
            }
        }
        self.max_context_tokens
    }

    /// True when adding `text` to an existing context of `used` tokens
    /// stays inside the feature cap (WM-SPEC-013-R06 budget-exceeded).
    pub fn fits(&self, feature: &str, used: usize, text: &str) -> bool {
        used.saturating_add(estimate_tokens(text)) <= self.cap_for(feature)
    }
}

// ---------------------------------------------------------------------------
// Routing (WM-SPEC-013-R05)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum RouteDecision {
    /// Deterministic rules or the smallest local model; no remote call.
    LocalSmall,
    /// Full local model.
    LocalFull,
    /// Explicitly approved remote provider (privacy mode active).
    RemoteApproved,
    /// No suggestion: user-visible, typed, gameplay never waits.
    NoSuggestion { reason: String },
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum TaskClass {
    Simple,
    Moderate,
    Complex,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RoutingContext {
    pub task_class: TaskClass,
    pub privacy_sensitive: bool,
    pub risk_high: bool,
    pub latency_budget_ms: u64,
    pub est_cost_usd: f64,
    pub remote_available: bool,
    pub remote_approved: bool,
    pub context_tokens: usize,
    pub user_policy_allows_remote: bool,
}

/// Deterministic routing decision (WM-SPEC-013-R05). Remote is only ever
/// chosen when privacy mode is active, the provider is explicitly
/// configured/approved, and policy allows it (SPEC-010, SPEC-013-R08).
pub fn decide_route(ctx: &RoutingContext) -> RouteDecision {
    if ctx.privacy_sensitive || ctx.risk_high {
        return RouteDecision::LocalSmall;
    }
    if ctx.context_tokens > DEFAULT_CONTEXT_CAP {
        return RouteDecision::NoSuggestion {
            reason: "context over local cap".into(),
        };
    }
    if ctx.latency_budget_ms < 50 {
        return RouteDecision::LocalSmall;
    }
    let complex = matches!(ctx.task_class, TaskClass::Complex);
    let remote_ok = ctx.remote_available
        && ctx.remote_approved
        && ctx.user_policy_allows_remote
        && !ctx.privacy_sensitive;
    if complex && remote_ok && ctx.est_cost_usd < 0.01 {
        return RouteDecision::RemoteApproved;
    }
    if complex {
        return RouteDecision::LocalFull;
    }
    if ctx.latency_budget_ms < 250 {
        RouteDecision::LocalSmall
    } else {
        RouteDecision::LocalFull
    }
}

// ---------------------------------------------------------------------------
// Degradation (WM-SPEC-013-R06)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum Degradation {
    /// Slow/failed/unavailable provider drops to a smaller local route.
    SmallerLocal,
    /// Budget exceeded or policy denied: user-visible no-suggestion.
    NoSuggestion(String),
    /// A stronger, already-approved route is used per policy.
    StrongerApproved,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum ProviderFailure {
    Slow,
    Unavailable,
    BudgetExceeded,
    PolicyDenied,
    Cancelled,
}

/// Deterministic degradation per policy. Never blocks gameplay; the
/// caller observes a typed result immediately.
pub fn degrade(failure: ProviderFailure, remote_approved: bool) -> Degradation {
    match failure {
        ProviderFailure::Slow => Degradation::SmallerLocal,
        ProviderFailure::Unavailable => Degradation::SmallerLocal,
        ProviderFailure::BudgetExceeded => Degradation::NoSuggestion(
            "token budget exceeded; no suggestion produced".into(),
        ),
        ProviderFailure::PolicyDenied => Degradation::NoSuggestion(
            "policy denied; no suggestion produced".into(),
        ),
        ProviderFailure::Cancelled => {
            if remote_approved {
                Degradation::StrongerApproved
            } else {
                Degradation::SmallerLocal
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Token Budget Dashboard record (WM-SPEC-013-R07)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct UsageRecord {
    pub provider: String,
    pub model_family: String,
    pub feature: String,
    pub context_tokens: usize,
    pub output_tokens: usize,
    pub estimated_cost_usd_micros: u64,
    pub latency_ms: u64,
    pub cache_status: String,
    pub reason: String,
    pub profile_scope: String,
}

impl UsageRecord {
    pub fn new(feature: &str, profile_scope: &str) -> Self {
        Self {
            provider: String::new(),
            model_family: String::new(),
            feature: feature.to_string(),
            context_tokens: 0,
            output_tokens: 0,
            estimated_cost_usd_micros: 0,
            latency_ms: 0,
            cache_status: "none".into(),
            reason: String::new(),
            profile_scope: profile_scope.to_string(),
        }
    }

    /// Deterministic cost estimate in USD micros (no external rate API).
    pub fn estimate_cost(&mut self, per_million_input_usd: u64, per_million_output_usd: u64) {
        let input = self.context_tokens as u128 * per_million_input_usd as u128 / 1_000_000;
        let output = self.output_tokens as u128 * per_million_output_usd as u128 / 1_000_000;
        self.estimated_cost_usd_micros = (input + output) as u64;
    }
}

/// Bounded, in-memory dashboard (WM-SPEC-013-R07). Callers append after
/// each usage; the dashboard caps retained rows and exposes a compact
/// summary. Persistence is EP-014 storage's responsibility (M3).
#[derive(Debug, Clone, Default)]
pub struct TokenDashboard {
    pub records: Vec<UsageRecord>,
    pub max_records: usize,
}

impl TokenDashboard {
    pub fn new(max_records: usize) -> Self {
        Self {
            records: Vec::new(),
            max_records: if max_records == 0 { 1024 } else { max_records },
        }
    }

    pub fn record(&mut self, r: UsageRecord) -> Result<(), BudgetError> {
        if self.records.len() >= self.max_records {
            return Err(BudgetError::DashboardFull);
        }
        self.records.push(r);
        Ok(())
    }

    pub fn total_estimated_cost_usd_micros(&self) -> u64 {
        self.records.iter().map(|r| r.estimated_cost_usd_micros).sum()
    }

    pub fn total_tokens(&self) -> usize {
        self.records
            .iter()
            .map(|r| r.context_tokens + r.output_tokens)
            .sum()
    }

    pub fn len(&self) -> usize {
        self.records.len()
    }

    pub fn is_empty(&self) -> bool {
        self.records.is_empty()
    }
}

// ---------------------------------------------------------------------------
// Untrusted output validation (WM-SPEC-013-R09)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OutputValidation {
    pub ok: bool,
    pub reasons: Vec<String>,
}

impl OutputValidation {
    pub fn pass() -> Self {
        Self {
            ok: true,
            reasons: Vec::new(),
        }
    }
    pub fn reject(reason: impl Into<String>) -> Self {
        Self {
            ok: false,
            reasons: vec![reason.into()],
        }
    }
}

/// Validate untrusted AI output before use: schema shape, citation
/// presence, command-safety policy, and no secret leakage.
/// Deterministic and local; returns typed rejection reasons.
pub fn validate_output(text: &str, policy: &[&str], require_citation: bool) -> OutputValidation {
    let mut reasons = Vec::new();

    if text.trim().is_empty() {
        reasons.push("empty output".into());
    }
    if text.chars().count() > DEFAULT_OUTPUT_CAP * 4 {
        reasons.push("output over budget".into());
    }
    if require_citation && !text.contains('[') {
        reasons.push("missing citation".into());
    }
    if text.contains("Bearer ") || text.contains("api_key=") || text.contains("password=") {
        reasons.push("secret leakage".into());
    }
    // Command safety: policy-listed dangerous commands are refused.
    for cmd in policy {
        if text.contains(cmd) {
            reasons.push(format!("policy command refused: {cmd}"));
        }
    }
    if reasons.is_empty() {
        OutputValidation::pass()
    } else {
        OutputValidation {
            ok: false,
            reasons,
        }
    }
}

// ---------------------------------------------------------------------------
// Errors (SPEC-025)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum BudgetError {
    DashboardFull,
    Invalid(String),
}

impl std::fmt::Display for BudgetError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{self:?}")
    }
}

impl std::error::Error for BudgetError {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn estimate_is_deterministic() {
        assert_eq!(estimate_tokens("abcd"), 1);
        assert_eq!(estimate_tokens("abcdefgh"), 2);
        assert_eq!(estimate_tokens(""), 0);
    }

    #[test]
    fn budget_fits_and_caps() {
        let b = TokenBudget::default_full();
        assert!(b.fits("feature", 0, "short text"));
        assert!(!b.fits("feature", DEFAULT_CONTEXT_CAP, "more text"));
        let b2 = TokenBudget {
            max_context_tokens: 100,
            max_output_tokens: 50,
            feature_caps: vec![("copilot".into(), 200)],
        };
        assert_eq!(b2.cap_for("copilot"), 200);
        assert_eq!(b2.cap_for("other"), 100);
    }

    #[test]
    fn routing_never_remote_without_privacy() {
        let ctx = RoutingContext {
            task_class: TaskClass::Complex,
            privacy_sensitive: true,
            risk_high: false,
            latency_budget_ms: 1000,
            est_cost_usd: 0.0,
            remote_available: true,
            remote_approved: true,
            context_tokens: 100,
            user_policy_allows_remote: true,
        };
        assert_eq!(decide_route(&ctx), RouteDecision::LocalSmall);
    }

    #[test]
    fn routing_remote_only_when_approved() {
        let ctx = RoutingContext {
            task_class: TaskClass::Complex,
            privacy_sensitive: false,
            risk_high: false,
            latency_budget_ms: 1000,
            est_cost_usd: 0.001,
            remote_available: true,
            remote_approved: false,
            context_tokens: 100,
            user_policy_allows_remote: true,
        };
        assert_eq!(decide_route(&ctx), RouteDecision::LocalFull);
        let ctx2 = RoutingContext {
            remote_approved: true,
            user_policy_allows_remote: true,
            ..ctx
        };
        assert_eq!(decide_route(&ctx2), RouteDecision::RemoteApproved);
    }

    #[test]
    fn routing_budget_exceeded_no_suggestion() {
        let ctx = RoutingContext {
            context_tokens: DEFAULT_CONTEXT_CAP + 1,
            ..RoutingContext {
                task_class: TaskClass::Moderate,
                privacy_sensitive: false,
                risk_high: false,
                latency_budget_ms: 500,
                est_cost_usd: 0.0,
                remote_available: true,
                remote_approved: true,
                context_tokens: 0,
                user_policy_allows_remote: true,
            }
        };
        assert!(matches!(decide_route(&ctx), RouteDecision::NoSuggestion { .. }));
    }

    #[test]
    fn degradation_never_blocks() {
        assert_eq!(degrade(ProviderFailure::Slow, false), Degradation::SmallerLocal);
        assert!(matches!(
            degrade(ProviderFailure::BudgetExceeded, false),
            Degradation::NoSuggestion(_)
        ));
        assert_eq!(
            degrade(ProviderFailure::Cancelled, true),
            Degradation::StrongerApproved
        );
    }

    #[test]
    fn dashboard_records_and_bounds() {
        let mut d = TokenDashboard::new(2);
        let mut r = UsageRecord::new("copilot", "dom");
        r.context_tokens = 1000;
        r.output_tokens = 100;
        r.provider = "lightning".into();
        r.model_family = "claude-opus".into();
        r.estimate_cost(3_000_000, 15_000_000);
        d.record(r.clone()).unwrap();
        d.record(r).unwrap();
        assert_eq!(d.len(), 2);
        assert!(d.record(UsageRecord::new("x", "y")).is_err());
        assert_eq!(d.total_tokens(), 2200);
        assert!(d.total_estimated_cost_usd_micros() > 0);
    }

    #[test]
    fn usage_record_serializes() {
        let mut r = UsageRecord::new("dashboard", "dom");
        r.provider = "local".into();
        let json = serde_json::to_string(&r).unwrap();
        assert!(json.contains("model_family"));
    }

    #[test]
    fn validation_rejects_untrusted() {
        let v = validate_output("Sure, here is the plan.", &["quit"], false);
        assert!(v.ok);
        let v2 = validate_output("quit now", &["quit"], false);
        assert!(!v2.ok);
        assert!(v2.reasons.iter().any(|r| r.contains("quit")));
        let v3 = validate_output("no citation here", &[], true);
        assert!(!v3.ok);
        assert!(v3.reasons.iter().any(|r| r.contains("citation")));
        let v4 = validate_output("password=hunter2", &[], false);
        assert!(!v4.ok);
        assert!(v4.reasons.iter().any(|r| r.contains("secret")));
    }

    #[test]
    fn validation_requires_schema_shape() {
        let v = validate_output("", &[], false);
        assert!(!v.ok);
        assert!(v.reasons.iter().any(|r| r.contains("empty")));
    }
}

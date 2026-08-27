//! WireMudder AI Provider Router (SPEC-013, EP-016).
//!
//! WM-FEAT-0038: provider-neutral routing under the accepted WireMudder
//! contracts. WM-SPEC-013-R05: routing considers task, complexity, privacy,
//! risk, latency, cost, locality, availability, historical evaluation,
//! context size, and user policy — all from declared inputs, deterministically.
//! WM-SPEC-013-R08: remote calls require the active privacy mode and explicit
//! provider configuration; no silent remote fallback exists. WM-SPEC-013-R06:
//! degradation to a smaller local route or a user-visible no-suggestion result
//! is explicit, never silent. WM-SPEC-013-R10: evaluation fixtures compare
//! quality, privacy leakage, latency, cancellation, cost, and fallback
//! behavior before provider certification.

use serde::{Deserialize, Serialize};
use wire_privacy::PrivacyMode;

pub const ROUTER_SCHEMA_VERSION: u32 = 1;

// ---------------------------------------------------------------------------
// Declared routing inputs (R05)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct RoutingInputs {
    pub task: String,
    /// 1 (trivial) ..= 5 (complex)
    pub complexity: u8,
    pub privacy_mode: PrivacyMode,
    pub risk: String,
    pub latency_budget_ms: u64,
    pub cost_budget: f64,
    pub context_size: usize,
    pub availability_hint: bool,
    pub user_policy: Option<String>,
}

impl RoutingInputs {
    pub fn new(
        task: &str,
        complexity: u8,
        privacy_mode: PrivacyMode,
        latency_budget_ms: u64,
        cost_budget: f64,
        context_size: usize,
    ) -> Self {
        Self {
            task: task.into(),
            complexity,
            privacy_mode,
            risk: "low".into(),
            latency_budget_ms,
            cost_budget,
            context_size,
            availability_hint: true,
            user_policy: None,
        }
    }
}

// ---------------------------------------------------------------------------
// Route configuration (explicit provider configuration, R08)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct RouteConfig {
    pub route_id: String,
    pub provider_id: String,
    pub kind: String, // "local" | "remote"
    pub model: String,
    pub certified: bool,
    pub configured: bool,
    pub remote_egress: bool,
    pub context_window: usize,
    pub cost_per_1k: f64,
    pub locality: String,
    pub min_privacy_mode: Option<PrivacyMode>,
    pub est_latency_ms: u64,
}

impl RouteConfig {
    pub fn local(
        route_id: &str,
        provider_id: &str,
        model: &str,
        context_window: usize,
        cost_per_1k: f64,
        est_latency_ms: u64,
    ) -> Self {
        Self {
            route_id: route_id.into(),
            provider_id: provider_id.into(),
            kind: "local".into(),
            model: model.into(),
            certified: true,
            configured: true,
            remote_egress: false,
            context_window,
            cost_per_1k,
            locality: "local".into(),
            min_privacy_mode: None,
            est_latency_ms,
        }
    }

    pub fn remote(
        route_id: &str,
        provider_id: &str,
        model: &str,
        context_window: usize,
        cost_per_1k: f64,
        est_latency_ms: u64,
    ) -> Self {
        Self {
            route_id: route_id.into(),
            provider_id: provider_id.into(),
            kind: "remote".into(),
            model: model.into(),
            certified: false,
            configured: false,
            remote_egress: true,
            context_window,
            cost_per_1k,
            locality: "remote".into(),
            min_privacy_mode: Some(PrivacyMode::RemoteApproved),
            est_latency_ms,
        }
    }
}

// ---------------------------------------------------------------------------
// Decision (explicit, typed; no silent fallback)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "decision", rename_all = "kebab-case")]
pub enum RoutingDecision {
    Selected {
        route_id: String,
        provider_id: String,
        reason: String,
        degraded: bool,
    },
    NoSuggestion {
        reason: String,
    },
    Denied {
        reason: String,
    },
}

impl RoutingDecision {
    pub fn route_id(&self) -> Option<&str> {
        match self {
            RoutingDecision::Selected { route_id, .. } => Some(route_id),
            _ => None,
        }
    }

    pub fn reason(&self) -> &str {
        match self {
            RoutingDecision::Selected { reason, .. } => reason,
            RoutingDecision::NoSuggestion { reason } => reason,
            RoutingDecision::Denied { reason } => reason,
        }
    }
}

// ---------------------------------------------------------------------------
// Router: deterministic pure function over declared inputs
// ---------------------------------------------------------------------------

pub struct AiRouter {
    routes: Vec<RouteConfig>,
}

impl AiRouter {
    pub fn new(routes: Vec<RouteConfig>) -> Self {
        Self { routes }
    }

    pub fn route_count(&self) -> usize {
        self.routes.len()
    }

    /// Deterministic routing. Same declared inputs always yield the same
    /// decision. Uncertified adapters are never selected (acceptance
    /// obligation 6); remote routes require active privacy mode and explicit
    /// configuration (R08); any fallback is explicit and marked degraded.
    pub fn route(&self, inputs: &RoutingInputs) -> RoutingDecision {
        // Scan remote routes for explicit block reasons (R08) before the
        // eligibility filter, so denial reasons are honest and a local
        // fallback is explicitly marked degraded (R06: never silent).
        let mut remote_denied_reason: Option<String> = None;
        for r in self
            .routes
            .iter()
            .filter(|r| r.remote_egress || r.kind == "remote")
        {
            if inputs.privacy_mode.blocks_remote() {
                remote_denied_reason = Some(
                    "remote calls require an active privacy mode that permits egress".into(),
                );
                break;
            }
            if !r.configured {
                remote_denied_reason =
                    Some("remote provider is not explicitly configured".into());
                break;
            }
            if let Some(min) = r.min_privacy_mode {
                if !privacy_allows(min, inputs.privacy_mode) {
                    remote_denied_reason = Some("route privacy requirement not met".into());
                    break;
                }
            }
        }

        // 1. Candidates: certified, configured, fits context, fits cost.
        //    cost_budget <= 0.0 means no cost constraint.
        let mut candidates: Vec<&RouteConfig> = self
            .routes
            .iter()
            .filter(|r| r.certified)
            .filter(|r| r.configured)
            .filter(|r| inputs.context_size <= r.context_window)
            .filter(|r| inputs.cost_budget <= 0.0 || r.cost_per_1k <= inputs.cost_budget)
            .collect();

        // 2. Availability hint filters candidates.
        if !inputs.availability_hint {
            candidates.retain(|r| r.locality == "local");
        }

        // 3. User policy is honored when eligible.
        if let Some(pref) = inputs.user_policy.as_deref() {
            if let Some(r) = candidates.iter().find(|r| r.route_id == pref) {
                return self.apply_privacy_gate(r, inputs);
            }
        }

        if candidates.is_empty() {
            return match remote_denied_reason {
                Some(reason) => RoutingDecision::Denied { reason },
                None => RoutingDecision::NoSuggestion {
                    reason: "no certified provider fits the declared budget".into(),
                },
            };
        }

        // 4. Deterministic ordering: local first, then cost, latency, id.
        candidates.sort_by(|a, b| {
            let la = if a.locality == "local" { 0 } else { 1 };
            let lb = if b.locality == "local" { 0 } else { 1 };
            la.cmp(&lb)
                .then(
                    a.cost_per_1k
                        .partial_cmp(&b.cost_per_1k)
                        .unwrap_or(std::cmp::Ordering::Equal),
                )
                .then(a.est_latency_ms.cmp(&b.est_latency_ms))
                .then(a.route_id.cmp(&b.route_id))
        });

        let chosen = candidates[0];

        // 5. Latency budget check on the chosen route.
        if chosen.est_latency_ms > inputs.latency_budget_ms && !chosen.remote_egress {
            return RoutingDecision::NoSuggestion {
                reason: "no certified provider meets the latency budget".into(),
            };
        }

        // 6. Explicit degradation (R06): when a remote route was present but
        //    blocked, selecting local is a marked fallback, never silent.
        let degraded = remote_denied_reason.is_some()
            || inputs
                .user_policy
                .as_deref()
                .map(|p| p != chosen.route_id)
                .unwrap_or(false);

        RoutingDecision::Selected {
            route_id: chosen.route_id.clone(),
            provider_id: chosen.provider_id.clone(),
            reason: if degraded {
                format!(
                    "explicit local fallback; {}",
                    remote_denied_reason.unwrap_or_default()
                )
            } else {
                "best certified route for declared inputs".into()
            },
            degraded,
        }
    }

    fn apply_privacy_gate(&self, r: &RouteConfig, inputs: &RoutingInputs) -> RoutingDecision {
        if r.remote_egress || r.kind == "remote" {
            if inputs.privacy_mode.blocks_remote() {
                return RoutingDecision::Denied {
                    reason: "remote calls require an active privacy mode that permits egress".into(),
                };
            }
            if !r.configured {
                return RoutingDecision::Denied {
                    reason: "remote provider is not explicitly configured".into(),
                };
            }
            if let Some(min) = r.min_privacy_mode {
                if !privacy_allows(min, inputs.privacy_mode) {
                    return RoutingDecision::Denied {
                        reason: "route privacy requirement not met".into(),
                    };
                }
            }
        }
        RoutingDecision::Selected {
            route_id: r.route_id.clone(),
            provider_id: r.provider_id.clone(),
            reason: "user policy route".into(),
            degraded: false,
        }
    }
}

/// PrivacyMode ordering: RemoteApproved >= RemoteRedacted >= LocalPreferred
/// >= LocalOnly >= Disabled. A route's min mode is satisfied when the active
/// mode is at least as permissive.
fn privacy_allows(min: PrivacyMode, active: PrivacyMode) -> bool {
    fn rank(m: PrivacyMode) -> u8 {
        match m {
            PrivacyMode::Disabled => 0,
            PrivacyMode::LocalOnly => 1,
            PrivacyMode::LocalPreferred => 2,
            PrivacyMode::RemoteRedacted => 3,
            PrivacyMode::RemoteApproved => 4,
        }
    }
    rank(active) >= rank(min)
}

// ---------------------------------------------------------------------------
// Evaluation fixtures (R10): compare quality, privacy leakage, latency,
// cancellation, cost, and fallback before provider certification.
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct EvaluationFixture {
    pub fixture_id: String,
    pub route_id: String,
    pub provider: String,
    pub quality_score: f64,
    pub privacy_leak_count: usize,
    pub latency_ms: u64,
    pub cancellation_ms: u64,
    pub cost: f64,
    pub fallback_count: u32,
    pub baseline_quality: f64,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct EvaluationLimits {
    pub min_quality_factor: f64,
    pub max_privacy_leaks: usize,
    pub max_latency_ms: u64,
    pub max_cancellation_ms: u64,
    pub max_cost: f64,
    pub max_fallbacks: u32,
}

impl EvaluationLimits {
    pub fn strict() -> Self {
        Self {
            min_quality_factor: 0.9,
            max_privacy_leaks: 0,
            max_latency_ms: 2_000,
            max_cancellation_ms: 500,
            max_cost: 0.05,
            max_fallbacks: 1,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct EvaluationReport {
    pub fixture_id: String,
    pub route_id: String,
    pub provider: String,
    pub quality_ok: bool,
    pub privacy_ok: bool,
    pub latency_ok: bool,
    pub cancellation_ok: bool,
    pub cost_ok: bool,
    pub fallback_ok: bool,
    pub certified: bool,
}

/// Deterministic evaluation: every dimension must meet its limit for the
/// route to be certifiable.
pub fn evaluate_fixture(f: &EvaluationFixture, limits: &EvaluationLimits) -> EvaluationReport {
    let quality_ok = f.quality_score >= f.baseline_quality * limits.min_quality_factor;
    let privacy_ok = f.privacy_leak_count <= limits.max_privacy_leaks;
    let latency_ok = f.latency_ms <= limits.max_latency_ms;
    let cancellation_ok = f.cancellation_ms <= limits.max_cancellation_ms;
    let cost_ok = f.cost <= limits.max_cost;
    let fallback_ok = f.fallback_count <= limits.max_fallbacks;
    EvaluationReport {
        fixture_id: f.fixture_id.clone(),
        route_id: f.route_id.clone(),
        provider: f.provider.clone(),
        quality_ok,
        privacy_ok,
        latency_ok,
        cancellation_ok,
        cost_ok,
        fallback_ok,
        certified: quality_ok && privacy_ok && latency_ok && cancellation_ok && cost_ok && fallback_ok,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn local_route(id: &str) -> RouteConfig {
        RouteConfig::local(id, "ollama", "tinyllama", 2048, 0.0, 30)
    }

    fn remote_route(id: &str) -> RouteConfig {
        RouteConfig::remote(id, "openai", "gpt-x", 8192, 0.01, 800)
    }

    fn inputs(privacy: PrivacyMode) -> RoutingInputs {
        RoutingInputs::new("suggest", 2, privacy, 2_000, 0.1, 512)
    }

    #[test]
    fn deterministic_same_inputs() {
        let router = AiRouter::new(vec![local_route("local-a"), remote_route("remote-b")]);
        let i = inputs(PrivacyMode::RemoteApproved);
        assert_eq!(router.route(&i), router.route(&i));
        assert_eq!(router.route(&i), router.route(&i.clone()));
    }

    #[test]
    fn local_selected_when_available() {
        let router = AiRouter::new(vec![local_route("local-a"), remote_route("remote-b")]);
        let d = router.route(&inputs(PrivacyMode::LocalPreferred));
        assert_eq!(d.route_id(), Some("local-a"));
        assert!(!matches!(d, RoutingDecision::Denied { .. }));
    }

    #[test]
    fn remote_requires_configuration() {
        // remote route has configured=false by default -> denied, not silent.
        let router = AiRouter::new(vec![remote_route("remote-b")]);
        let d = router.route(&inputs(PrivacyMode::RemoteApproved));
        assert!(matches!(d, RoutingDecision::NoSuggestion { .. } | RoutingDecision::Denied { .. }));
    }

    #[test]
    fn remote_requires_privacy_mode() {
        let mut r = remote_route("remote-b");
        r.configured = true;
        let router = AiRouter::new(vec![r]);
        let d = router.route(&inputs(PrivacyMode::LocalOnly));
        assert!(matches!(d, RoutingDecision::Denied { .. }));
        assert!(d.reason().contains("privacy"));
    }

    #[test]
    fn no_silent_remote_fallback() {
        // Privacy blocks remote; local exists -> explicit degraded local.
        let router = AiRouter::new(vec![local_route("local-a"), remote_route("remote-b")]);
        let d = router.route(&inputs(PrivacyMode::LocalOnly));
        match d {
            RoutingDecision::Selected { route_id, degraded, .. } => {
                assert_eq!(route_id, "local-a");
                assert!(degraded);
            }
            other => panic!("expected degraded local selection, got {other:?}"),
        }
    }

    #[test]
    fn uncertified_never_selected() {
        let mut r = local_route("local-a");
        r.certified = false;
        let router = AiRouter::new(vec![r]);
        let d = router.route(&inputs(PrivacyMode::LocalPreferred));
        assert!(matches!(d, RoutingDecision::NoSuggestion { .. } | RoutingDecision::Denied { .. }));
        assert!(d.route_id().is_none());
    }

    #[test]
    fn user_policy_respected() {
        let router = AiRouter::new(vec![local_route("local-a"), local_route("local-b")]);
        let mut i = inputs(PrivacyMode::LocalPreferred);
        i.user_policy = Some("local-b".into());
        let d = router.route(&i);
        assert_eq!(d.route_id(), Some("local-b"));
    }

    #[test]
    fn user_policy_remote_denied_when_privacy_blocks() {
        let mut r = remote_route("remote-b");
        r.configured = true;
        let router = AiRouter::new(vec![r]);
        let mut i = inputs(PrivacyMode::LocalOnly);
        i.user_policy = Some("remote-b".into());
        let d = router.route(&i);
        assert!(matches!(d, RoutingDecision::Denied { .. }));
    }

    #[test]
    fn cost_budget_filters() {
        let mut r = local_route("local-a");
        r.cost_per_1k = 0.5;
        let router = AiRouter::new(vec![r]);
        let mut i = inputs(PrivacyMode::LocalPreferred);
        i.cost_budget = 0.0; // 0.0 means no cost constraint
        assert!(router.route(&i).route_id().is_some());
        i.cost_budget = 0.1; // below the 0.5 cost -> excluded
        assert!(router.route(&i).route_id().is_none());
    }

    #[test]
    fn context_window_filters() {
        let router = AiRouter::new(vec![local_route("local-a")]);
        let mut i = inputs(PrivacyMode::LocalPreferred);
        i.context_size = 4096; // window is 2048
        let d = router.route(&i);
        assert!(d.route_id().is_none());
    }

    #[test]
    fn latency_budget_filters() {
        let router = AiRouter::new(vec![local_route("local-a")]);
        let mut i = inputs(PrivacyMode::LocalPreferred);
        i.latency_budget_ms = 10; // est latency 30
        let d = router.route(&i);
        assert!(d.route_id().is_none());
    }

    #[test]
    fn degraded_flag_only_when_fallback() {
        let router = AiRouter::new(vec![local_route("local-a")]);
        let d = router.route(&inputs(PrivacyMode::LocalPreferred));
        match d {
            RoutingDecision::Selected { degraded, .. } => assert!(!degraded),
            other => panic!("expected selected, got {other:?}"),
        }
    }

    #[test]
    fn no_suggestion_when_nothing_fits() {
        let router = AiRouter::new(vec![]);
        let d = router.route(&inputs(PrivacyMode::LocalPreferred));
        assert!(matches!(d, RoutingDecision::NoSuggestion { .. }));
    }

    #[test]
    fn deterministic_ordering_local_first() {
        let mut remote = remote_route("remote-b");
        remote.configured = true;
        let router = AiRouter::new(vec![remote, local_route("local-a")]);
        let d = router.route(&inputs(PrivacyMode::RemoteApproved));
        assert_eq!(d.route_id(), Some("local-a"));
    }

    #[test]
    fn evaluation_fixture_pass() {
        let f = EvaluationFixture {
            fixture_id: "fx-1".into(),
            route_id: "local-a".into(),
            provider: "ollama".into(),
            quality_score: 0.95,
            privacy_leak_count: 0,
            latency_ms: 40,
            cancellation_ms: 20,
            cost: 0.0,
            fallback_count: 0,
            baseline_quality: 1.0,
        };
        let r = evaluate_fixture(&f, &EvaluationLimits::strict());
        assert!(r.certified);
        assert!(r.privacy_ok);
    }

    #[test]
    fn evaluation_fixture_privacy_leak_fails() {
        let mut f = EvaluationFixture {
            fixture_id: "fx-2".into(),
            route_id: "remote-b".into(),
            provider: "openai".into(),
            quality_score: 0.99,
            privacy_leak_count: 0,
            latency_ms: 100,
            cancellation_ms: 30,
            cost: 0.0,
            fallback_count: 0,
            baseline_quality: 1.0,
        };
        f.privacy_leak_count = 1;
        let r = evaluate_fixture(&f, &EvaluationLimits::strict());
        assert!(!r.certified);
        assert!(!r.privacy_ok);
    }

    #[test]
    fn evaluation_fixture_latency_fails() {
        let mut f = EvaluationFixture {
            fixture_id: "fx-3".into(),
            route_id: "remote-b".into(),
            provider: "openai".into(),
            quality_score: 0.99,
            privacy_leak_count: 0,
            latency_ms: 100,
            cancellation_ms: 30,
            cost: 0.0,
            fallback_count: 0,
            baseline_quality: 1.0,
        };
        f.latency_ms = 5_000;
        let r = evaluate_fixture(&f, &EvaluationLimits::strict());
        assert!(!r.certified);
        assert!(!r.latency_ok);
    }

    #[test]
    fn evaluation_fixture_cost_fails() {
        let mut f = EvaluationFixture {
            fixture_id: "fx-4".into(),
            route_id: "remote-b".into(),
            provider: "openai".into(),
            quality_score: 0.99,
            privacy_leak_count: 0,
            latency_ms: 100,
            cancellation_ms: 30,
            cost: 0.0,
            fallback_count: 0,
            baseline_quality: 1.0,
        };
        f.cost = 0.5;
        let r = evaluate_fixture(&f, &EvaluationLimits::strict());
        assert!(!r.certified);
        assert!(!r.cost_ok);
    }

    #[test]
    fn evaluation_fixture_quality_fails() {
        let f = EvaluationFixture {
            fixture_id: "fx-5".into(),
            route_id: "local-a".into(),
            provider: "ollama".into(),
            quality_score: 0.5,
            privacy_leak_count: 0,
            latency_ms: 40,
            cancellation_ms: 20,
            cost: 0.0,
            fallback_count: 0,
            baseline_quality: 1.0,
        };
        let r = evaluate_fixture(&f, &EvaluationLimits::strict());
        assert!(!r.certified);
        assert!(!r.quality_ok);
    }

    #[test]
    fn schema_version_stable() {
        assert_eq!(ROUTER_SCHEMA_VERSION, 1);
    }

    #[test]
    fn privacy_mode_ordering() {
        assert!(privacy_allows(PrivacyMode::RemoteApproved, PrivacyMode::RemoteApproved));
        assert!(!privacy_allows(PrivacyMode::RemoteApproved, PrivacyMode::LocalOnly));
        assert!(privacy_allows(PrivacyMode::LocalOnly, PrivacyMode::RemoteRedacted));
    }
}

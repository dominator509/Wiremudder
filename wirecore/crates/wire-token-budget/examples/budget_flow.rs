//! EP-015 M3 integration fixture: real token budget flow.
//! Routing decisions, degradation matrix, usage records with cost, and
//! untrusted output validation as deterministic stdout evidence.

use wire_token_budget::{
    decide_route, degrade, validate_output, ProviderFailure, RouteDecision, RoutingContext,
    TaskClass, TokenBudget, TokenDashboard, UsageRecord,
};

fn main() {
    // Budget fits/caps.
    let b = TokenBudget::default_full();
    println!("BUDGET fits={} cap={}", b.fits("copilot", 0, "hello"), b.cap_for("copilot"));

    // Routing: privacy-sensitive stays local; approved remote for complex.
    let ctx = RoutingContext {
        task_class: TaskClass::Complex,
        privacy_sensitive: true,
        risk_high: false,
        latency_budget_ms: 1000,
        est_cost_usd: 0.001,
        remote_available: true,
        remote_approved: true,
        context_tokens: 100,
        user_policy_allows_remote: true,
    };
    println!("ROUTE privacy={}", route_name(decide_route(&ctx)));
    let ctx2 = RoutingContext {
        privacy_sensitive: false,
        ..ctx
    };
    println!("ROUTE approved={}", route_name(decide_route(&ctx2)));

    // Degradation never blocks gameplay.
    println!("DEGRADE slow={} budget={} cancel={}",
        degrade_name(degrade(ProviderFailure::Slow, false)),
        degrade_name(degrade(ProviderFailure::BudgetExceeded, false)),
        degrade_name(degrade(ProviderFailure::Cancelled, true)));

    // Usage record with deterministic cost.
    let mut d = TokenDashboard::new(64);
    let mut r = UsageRecord::new("copilot", "dom");
    r.provider = "lightning".into();
    r.model_family = "claude-opus".into();
    r.context_tokens = 1000;
    r.output_tokens = 100;
    r.latency_ms = 42;
    r.cache_status = "hit".into();
    r.estimate_cost(3_000_000, 15_000_000);
    d.record(r).unwrap();
    println!("USAGE cost_usd_micros={} tokens={}", d.total_estimated_cost_usd_micros(), d.total_tokens());

    // Untrusted output validation (R09).
    let ok = validate_output("Walk north to the gate. [room:2]", &["quit"], true);
    let bad = validate_output("quit now; password=hunter2", &["quit"], true);
    println!("VALIDATE ok={} bad={} reasons={}",
        ok.ok,
        bad.ok,
        bad.reasons.len());
}

fn route_name(r: RouteDecision) -> &'static str {
    match r {
        RouteDecision::LocalSmall => "local-small",
        RouteDecision::LocalFull => "local-full",
        RouteDecision::RemoteApproved => "remote-approved",
        RouteDecision::NoSuggestion { .. } => "no-suggestion",
    }
}

fn degrade_name(d: wire_token_budget::Degradation) -> &'static str {
    match d {
        wire_token_budget::Degradation::SmallerLocal => "smaller-local",
        wire_token_budget::Degradation::NoSuggestion(_) => "no-suggestion",
        wire_token_budget::Degradation::StrongerApproved => "stronger-approved",
    }
}

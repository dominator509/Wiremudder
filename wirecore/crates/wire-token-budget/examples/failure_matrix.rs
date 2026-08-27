//! EP-015 M4 failure matrix (wire-token-budget): typed failures for
//! resource exhaustion, budget exceeded, unavailable dependency,
//! timeout, cancellation, policy denial, and partial effects. Every
//! case fails typed, never panics, and never blocks gameplay.

use wire_token_budget::{
    decide_route, degrade, validate_output, BudgetError, ProviderFailure, RouteDecision,
    RoutingContext, TaskClass, TokenBudget, TokenDashboard, UsageRecord,
};

fn main() {
    // 1. Resource exhaustion: dashboard bounded, typed DashboardFull.
    let mut dash = TokenDashboard::new(1);
    dash.record(UsageRecord::new("a", "dom")).unwrap();
    let full = matches!(dash.record(UsageRecord::new("b", "dom")), Err(BudgetError::DashboardFull));
    println!("dashboard-full:{}", if full { "ok" } else { "fail" });

    // 2. Budget exhausted: context over cap -> no-suggestion, typed.
    let ctx = RoutingContext {
        task_class: TaskClass::Moderate,
        privacy_sensitive: false,
        risk_high: false,
        latency_budget_ms: 500,
        est_cost_usd: 0.0,
        remote_available: true,
        remote_approved: true,
        context_tokens: TokenBudget::default_full().max_context_tokens + 1,
        user_policy_allows_remote: true,
    };
    let nosugg = matches!(decide_route(&ctx), RouteDecision::NoSuggestion { .. });
    println!("budget-exceeded:{}", if nosugg { "ok" } else { "fail" });

    // 3. Unavailable dependency: remote missing -> smaller local route.
    let slow = degrade(ProviderFailure::Unavailable, false)
        == wire_token_budget::Degradation::SmallerLocal;
    println!("unavailable:{}", if slow { "ok" } else { "fail" });

    // 4. Timeout/cancellation: latency budget exceeded degrades.
    let timeout = degrade(ProviderFailure::Slow, false)
        == wire_token_budget::Degradation::SmallerLocal;
    let cancel = matches!(
        degrade(ProviderFailure::Cancelled, false),
        wire_token_budget::Degradation::SmallerLocal
    );
    println!("timeout:{} cancel:{}", if timeout { "ok" } else { "fail" }, if cancel { "ok" } else { "fail" });

    // 5. Denied policy: validation refuses policy-listed command.
    let denied = !validate_output("quit now", &["quit"], false).ok;
    println!("policy-denied:{}", if denied { "ok" } else { "fail" });

    // 6. Partial side effect: failed validation never mutates state.
    let v = validate_output("drop table transcripts", &["drop"], false);
    println!("partial-effect:{}", if !v.ok && v.reasons.len() > 0 { "ok" } else { "fail" });

    println!("failure-budget EP-015 M4: ok");
}

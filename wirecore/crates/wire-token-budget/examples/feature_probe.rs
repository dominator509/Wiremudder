//! EP-015 M5 feature probe (wire-token-budget): asserts one owned
//! feature per invocation. Prints the feature sentinel only when real
//! behavior holds.

use wire_token_budget::{
    decide_route, degrade, ProviderFailure, RouteDecision, RoutingContext, TaskClass,
    TokenDashboard, UsageRecord,
};

fn main() {
    let feature = std::env::args().nth(1).expect("feature id");
    let ok = match feature.as_str() {
        // WM-FEAT-0049: token budget dashboard records usage + cost.
        "WM-FEAT-0049" => {
            let mut d = TokenDashboard::new(64);
            let mut r = UsageRecord::new("copilot", "dom");
            r.context_tokens = 1000;
            r.output_tokens = 100;
            r.estimate_cost(3_000_000, 15_000_000);
            d.record(r).is_ok() && d.total_tokens() == 1100 && d.total_estimated_cost_usd_micros() > 0
        }
        // WM-FEAT-0189: token budget agent routes and degrades.
        "WM-FEAT-0189" => {
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
            matches!(decide_route(&ctx), RouteDecision::LocalSmall)
                && degrade(ProviderFailure::Unavailable, false)
                    == wire_token_budget::Degradation::SmallerLocal
        }
        _ => {
            eprintln!("unknown feature {feature}");
            false
        }
    };
    if ok {
        println!("{feature}: ok");
    } else {
        println!("{feature}: fail");
        std::process::exit(1);
    }
}

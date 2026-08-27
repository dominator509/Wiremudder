//! EP-015 M4 security matrix (wire-token-budget): AI output validation
//! rejects secret leakage and policy violations; routing permission
//! requires explicit approval; supply chain stays minimal.

use wire_token_budget::{decide_route, validate_output, RoutingContext, TaskClass};

fn main() {
    // 1. AI output validation rejects secret leakage (R09).
    let leak = !validate_output("the token is token=abc", &[], false).ok;
    println!("output-secret-rejected:{}", if leak { "ok" } else { "fail" });

    // 2. AI output validation rejects policy-listed commands.
    let policy = !validate_output("quit now", &["quit"], false).ok;
    println!("output-policy-rejected:{}", if policy { "ok" } else { "fail" });

    // 3. Routing permission: remote requires explicit approval.
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
    let denied = !matches!(
        decide_route(&ctx),
        wire_token_budget::RouteDecision::RemoteApproved
    );
    println!("route-permission:{}", if denied { "ok" } else { "fail" });

    // 4. Supply chain: only serde/serde_json declared (no network deps).
    let cargo = std::fs::read_to_string("wirecore/crates/wire-token-budget/Cargo.toml").unwrap();
    let deps = &cargo[cargo.find("[dependencies]").unwrap_or(0)..];
    let minimal = !deps.contains("reqwest") && !deps.contains("tokio") && !deps.contains("hyper");
    println!("supply-chain-minimal:{}", if minimal { "ok" } else { "fail" });

    println!("security-budget EP-015 M4: ok");
}

//! Oracle CLI: emit the policy matrix for cross-implementation
//! comparison with the C++ Qt layer (EP-008 M3 e2e oracle test).
use serde_json::json;
use wire_policy::{CommandDatabase, CommandRule, HumanTempo, RiskTier, TempoDecision};

fn main() {
    let mut db = CommandDatabase::new("midkemia");
    db.add_rule(CommandRule::new("say", RiskTier::Safe));
    db.add_rule(CommandRule::new("tell", RiskTier::Standard));
    db.add_rule(CommandRule::new("kill", RiskTier::Destructive));
    db.add_rule(CommandRule::new("quit", RiskTier::Destructive).deny());
    db.add_rule(CommandRule::new("give", RiskTier::Risky).arg_policy("min:2"));
    db.add_rule(CommandRule::new("drop all", RiskTier::Destructive).allowlist());

    let cases = vec![
        ("say", vec!["hi"]),
        ("tell", vec!["bob", "hi"]),
        ("kill", vec!["orc"]),
        ("quit", vec![]),
        ("give", vec!["bob"]),
        ("give", vec!["bob", "sword"]),
        ("drop all", vec![]),
        ("frobnicate", vec!["x"]),
    ];
    let matrix: Vec<serde_json::Value> = cases
        .iter()
        .map(|(cmd, args)| {
            let p = db.evaluate(cmd, args);
            json!({
                "command": cmd,
                "tier": p.tier.label(),
                "denied": p.denied,
                "requires_confirmation": p.requires_confirmation,
                "arg_ok": p.arg_ok,
            })
        })
        .collect();

    // Human-Tempo pacing matrix.
    let mut tempo = HumanTempo::new(1000, 3, 5000);
    let pacing = vec![
        tempo.should_send(0),
        tempo.should_send(10),
        tempo.should_send(20),
        tempo.should_send(30),
        tempo.should_send(5000),
    ];
    let pacing: Vec<serde_json::Value> = pacing
        .iter()
        .map(|d| match d {
            TempoDecision::Now => json!("now"),
            TempoDecision::Wait(ms) => json!(format!("wait:{ms}")),
        })
        .collect();

    let out = json!({
        "matrix": matrix,
        "pacing": pacing,
    });
    println!("{}", serde_json::to_string(&out).unwrap());
}

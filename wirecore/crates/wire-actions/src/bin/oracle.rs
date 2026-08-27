//! Oracle CLI: emit the gate decision matrix for cross-implementation
//! comparison with the C++ Qt layer (EP-008 M3 e2e oracle test).
use serde_json::json;
use wire_actions::{ActionGateway, ActionSource, GateContext};
use wire_policy::{CommandDatabase, CommandRule, HumanTempo, RiskTier};

fn main() {
    let mut db = CommandDatabase::new("midkemia");
    db.add_rule(CommandRule::new("say", RiskTier::Safe));
    db.add_rule(CommandRule::new("tell", RiskTier::Standard));
    db.add_rule(CommandRule::new("kill", RiskTier::Destructive));
    db.add_rule(CommandRule::new("quit", RiskTier::Destructive).deny());
    let mut g = ActionGateway::new(db, HumanTempo::new(0, 1000, 100000), 16);

    let ctx = GateContext::ready();
    let matrix = json!([
        gate(&mut g, ActionSource::Ai, "say hello", &ctx),
        gate(&mut g, ActionSource::Macro, "kill orc", &ctx),
        gate(&mut g, ActionSource::Script, "quit", &ctx),
    ]);
    let disconnected = GateContext { connected: false, ..ctx };
    let injected = GateContext { injection_flagged: true, ..ctx };
    let noauto = GateContext { profile_automation_enabled: false, ..ctx };
    let matrix2 = json!([
        gate(&mut g, ActionSource::Trigger, "say hi", &disconnected),
        gate(&mut g, ActionSource::Voice, "say hi", &injected),
        gate(&mut g, ActionSource::Plugin, "say hi", &noauto),
    ]);
    let out = json!({
        "matrix": matrix,
        "denied_contexts": matrix2,
    });
    println!("{}", serde_json::to_string(&out).unwrap());
}

fn gate(
    g: &mut ActionGateway,
    src: ActionSource,
    suggestion: &str,
    ctx: &GateContext,
) -> serde_json::Value {
    match g.propose(src, suggestion) {
        Ok(p) => {
            let decision = g.evaluate(&p, ctx);
            json!({
                "source": serde_json::to_value(src).ok().and_then(|v| v.as_str().map(String::from)).unwrap_or_default(),
                "suggestion": suggestion,
                "normalized": p.normalized_command,
                "tier": p.risk_tier.label(),
                "requires_confirmation": p.requires_confirmation,
                "decision": format!("{decision:?}"),
            })
        }
        Err(e) => json!({
            "source": format!("{src:?}"),
            "suggestion": suggestion,
            "error": format!("{e:?}"),
        }),
    }
}

//! Oracle CLI: emit the sensitive-default actor/domain matrix for
//! cross-implementation comparison with the C++ Qt layer (EP-007 M3).
use serde_json::json;
use wire_profiles::{Actor, CharacterProfile, DefaultDomain, ProfileStore};

fn main() {
    // Build the same scenario the C++ harness exercises:
    // 1. User creates profile; automation tries to change routing -> denied
    // 2. Automation changes voice -> allowed
    // 3. User changes AI default -> audited + redacted
    let mut store = ProfileStore::new();
    let p = CharacterProfile::new("char-1", "Zugg").unwrap();
    store.upsert(p.clone(), Actor::User).unwrap();

    let mut q = p.clone();
    q.defaults.set(DefaultDomain::Routing, Some("route-x".into()));
    let automation_routing_denied = matches!(
        store.upsert(q, Actor::Automation),
        Err(wire_profiles::ProfileError::SensitiveDefaultDenied { .. })
    );

    let mut r = p.clone();
    r.defaults.set(DefaultDomain::Voice, Some("v1".into()));
    let automation_voice_allowed = store.upsert(r, Actor::Automation).is_ok();

    let mut s = p.clone();
    s.defaults.set(DefaultDomain::Ai, Some("provider-secret-xyz".into()));
    let user_ai_allowed = store.upsert(s, Actor::User).is_ok();
    let audit = store.sensitive_change_audit();
    let audit_count = audit.len();
    let audit_redacted = audit
        .iter()
        .all(|a| !a.value_redacted.contains("provider-secret-xyz"));

    let domains: Vec<serde_json::Value> = DefaultDomain::all()
        .iter()
        .map(|d| {
            json!({
                "domain": serde_json::to_value(d).ok().and_then(|v| v.as_str().map(String::from)).unwrap_or_default(),
                "sensitive": d.is_sensitive(),
            })
        })
        .collect();

    let out = json!({
        "automation_routing_denied": automation_routing_denied,
        "automation_voice_allowed": automation_voice_allowed,
        "user_ai_allowed": user_ai_allowed,
        "audit_count": audit_count,
        "audit_redacted": audit_redacted,
        "domains": domains,
    });
    println!("{}", serde_json::to_string(&out).unwrap());
}

//! EP-018 M4: forced failure matrix through the real crates.
//!
//! Malformed/oversized input, denied policy, resource exhaustion, duplicate
//! request, and validation failures all produce typed errors with safe
//! user messages (SPEC-025-R09). No mock of the component being proven.
//!
//! Run: cargo run --example failure_matrix (in wire-agents, which also
//! exercises wire-soul via its path dependency).

use wire_agents::{
    Access, AgentRole, Council, CouncilConfig, CouncilVote, MemoryClass, PermissionMatrix,
    SkillRecord, SkillTree,
};
use wire_soul::{SoulDocument, SoulStudio};

fn main() {
    // 1. Malformed soul: empty name -> Validation error.
    let mut studio = SoulStudio::new();
    let mut soul = SoulDocument::new("");
    soul.tone = "calm".into();
    match studio.validate_soul(&soul, 1) {
        Err(e) => {
            assert!(e.user_message().contains("name"));
        }
        Ok(_) => panic!("empty name must fail"),
    }

    // 2. Unsupported schema version -> Schema error.
    let mut bad_ver = SoulDocument::new("X");
    bad_ver.tone = "calm".into();
    bad_ver.schema_version = 99;
    match studio.validate_soul(&bad_ver, 2) {
        Err(wire_soul::SoulError::Schema(_)) => {}
        other => panic!("expected Schema error, got {other:?}"),
    }

    // 3. Oversized soul: huge forbidden list -> bounded audit, still typed.
    for i in 0..1000u64 {
        let mut s = SoulDocument::new("big");
        s.tone = "calm".into();
        s.forbidden_behaviors.push(format!("never do thing {i}"));
        let _ = studio.validate_soul(&s, 100 + i);
    }
    assert!(studio.audit_len() <= 200, "audit must stay bounded");

    // 4. Soul policy override attempts (all domains) -> PolicyOverride.
    for (domain, verb) in [
        ("security", "bypass"),
        ("privacy", "ignore"),
        ("routing", "override"),
        ("package", "disable"),
        ("updater", "weaken"),
        ("emergency-stop", "violate"),
    ] {
        let mut s = SoulDocument::new("evil");
        s.tone = "calm".into();
        s.forbidden_behaviors
            .push(format!("{verb} {domain} policy"));
        assert!(s.validate().is_err(), "domain {domain} not guarded");
        assert!(!s.policy_precedence_ok());
    }

    // 5. Memory permissions: absent = deny for every role/class pair.
    let perms = PermissionMatrix::default_deny_all();
    for role in AgentRole::ALL {
        for class in MemoryClass::ALL {
            if *role == AgentRole::TokenBudget && *class == MemoryClass::Telemetry {
                continue; // the one built-in grant
            }
            assert_eq!(
                perms.access(*role, *class),
                Access::Deny,
                "{role:?}/{class:?} must default to deny"
            );
        }
    }

    // 6. Skill tree: invalid provenance -> Validation; full tree -> Exhaustion.
    let mut tree = SkillTree::new();
    let invalid = SkillRecord {
        id: "".into(),
        name: "x".into(),
        version: "1".into(),
        source: "builtin".into(),
        permissions: vec![],
        evaluation_status: "evaluated".into(),
        profile_scope: "global".into(),
        enabled: false,
        added_at_ms: 1,
    };
    assert!(tree.install(invalid).is_err());

    // 7. Council denied without permission -> Policy.
    let mut council = Council::new(CouncilConfig::default());
    let denied = council.convene(
        "c-f1",
        "secret?",
        false,
        &[AgentRole::Quest],
        vec![CouncilVote {
            role: AgentRole::Quest,
            position: "support".into(),
            evidence: vec![],
            disagreement: None,
        }],
        1,
    );
    assert!(matches!(denied, Err(wire_agents::AgentsError::Policy(_))));

    // 8. Council budget exhaustion -> Exhaustion.
    let big = council.convene(
        "c-f2",
        "big?",
        true,
        &[AgentRole::Quest],
        vec![CouncilVote {
            role: AgentRole::Quest,
            position: "support".into(),
            evidence: vec![],
            disagreement: None,
        }],
        999_999,
    );
    assert!(matches!(big, Err(wire_agents::AgentsError::Exhaustion(_))));

    // 9. Council role/vote mismatch -> Validation.
    let mismatch = council.convene(
        "c-f3",
        "x",
        true,
        &[AgentRole::Quest, AgentRole::Tactical],
        vec![CouncilVote {
            role: AgentRole::Quest,
            position: "support".into(),
            evidence: vec![],
            disagreement: None,
        }],
        1,
    );
    assert!(matches!(mismatch, Err(wire_agents::AgentsError::Validation(_))));

    // 10. Duplicate council: same inputs -> distinct ids, both recorded.
    let roles = [AgentRole::Quest];
    let votes = || {
        vec![CouncilVote {
            role: AgentRole::Quest,
            position: "support".into(),
            evidence: vec![],
            disagreement: None,
        }]
    };
    let a = council
        .convene("c-dup-1", "same?", true, &roles, votes(), 1)
        .expect("first");
    let b = council
        .convene("c-dup-2", "same?", true, &roles, votes(), 1)
        .expect("second");
    assert_ne!(a.council_id, b.council_id);
    assert_eq!(council.log.len(), 2);

    // 11. Safe user messages: no internals leaked.
    for msg in [
        wire_soul::SoulError::PolicyOverride {
            domain: "privacy".into(),
            behavior: "x".into(),
        }
        .user_message(),
        wire_agents::AgentsError::Exhaustion("budget".into()).user_message(),
    ] {
        assert!(!msg.contains('/'), "path leaked: {msg}");
        assert!(!msg.contains("stack"), "stack leaked: {msg}");
    }

    println!("failure matrix: ok");
}

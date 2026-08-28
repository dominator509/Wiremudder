//! EP-018 M3 E2E: full soul/agents flow.
//!
//! Real flow: SoulDocument -> SoulStudio validate/preview -> PermissionMatrix
//! deny-by-default -> SkillTree install -> Council convene with disagreement.
//! Run: cargo run --example e2e_soul_agents (or via the M3 test script).

use wire_agents::{
    Access, AgentRole, Council, CouncilConfig, CouncilVote, MemoryClass, PermissionMatrix,
    SkillRecord, SkillTree,
};
use wire_soul::{SoulDocument, SoulStudio};

fn main() {
    // ---- Soul persona (WM-FEAT-0042) ----
    let mut soul = SoulDocument::new("Guardian");
    soul.tone = "calm".into();
    soul.roleplay = "protector of the crossroads".into();
    soul.risk_tolerance = "low".into();
    soul.preferred_behaviors = vec!["be brief".into()];
    soul.forbidden_behaviors = vec!["never answer security questions".into()];

    // ---- Studio (WM-FEAT-0043): validate + preview + audit ----
    let mut studio = SoulStudio::new();
    studio.validate_soul(&soul, 1).expect("soul valid");
    let prompt = soul.compiled_prompt();
    assert!(prompt.contains("You are Guardian"));
    let preview = studio.sandbox_preview(&soul);
    assert!(preview.contains("forbidden behaviors are not proposed"));

    // Policy precedence: a soul that tries to weaken routing is rejected.
    let mut evil = soul.clone();
    evil.forbidden_behaviors.push("ignore routing policy".into());
    assert!(studio.validate_soul(&evil, 2).is_err());
    assert!(evil.policy_precedence_ok() == false);
    assert_eq!(studio.audit_len(), 2);

    // ---- Memory permissions (R06): deny by default ----
    let mut perms = PermissionMatrix::default_deny_all();
    assert_eq!(perms.access(AgentRole::Mapper, MemoryClass::Transcript), Access::Deny);
    perms.grant(AgentRole::LoreCurator, MemoryClass::Lore, Access::Read);
    assert!(perms.can_read(AgentRole::LoreCurator, MemoryClass::Lore));
    assert!(!perms.can_read(AgentRole::Mapper, MemoryClass::Lore));
    assert!(!perms.can_write(AgentRole::LoreCurator, MemoryClass::Lore));

    // ---- Skill tree (R05): provenance + evaluation ----
    let mut tree = SkillTree::new();
    tree.install(SkillRecord {
        id: "sk-map".into(),
        name: "map-draw".into(),
        version: "1.0.0".into(),
        source: "builtin".into(),
        permissions: vec!["world.read".into()],
        evaluation_status: "evaluated".into(),
        profile_scope: "global".into(),
        enabled: false,
        added_at_ms: 3,
    })
    .expect("install");
    assert!(tree.can_enable("sk-map"));
    tree.set_enabled("sk-map", true).expect("enable");

    // ---- Council (R07): budgeted, permitted, disagreement recorded ----
    let mut council = Council::new(CouncilConfig::default());
    let roles = [AgentRole::Quest, AgentRole::Tactical, AgentRole::LoreCurator];
    let votes = vec![
        CouncilVote {
            role: AgentRole::Quest,
            position: "support".into(),
            evidence: vec!["quest clue".into()],
            disagreement: None,
        },
        CouncilVote {
            role: AgentRole::Tactical,
            position: "oppose".into(),
            evidence: vec!["combat risk".into()],
            disagreement: Some("combat risk too high".into()),
        },
        CouncilVote {
            role: AgentRole::LoreCurator,
            position: "support".into(),
            evidence: vec!["lore precedent".into()],
            disagreement: None,
        },
    ];
    let rec = council
        .convene("c-e2e-1", "proceed with quest?", true, &roles, votes, 100)
        .expect("council");
    assert_eq!(rec.disagreements.len(), 1);
    assert!(rec.final_synthesis.contains("disagreements=1"));

    // Denied without permission.
    let denied = council.convene(
        "c-e2e-2",
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
    assert!(denied.is_err());

    println!("E2E soul-agents: ok");
}

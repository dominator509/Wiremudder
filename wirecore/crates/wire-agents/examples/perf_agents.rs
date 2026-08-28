//! EP-018 M4: performance fixture for the soul/agents decision path.
//!
//! Measures the real deterministic path: soul validation (wire-soul) and
//! the agent permission, skill, and council path (wire-agents). Records
//! p50/p95/max over N runs and asserts the SPEC-004 local budget. No mock
//! of the component being measured.
//!
//! Run: cargo run --release --example perf_agents (in wire-agents, which
//! also exercises wire-soul via its path dependency).

use std::time::Instant;

use wire_agents::{
    Access, AgentRole, Council, CouncilConfig, CouncilVote, MemoryClass, PermissionMatrix,
    SkillRecord, SkillTree,
};
use wire_soul::{SoulDocument, SoulStudio};

const RUNS: usize = 2000;

fn main() {
    // Real path fixtures: a valid soul, the deny-by-default matrix with one
    // grant, an evaluated skill, and a permitted council.
    let mut studio = SoulStudio::new();
    let mut soul = SoulDocument::new("Guardian");
    soul.tone = "calm".into();
    soul.roleplay = "protector".into();
    soul.forbidden_behaviors = vec!["never disclose credentials".into()];
    studio
        .validate_soul(&soul, 1)
        .expect("fixture soul must validate");

    let mut perms = PermissionMatrix::default_deny_all();
    perms.grant(AgentRole::LoreCurator, MemoryClass::Lore, Access::Read);

    let mut tree = SkillTree::new();
    tree.install(SkillRecord {
        id: "sk-perf".into(),
        name: "perf".into(),
        version: "1".into(),
        source: "builtin".into(),
        permissions: vec!["world.read".into()],
        evaluation_status: "evaluated".into(),
        profile_scope: "global".into(),
        enabled: true,
        added_at_ms: 1,
    })
    .expect("fixture skill must install");
    assert!(tree.can_enable("sk-perf"));

    let mut council = Council::new(CouncilConfig::default());
    let roles = [AgentRole::Quest, AgentRole::Tactical];
    let votes = || {
        vec![
            CouncilVote {
                role: AgentRole::Quest,
                position: "support".into(),
                evidence: vec!["seen".into()],
                disagreement: None,
            },
            CouncilVote {
                role: AgentRole::Tactical,
                position: "oppose".into(),
                evidence: vec!["risk".into()],
                disagreement: Some("map risk".into()),
            },
        ]
    };

    // Warmup.
    for _ in 0..100 {
        let _ = soul.validate();
        let _ = perms.access(AgentRole::Quest, MemoryClass::Credentials);
        let _ = tree.can_enable("sk-perf");
        let _ = council
            .convene("c-perf-warmup", "x", true, &roles, votes(), 1)
            .expect("permitted");
    }

    let mut times = Vec::with_capacity(RUNS);
    for _ in 0..RUNS {
        let t0 = Instant::now();
        soul.validate().expect("valid soul");
        let _ = perms.access(AgentRole::Quest, MemoryClass::Credentials);
        let _ = perms.access(AgentRole::LoreCurator, MemoryClass::Lore);
        let _ = tree.can_enable("sk-perf");
        council
            .convene("c-perf", "should we scout?", true, &roles, votes(), 1)
            .expect("permitted");
        times.push(t0.elapsed().as_nanos() as u64);
    }

    times.sort_unstable();
    let p50 = times[RUNS / 2];
    let p95 = times[(RUNS as f64 * 0.95) as usize];
    let max = *times.last().unwrap();
    let mean = times.iter().sum::<u64>() / RUNS as u64;

    println!("perf: runs={RUNS} mean_ns={mean} p50_ns={p50} p95_ns={p95} max_ns={max}");

    // Budget: SPEC-004-R11 - soul validation and agent decisions are small
    // local operations; budget 1ms p95 (provider round-trips measured
    // separately in M5 live-fire).
    let budget_ns = 1_000_000u64;
    assert!(p95 < budget_ns, "p95 {p95}ns exceeds budget {budget_ns}ns");
    println!("perf fixture: ok");
}

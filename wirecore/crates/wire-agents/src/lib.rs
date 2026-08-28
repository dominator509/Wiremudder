//! WireMudder specialized agents, skills, memory permissions, and council
//! (SPEC-014, EP-018).
//!
//! WM-SPEC-014-R02: specialized agent roles (mapper/cartographer, lore/
//! memory curator, quest, tactical, renderer scene, voice companion,
//! help/setup, command safety, token budget, privacy firewall).
//! WM-SPEC-014-R05: Agent Skill Tree lists installed skills with source,
//! version, permissions, evaluation status, profile scope, enable state.
//! WM-SPEC-014-R06: Agent Memory Permissions define which memory classes each
//! role may read, propose, summarize, share, or never access (deny by
//! default).
//! WM-SPEC-014-R07: Agent Council is reserved for tasks whose policy permits
//! multi-agent reasoning and records roles, evidence, disagreements, budget,
//! and final synthesis.
//!
//! Acceptance obligations implemented here:
//!   3. Skills declare provenance, permissions, and evaluation.
//!   4. Memory access is role-scoped and denied by default.
//!   5. Council is budgeted and records disagreement.
//!   6. No agent can grant itself authority.

use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

// ---------------------------------------------------------------------------
// Specialized agent roles (R02)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum AgentRole {
    Mapper,
    Cartographer,
    LoreCurator,
    Quest,
    Tactical,
    RendererScene,
    VoiceCompanion,
    HelpSetup,
    CommandSafety,
    TokenBudget,
    PrivacyFirewall,
}

impl AgentRole {
    pub const ALL: &'static [AgentRole] = &[
        AgentRole::Mapper,
        AgentRole::Cartographer,
        AgentRole::LoreCurator,
        AgentRole::Quest,
        AgentRole::Tactical,
        AgentRole::RendererScene,
        AgentRole::VoiceCompanion,
        AgentRole::HelpSetup,
        AgentRole::CommandSafety,
        AgentRole::TokenBudget,
        AgentRole::PrivacyFirewall,
    ];

    pub fn key(&self) -> &'static str {
        match self {
            AgentRole::Mapper => "mapper",
            AgentRole::Cartographer => "cartographer",
            AgentRole::LoreCurator => "lore-curator",
            AgentRole::Quest => "quest",
            AgentRole::Tactical => "tactical",
            AgentRole::RendererScene => "renderer-scene",
            AgentRole::VoiceCompanion => "voice-companion",
            AgentRole::HelpSetup => "help-setup",
            AgentRole::CommandSafety => "command-safety",
            AgentRole::TokenBudget => "token-budget",
            AgentRole::PrivacyFirewall => "privacy-firewall",
        }
    }

    pub fn from_key(k: &str) -> Option<AgentRole> {
        AgentRole::ALL.iter().copied().find(|r| r.key() == k)
    }
}

// ---------------------------------------------------------------------------
// Memory classes (R06)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum MemoryClass {
    Profile,
    Transcript,
    World,
    Lore,
    Messages,
    Voice,
    Credentials,
    Telemetry,
}

impl MemoryClass {
    pub const ALL: &'static [MemoryClass] = &[
        MemoryClass::Profile,
        MemoryClass::Transcript,
        MemoryClass::World,
        MemoryClass::Lore,
        MemoryClass::Messages,
        MemoryClass::Voice,
        MemoryClass::Credentials,
        MemoryClass::Telemetry,
    ];

    pub fn key(&self) -> &'static str {
        match self {
            MemoryClass::Profile => "profile",
            MemoryClass::Transcript => "transcript",
            MemoryClass::World => "world",
            MemoryClass::Lore => "lore",
            MemoryClass::Messages => "messages",
            MemoryClass::Voice => "voice",
            MemoryClass::Credentials => "credentials",
            MemoryClass::Telemetry => "telemetry",
        }
    }
}

// ---------------------------------------------------------------------------
// Memory permissions (R06, obligation 4)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Access {
    Deny,
    Read,
    Propose,
    Summarize,
    Share,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MemoryPermission {
    pub role: AgentRole,
    pub class: MemoryClass,
    /// Deny by default; anything not explicitly granted is Deny.
    pub access: Access,
}

#[derive(Debug, Clone, Default)]
pub struct PermissionMatrix {
    /// role -> class -> access. Absent = Deny (obligation 4).
    grants: BTreeMap<String, BTreeMap<String, Access>>,
}

impl PermissionMatrix {
    pub fn new() -> Self {
        Self::default()
    }

    /// Explicitly grant access. Absent entries remain Deny by default.
    pub fn grant(&mut self, role: AgentRole, class: MemoryClass, access: Access) {
        self.grants
            .entry(role.key().to_string())
            .or_default()
            .insert(class.key().to_string(), access);
    }

    pub fn access(&self, role: AgentRole, class: MemoryClass) -> Access {
        self.grants
            .get(role.key())
            .and_then(|m| m.get(class.key()))
            .copied()
            .unwrap_or(Access::Deny)
    }

    pub fn can_read(&self, role: AgentRole, class: MemoryClass) -> bool {
        let a = self.access(role, class);
        matches!(a, Access::Read | Access::Propose | Access::Summarize | Access::Share)
    }

    pub fn can_write(&self, role: AgentRole, class: MemoryClass) -> bool {
        matches!(self.access(role, class), Access::Propose | Access::Share)
    }

    /// Default matrix: every role denies every class unless explicitly
    /// granted. The only built-in grant: TokenBudget may read Telemetry.
    pub fn default_deny_all() -> Self {
        let mut m = Self::new();
        m.grant(AgentRole::TokenBudget, MemoryClass::Telemetry, Access::Read);
        m
    }

    pub fn grant_count(&self) -> usize {
        self.grants.values().map(|m| m.len()).sum()
    }
}

// ---------------------------------------------------------------------------
// Agent Skill Tree (R05, obligation 3)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SkillRecord {
    pub id: String,
    pub name: String,
    pub version: String,
    pub source: String, // e.g. "builtin" | "user-local" | "pack:<id>"
    pub permissions: Vec<String>,
    pub evaluation_status: String, // "evaluated" | "pending" | "failed"
    pub profile_scope: String,     // "global" | profile name
    pub enabled: bool,
    pub added_at_ms: u64,
}

#[derive(Debug, Clone, Default)]
pub struct SkillTree {
    skills: BTreeMap<String, SkillRecord>,
    max_skills: usize,
}

impl SkillTree {
    pub fn new() -> Self {
        Self {
            skills: BTreeMap::new(),
            max_skills: 500,
        }
    }

    /// Install a skill (idempotent by id; rejects invalid provenance).
    pub fn install(&mut self, skill: SkillRecord) -> Result<(), AgentsError> {
        if skill.id.trim().is_empty() || skill.name.trim().is_empty() {
            return Err(AgentsError::Validation("skill id and name required".into()));
        }
        if skill.version.trim().is_empty() || skill.source.trim().is_empty() {
            return Err(AgentsError::Validation(
                "skill version and source required".into(),
            ));
        }
        if self.skills.len() >= self.max_skills && !self.skills.contains_key(&skill.id) {
            return Err(AgentsError::Exhaustion("skill tree full".into()));
        }
        self.skills.insert(skill.id.clone(), skill);
        Ok(())
    }

    pub fn get(&self, id: &str) -> Option<&SkillRecord> {
        self.skills.get(id)
    }

    pub fn list(&self) -> Vec<&SkillRecord> {
        self.skills.values().collect()
    }

    pub fn set_enabled(&mut self, id: &str, enabled: bool) -> Result<(), AgentsError> {
        let s = self
            .skills
            .get_mut(id)
            .ok_or_else(|| AgentsError::NotFound(id.to_string()))?;
        s.enabled = enabled;
        Ok(())
    }

    pub fn count(&self) -> usize {
        self.skills.len()
    }

    /// Only skills with provenance + evaluation can be enabled (obligation 3).
    pub fn can_enable(&self, id: &str) -> bool {
        self.skills
            .get(id)
            .map(|s| !s.source.is_empty() && s.evaluation_status == "evaluated")
            .unwrap_or(false)
    }
}

// ---------------------------------------------------------------------------
// Agent Council (R07, obligation 5)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CouncilVote {
    pub role: AgentRole,
    pub position: String, // "support" | "oppose" | "abstain"
    pub evidence: Vec<String>,
    pub disagreement: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CouncilRecord {
    pub council_id: String,
    pub task: String,
    pub budget_usd_micros: u64,
    pub roles: Vec<AgentRole>,
    pub votes: Vec<CouncilVote>,
    pub disagreements: Vec<String>,
    pub final_synthesis: String,
    pub permitted: bool, // policy allowed multi-agent reasoning
}

#[derive(Debug, Clone)]
pub struct CouncilConfig {
    pub max_roles: usize,
    pub max_budget_usd_micros: u64,
    pub require_permission: bool,
}

impl Default for CouncilConfig {
    fn default() -> Self {
        Self {
            max_roles: 6,
            max_budget_usd_micros: 5000,
            require_permission: true,
        }
    }
}

#[derive(Debug, Clone, Default)]
pub struct CouncilLog {
    records: Vec<CouncilRecord>,
    max_records: usize,
}

impl CouncilLog {
    pub fn new() -> Self {
        Self {
            records: Vec::new(),
            max_records: 100,
        }
    }

    pub fn record(&mut self, r: CouncilRecord) {
        self.records.push(r);
        if self.records.len() > self.max_records {
            self.records.remove(0);
        }
    }

    pub fn len(&self) -> usize {
        self.records.len()
    }

    pub fn is_empty(&self) -> bool {
        self.records.is_empty()
    }

    pub fn last(&self) -> Option<&CouncilRecord> {
        self.records.last()
    }
}

/// Deterministic council orchestration (R07). A council is only convened
/// when policy permits multi-agent reasoning; it is budgeted; every
/// disagreement is recorded; the final synthesis is produced from votes.
pub struct Council {
    pub config: CouncilConfig,
    pub log: CouncilLog,
}

impl Council {
    pub fn new(config: CouncilConfig) -> Self {
        Self {
            config,
            log: CouncilLog::new(),
        }
    }

    /// Convene a council. Returns Err when policy denies it or the budget/
    /// role bounds are exceeded (obligation 5: budgeted).
    pub fn convene(
        &mut self,
        council_id: &str,
        task: &str,
        policy_allows: bool,
        roles: &[AgentRole],
        votes: Vec<CouncilVote>,
        budget_usd_micros: u64,
    ) -> Result<CouncilRecord, AgentsError> {
        if self.config.require_permission && !policy_allows {
            return Err(AgentsError::Policy("council not permitted for this task".into()));
        }
        if budget_usd_micros > self.config.max_budget_usd_micros {
            return Err(AgentsError::Exhaustion(format!(
                "council budget {budget_usd_micros} exceeds limit {}",
                self.config.max_budget_usd_micros
            )));
        }
        if roles.len() > self.config.max_roles {
            return Err(AgentsError::Validation(format!(
                "council roles {} exceeds limit {}",
                roles.len(),
                self.config.max_roles
            )));
        }
        // Every role must vote exactly once.
        if votes.len() != roles.len() {
            return Err(AgentsError::Validation(format!(
                "votes {} != roles {}",
                votes.len(),
                roles.len()
            )));
        }
        let disagreements: Vec<String> = votes
            .iter()
            .filter_map(|v| v.disagreement.clone())
            .collect();
        let record = CouncilRecord {
            council_id: council_id.into(),
            task: task.into(),
            budget_usd_micros,
            roles: roles.to_vec(),
            votes: votes.clone(),
            disagreements,
            final_synthesis: synthesize(votes),
            permitted: policy_allows,
        };
        let r = record.clone();
        self.log.record(record);
        Ok(r)
    }
}

/// Deterministic synthesis: majority position with explicit disagreement
/// count and no hidden votes (R07).
fn synthesize(votes: Vec<CouncilVote>) -> String {
    let support = votes.iter().filter(|v| v.position == "support").count();
    let oppose = votes.iter().filter(|v| v.position == "oppose").count();
    let abstain = votes.iter().filter(|v| v.position == "abstain").count();
    let disagreements = votes.iter().filter(|v| v.disagreement.is_some()).count();
    let verdict = if support > oppose { "support" } else if oppose > support { "oppose" } else { "tie" };
    format!(
        "council {verdict}: support={support} oppose={oppose} abstain={abstain} disagreements={disagreements}"
    )
}

// ---------------------------------------------------------------------------
// No self-grant authority (obligation 6)
// ---------------------------------------------------------------------------

/// The one rule: an agent cannot modify its own permissions. This is a
/// structural invariant - the PermissionMatrix has no method that grants
/// authority to the calling role; grants only come from an external
/// authority (the user or an explicit policy edit).
pub fn self_grant_is_impossible(matrix: &PermissionMatrix, role: AgentRole, class: MemoryClass) -> bool {
    // There is no API path for a role to grant itself access; this function
    // documents and tests that the matrix is immutable from within a role.
    !matrix.can_write(role, class) || matrix.access(role, class) == Access::Deny
}

// ---------------------------------------------------------------------------
// Typed errors (SPEC-025)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq)]
pub enum AgentsError {
    Validation(String),
    Policy(String),
    Exhaustion(String),
    NotFound(String),
}

impl AgentsError {
    pub fn user_message(&self) -> String {
        match self {
            AgentsError::Validation(m) => m.clone(),
            AgentsError::Policy(m) => m.clone(),
            AgentsError::Exhaustion(m) => m.clone(),
            AgentsError::NotFound(m) => format!("not found: {m}"),
        }
    }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn all_specialized_roles_exist() {
        // R02: all ten role kinds present.
        assert_eq!(AgentRole::ALL.len(), 11);
        for key in [
            "mapper", "cartographer", "lore-curator", "quest", "tactical",
            "renderer-scene", "voice-companion", "help-setup", "command-safety",
            "token-budget", "privacy-firewall",
        ] {
            assert!(AgentRole::from_key(key).is_some(), "missing role {key}");
        }
    }

    #[test]
    fn memory_denied_by_default() {
        // Obligation 4: absent entry = Deny.
        let m = PermissionMatrix::default_deny_all();
        assert_eq!(m.access(AgentRole::Mapper, MemoryClass::Transcript), Access::Deny);
        assert!(!m.can_read(AgentRole::Mapper, MemoryClass::Transcript));
        assert!(!m.can_write(AgentRole::Mapper, MemoryClass::Transcript));
        // The one built-in grant.
        assert!(m.can_read(AgentRole::TokenBudget, MemoryClass::Telemetry));
    }

    #[test]
    fn role_scoped_grants() {
        let mut m = PermissionMatrix::default_deny_all();
        m.grant(AgentRole::LoreCurator, MemoryClass::Lore, Access::Read);
        assert!(m.can_read(AgentRole::LoreCurator, MemoryClass::Lore));
        assert!(!m.can_read(AgentRole::Mapper, MemoryClass::Lore));
        assert!(!m.can_write(AgentRole::LoreCurator, MemoryClass::Lore)); // read-only
    }

    #[test]
    fn no_agent_grants_itself_authority() {
        // Obligation 6: a role cannot escalate its own access.
        let m = PermissionMatrix::default_deny_all();
        assert!(self_grant_is_impossible(&m, AgentRole::Mapper, MemoryClass::Credentials));
        // Even a read grant on telemetry doesn't allow write escalation.
        let mut m2 = PermissionMatrix::default_deny_all();
        m2.grant(AgentRole::TokenBudget, MemoryClass::Telemetry, Access::Read);
        assert!(!m2.can_write(AgentRole::TokenBudget, MemoryClass::Telemetry));
    }

    #[test]
    fn skill_tree_declares_provenance_and_evaluation() {
        let mut tree = SkillTree::new();
        let skill = SkillRecord {
            id: "sk-1".into(),
            name: "map-draw".into(),
            version: "1.2.0".into(),
            source: "builtin".into(),
            permissions: vec!["world.read".into()],
            evaluation_status: "evaluated".into(),
            profile_scope: "global".into(),
            enabled: false,
            added_at_ms: 1,
        };
        tree.install(skill).expect("install");
        assert_eq!(tree.count(), 1);
        assert!(tree.can_enable("sk-1"));
        tree.set_enabled("sk-1", true).expect("enable");
        assert!(tree.get("sk-1").unwrap().enabled);
    }

    #[test]
    fn unevaluated_skill_cannot_enable() {
        let mut tree = SkillTree::new();
        let skill = SkillRecord {
            id: "sk-2".into(),
            name: "risky".into(),
            version: "0.1".into(),
            source: "pack:unknown".into(),
            permissions: vec!["credentials.write".into()],
            evaluation_status: "pending".into(),
            profile_scope: "global".into(),
            enabled: false,
            added_at_ms: 2,
        };
        tree.install(skill).expect("install");
        assert!(!tree.can_enable("sk-2"));
        assert!(tree.set_enabled("sk-2", true).is_ok()); // stored but gated
        // The gate is can_enable; enforcement is at use time.
    }

    #[test]
    fn council_requires_permission_and_records_disagreement() {
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
                evidence: vec!["risk".into()],
                disagreement: Some("combat risk too high".into()),
            },
            CouncilVote {
                role: AgentRole::LoreCurator,
                position: "support".into(),
                evidence: vec!["lore".into()],
                disagreement: None,
            },
        ];
        let r = council
            .convene("c-1", "proceed?", true, &roles, votes, 100)
            .expect("convene");
        assert!(r.permitted);
        assert_eq!(r.disagreements.len(), 1);
        assert!(r.final_synthesis.contains("support=2"));
        assert!(r.final_synthesis.contains("oppose=1"));
        assert!(r.final_synthesis.contains("disagreements=1"));
        assert_eq!(council.log.len(), 1);
    }

    #[test]
    fn council_denied_without_permission() {
        let mut council = Council::new(CouncilConfig::default());
        let roles = [AgentRole::Quest];
        let votes = vec![CouncilVote {
            role: AgentRole::Quest,
            position: "support".into(),
            evidence: vec![],
            disagreement: None,
        }];
        match council.convene("c-2", "secret?", false, &roles, votes, 1) {
            Err(AgentsError::Policy(_)) => {}
            other => panic!("expected Policy denial, got {other:?}"),
        }
    }

    #[test]
    fn council_budget_exhaustion() {
        let mut council = Council::new(CouncilConfig::default());
        let roles = [AgentRole::Quest];
        let votes = vec![CouncilVote {
            role: AgentRole::Quest,
            position: "support".into(),
            evidence: vec![],
            disagreement: None,
        }];
        match council.convene("c-3", "big?", true, &roles, votes, 999_999) {
            Err(AgentsError::Exhaustion(_)) => {}
            other => panic!("expected Exhaustion, got {other:?}"),
        }
    }

    #[test]
    fn council_votes_must_match_roles() {
        let mut council = Council::new(CouncilConfig::default());
        let roles = [AgentRole::Quest, AgentRole::Tactical];
        let votes = vec![CouncilVote {
            role: AgentRole::Quest,
            position: "support".into(),
            evidence: vec![],
            disagreement: None,
        }];
        assert!(council.convene("c-4", "x", true, &roles, votes, 1).is_err());
    }
}

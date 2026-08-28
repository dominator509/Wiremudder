//! WireMudder World Brain (SPEC-012-R01/R02/R10, SPEC-023-R02/R03,
//! EP-021).
//!
//! Provenance-aware world memory: every fact records source event, time,
//! profile/world scope, confidence, sensitivity, model or rule version,
//! and supersession state. User corrections supersede derived facts
//! without erasing history. Hot current state and durable memory are
//! separate. The brain is an observer: it never sends commands.

use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

pub const WORLD_BRAIN_SCHEMA_VERSION: u32 = 1;

/// Sensitivity classes (SPEC-023-R05).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Sensitivity {
    Public,
    Private,
    Secret,
    Diagnostic,
}

impl Sensitivity {
    pub fn label(self) -> &'static str {
        match self {
            Sensitivity::Public => "public",
            Sensitivity::Private => "private",
            Sensitivity::Secret => "secret",
            Sensitivity::Diagnostic => "diagnostic",
        }
    }
}

/// Supersession state (SPEC-012-R02): a fact can be current, superseded
/// by a newer fact, or corrected by the user (history preserved).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Supersession {
    Current,
    Superseded,
    UserCorrected,
}

impl Supersession {
    pub fn label(self) -> &'static str {
        match self {
            Supersession::Current => "current",
            Supersession::Superseded => "superseded",
            Supersession::UserCorrected => "user-corrected",
        }
    }
}

/// One provenance-aware memory fact (SPEC-023-R02/R03).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MemoryFact {
    pub id: String,
    pub subject: String,       // e.g. "room:crossroads"
    pub attribute: String,     // e.g. "exit.north"
    pub value: String,
    pub source_event: String,  // e.g. "line:123" | "user-note" | "correction"
    pub actor: String,         // e.g. "player" | "ai" | "rule"
    pub profile_scope: String,
    pub world_scope: String,
    pub created_at_ms: u64,
    pub observed_at_ms: u64,
    pub confidence: f64,       // 0.0..=1.0
    pub model_or_rule_version: String,
    pub sensitivity: Sensitivity,
    pub supersession: Supersession,
    /// When user-corrected, the note describing the correction.
    pub correction_note: Option<String>,
    pub content_hash: String,
}

/// Typed errors (SPEC-025).
#[derive(Debug, Clone, PartialEq)]
pub enum WorldBrainError {
    Validation(String),
    NotFound(String),
    Exhaustion(String),
}

impl WorldBrainError {
    pub fn user_message(&self) -> String {
        match self {
            WorldBrainError::Validation(m) => m.clone(),
            WorldBrainError::NotFound(m) => format!("memory fact not found: {m}"),
            WorldBrainError::Exhaustion(m) => m.clone(),
        }
    }
}

/// A minimal content hash for provenance (SPEC-023-R02). Not a secret.
pub fn content_hash(subject: &str, attribute: &str, value: &str) -> String {
    let mut h: u64 = 1469598103934665603;
    for b in format!("{subject}|{attribute}|{value}").bytes() {
        h ^= u64::from(b);
        h = h.wrapping_mul(1099511628211);
    }
    format!("{h:016x}")
}

/// World Brain: bounded provenance-aware memory with separate hot and
/// durable views (SPEC-012-R03).
#[derive(Debug, Clone, Default)]
pub struct WorldBrain {
    facts: BTreeMap<String, MemoryFact>,
    hot_room: Option<String>,
    max_facts: usize,
}

impl WorldBrain {
    pub fn new() -> Self {
        Self {
            facts: BTreeMap::new(),
            hot_room: None,
            max_facts: 1000,
        }
    }

    /// Record an observed fact with full provenance. Derived facts may be
    /// superseded later; user corrections never erase history.
    pub fn observe(
        &mut self,
        subject: &str,
        attribute: &str,
        value: &str,
        source_event: &str,
        actor: &str,
        profile_scope: &str,
        world_scope: &str,
        now_ms: u64,
        confidence: f64,
        model_or_rule_version: &str,
        sensitivity: Sensitivity,
    ) -> Result<MemoryFact, WorldBrainError> {
        if subject.trim().is_empty() || attribute.trim().is_empty() {
            return Err(WorldBrainError::Validation("subject and attribute required".into()));
        }
        if value.trim().is_empty() {
            return Err(WorldBrainError::Validation("value required".into()));
        }
        if !(0.0..=1.0).contains(&confidence) {
            return Err(WorldBrainError::Validation("confidence outside [0,1]".into()));
        }
        if profile_scope.trim().is_empty() || world_scope.trim().is_empty() {
            return Err(WorldBrainError::Validation("profile and world scope required".into()));
        }
        if self.facts.len() >= self.max_facts {
            return Err(WorldBrainError::Exhaustion("world brain full".into()));
        }
        let id = format!("fact-{:08x}", self.facts.len() + 1);
        let fact = MemoryFact {
            id,
            subject: subject.to_string(),
            attribute: attribute.to_string(),
            value: value.to_string(),
            source_event: source_event.to_string(),
            actor: actor.to_string(),
            profile_scope: profile_scope.to_string(),
            world_scope: world_scope.to_string(),
            created_at_ms: now_ms,
            observed_at_ms: now_ms,
            confidence,
            model_or_rule_version: model_or_rule_version.to_string(),
            sensitivity,
            supersession: Supersession::Current,
            correction_note: None,
            content_hash: content_hash(subject, attribute, value),
        };
        // Supersede any prior current fact with the same subject+attribute.
        for f in self.facts.values_mut() {
            if f.subject == fact.subject
                && f.attribute == fact.attribute
                && f.supersession == Supersession::Current
                && f.id != fact.id
            {
                f.supersession = Supersession::Superseded;
            }
        }
        self.facts.insert(fact.id.clone(), fact.clone());
        Ok(fact)
    }

    /// User correction: supersedes the current derived fact and records
    /// the note, preserving history (SPEC-012-R10).
    pub fn correct(
        &mut self,
        subject: &str,
        attribute: &str,
        corrected_value: &str,
        note: &str,
        profile_scope: &str,
        world_scope: &str,
        now_ms: u64,
    ) -> Result<MemoryFact, WorldBrainError> {
        if corrected_value.trim().is_empty() || note.trim().is_empty() {
            return Err(WorldBrainError::Validation("corrected value and note required".into()));
        }
        let target = self
            .facts
            .values()
            .find(|f| f.subject == subject && f.attribute == attribute && f.supersession == Supersession::Current)
            .cloned()
            .ok_or_else(|| WorldBrainError::NotFound(format!("{subject}:{attribute}")))?;
        // Mark the derived fact user-corrected (history preserved).
        let mut f = target.clone();
        f.supersession = Supersession::UserCorrected;
        f.correction_note = Some(note.to_string());
        f.observed_at_ms = now_ms;
        self.facts.insert(f.id.clone(), f);
        // Record the correction fact as current.
        self.observe(
            subject,
            attribute,
            corrected_value,
            "user-correction",
            "player",
            profile_scope,
            world_scope,
            now_ms,
            1.0,
            "user",
            target.sensitivity,
        )
    }

    /// Hot current state: the observed current room (SPEC-012-R03 hot cache).
    pub fn set_hot_room(&mut self, room: &str) {
        self.hot_room = Some(room.to_string());
    }

    pub fn hot_room(&self) -> Option<&str> {
        self.hot_room.as_deref()
    }

    /// Current (non-superseded) fact for subject+attribute, if any.
    pub fn current(&self, subject: &str, attribute: &str) -> Option<&MemoryFact> {
        self.facts
            .values()
            .find(|f| f.subject == subject && f.attribute == attribute && f.supersession == Supersession::Current)
    }

    pub fn get(&self, id: &str) -> Option<&MemoryFact> {
        self.facts.get(id)
    }

    pub fn count(&self) -> usize {
        self.facts.len()
    }

    pub fn facts_for(&self, subject: &str) -> Vec<&MemoryFact> {
        self.facts.values().filter(|f| f.subject == subject).collect()
    }

    /// The brain is an observer: it can never send commands.
    pub fn can_send_command(&self) -> bool {
        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn brain() -> WorldBrain {
        let mut b = WorldBrain::new();
        b.observe(
            "room:crossroads", "exit.north", "room:gate", "line:10", "rule",
            "midkemia", "midkemia", 1, 0.9, "mapper-v1", Sensitivity::Public,
        )
        .unwrap();
        b
    }

    #[test]
    fn fact_records_provenance() {
        let b = brain();
        let f = b.current("room:crossroads", "exit.north").unwrap();
        assert_eq!(f.source_event, "line:10");
        assert_eq!(f.confidence, 0.9);
        assert_eq!(f.supersession, Supersession::Current);
        assert_eq!(f.sensitivity, Sensitivity::Public);
        assert!(!f.content_hash.is_empty());
    }

    #[test]
    fn new_fact_supersedes_old() {
        let mut b = brain();
        b.observe(
            "room:crossroads", "exit.north", "room:inn", "line:40", "rule",
            "midkemia", "midkemia", 2, 0.95, "mapper-v1", Sensitivity::Public,
        )
        .unwrap();
        let old = b.facts_for("room:crossroads");
        assert_eq!(old.len(), 2);
        assert_eq!(old[0].supersession, Supersession::Superseded);
        assert_eq!(b.current("room:crossroads", "exit.north").unwrap().value, "room:inn");
    }

    #[test]
    fn correction_supersedes_but_preserves_history() {
        let mut b = brain();
        b.correct(
            "room:crossroads", "exit.north", "room:tower", "the exit actually leads to the tower",
            "midkemia", "midkemia", 3,
        )
        .unwrap();
        assert_eq!(b.current("room:crossroads", "exit.north").unwrap().value, "room:tower");
        let corrected = b
            .facts_for("room:crossroads")
            .into_iter()
            .filter(|f| f.supersession == Supersession::UserCorrected)
            .count();
        assert_eq!(corrected, 1);
        // History preserved: the original derived fact is still present.
        assert!(b
            .facts_for("room:crossroads")
            .iter()
            .any(|f| f.value == "room:gate" && f.source_event == "line:10"));
    }

    #[test]
    fn validation_and_not_found() {
        let mut b = WorldBrain::new();
        assert!(b.observe("", "a", "v", "s", "r", "p", "w", 1, 0.5, "v", Sensitivity::Public).is_err());
        assert!(b.observe("s", "a", "", "s", "r", "p", "w", 1, 0.5, "v", Sensitivity::Public).is_err());
        assert!(b.observe("s", "a", "v", "s", "r", "p", "w", 1, 1.5, "v", Sensitivity::Public).is_err());
        assert!(b.correct("room:missing", "exit.north", "x", "n", "p", "w", 1).is_err());
    }

    #[test]
    fn hot_state_separate_from_durable() {
        let mut b = brain();
        assert!(b.hot_room().is_none());
        b.set_hot_room("room:gate");
        assert_eq!(b.hot_room(), Some("room:gate"));
        // Hot state does not create durable facts.
        assert_eq!(b.facts_for("room:gate").len(), 0);
    }

    #[test]
    fn brain_never_sends_commands() {
        let b = WorldBrain::new();
        assert!(!b.can_send_command());
    }

    #[test]
    fn bounded_brain() {
        let mut b = WorldBrain::new();
        b.max_facts = 3;
        for i in 0..3 {
            b.observe(
                &format!("room:{i}"), "exit.north", "room:gate", "line", "rule",
                "p", "w", i, 0.5, "v", Sensitivity::Public,
            )
            .unwrap();
        }
        assert!(b.observe("room:9", "exit.north", "x", "line", "rule", "p", "w", 9, 0.5, "v", Sensitivity::Public).is_err());
    }
}

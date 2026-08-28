//! WireMudder Quest Compass (SPEC-012-R06, EP-020).
//!
//! Cited quest tracking: every quest carries clues with a source citation
//! and a state that distinguishes observed, inferred, completed, failed,
//! and user-corrected. The log is bounded and deterministic.

use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

pub const QUEST_SCHEMA_VERSION: u32 = 1;

/// Quest state classes (SPEC-012-R06).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum QuestState {
    Observed,
    Inferred,
    Completed,
    Failed,
    UserCorrected,
}

impl QuestState {
    pub fn label(self) -> &'static str {
        match self {
            QuestState::Observed => "observed",
            QuestState::Inferred => "inferred",
            QuestState::Completed => "completed",
            QuestState::Failed => "failed",
            QuestState::UserCorrected => "user-corrected",
        }
    }
}

/// One cited clue (SPEC-012-R06: quest state cites clues).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct QuestClue {
    pub text: String,
    /// Citation: where the clue came from (e.g. "room:crossroads",
    /// "memory:guard", "user-note").
    pub cited_from: String,
    pub at_ms: u64,
}

/// A user correction (SPEC-012-R06: user-corrected state).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct QuestCorrection {
    pub note: String,
    pub at_ms: u64,
}

/// One tracked quest.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct QuestEntry {
    pub id: String,
    pub title: String,
    pub state: QuestState,
    pub clues: Vec<QuestClue>,
    pub corrections: Vec<QuestCorrection>,
    pub updated_at_ms: u64,
}

/// Typed errors (SPEC-025).
#[derive(Debug, Clone, PartialEq)]
pub enum QuestError {
    Validation(String),
    NotFound(String),
    Exhaustion(String),
}

impl QuestError {
    pub fn user_message(&self) -> String {
        match self {
            QuestError::Validation(m) => m.clone(),
            QuestError::NotFound(m) => format!("quest not found: {m}"),
            QuestError::Exhaustion(m) => m.clone(),
        }
    }
}

/// Bounded quest log (Quest Compass).
#[derive(Debug, Clone, Default)]
pub struct QuestLog {
    quests: BTreeMap<String, QuestEntry>,
    max_quests: usize,
}

impl QuestLog {
    pub fn new() -> Self {
        Self {
            quests: BTreeMap::new(),
            max_quests: 500,
        }
    }

    /// Track or update a quest. Every update cites a clue source.
    pub fn track(
        &mut self,
        id: &str,
        title: &str,
        state: QuestState,
        clue_text: &str,
        cited_from: &str,
        at_ms: u64,
    ) -> Result<(), QuestError> {
        if id.trim().is_empty() || title.trim().is_empty() {
            return Err(QuestError::Validation("quest id and title required".into()));
        }
        if clue_text.trim().is_empty() || cited_from.trim().is_empty() {
            return Err(QuestError::Validation("clue text and citation required".into()));
        }
        if !self.quests.contains_key(id) && self.quests.len() >= self.max_quests {
            return Err(QuestError::Exhaustion("quest log full".into()));
        }
        let clue = QuestClue {
            text: clue_text.to_string(),
            cited_from: cited_from.to_string(),
            at_ms,
        };
        let entry = self.quests.entry(id.to_string()).or_insert_with(|| QuestEntry {
            id: id.to_string(),
            title: title.to_string(),
            state,
            clues: Vec::new(),
            corrections: Vec::new(),
            updated_at_ms: at_ms,
        });
        entry.title = title.to_string();
        entry.state = state;
        entry.clues.push(clue);
        entry.updated_at_ms = at_ms;
        Ok(())
    }

    pub fn add_clue(&mut self, id: &str, text: &str, cited_from: &str, at_ms: u64) -> Result<(), QuestError> {
        if text.trim().is_empty() || cited_from.trim().is_empty() {
            return Err(QuestError::Validation("clue text and citation required".into()));
        }
        let entry = self
            .quests
            .get_mut(id)
            .ok_or_else(|| QuestError::NotFound(id.to_string()))?;
        entry.clues.push(QuestClue {
            text: text.to_string(),
            cited_from: cited_from.to_string(),
            at_ms,
        });
        entry.updated_at_ms = at_ms;
        Ok(())
    }

    pub fn set_state(&mut self, id: &str, state: QuestState, at_ms: u64) -> Result<(), QuestError> {
        let entry = self
            .quests
            .get_mut(id)
            .ok_or_else(|| QuestError::NotFound(id.to_string()))?;
        entry.state = state;
        entry.updated_at_ms = at_ms;
        Ok(())
    }

    /// User correction: moves the quest to UserCorrected and records the
    /// note (SPEC-012-R06).
    pub fn apply_correction(&mut self, id: &str, note: &str, at_ms: u64) -> Result<(), QuestError> {
        if note.trim().is_empty() {
            return Err(QuestError::Validation("correction note required".into()));
        }
        let entry = self
            .quests
            .get_mut(id)
            .ok_or_else(|| QuestError::NotFound(id.to_string()))?;
        entry.state = QuestState::UserCorrected;
        entry.corrections.push(QuestCorrection {
            note: note.to_string(),
            at_ms,
        });
        entry.updated_at_ms = at_ms;
        Ok(())
    }

    pub fn get(&self, id: &str) -> Option<&QuestEntry> {
        self.quests.get(id)
    }

    pub fn list(&self) -> Vec<&QuestEntry> {
        self.quests.values().collect()
    }

    pub fn count(&self) -> usize {
        self.quests.len()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn log() -> QuestLog {
        let mut l = QuestLog::new();
        l.track("q1", "Find the key", QuestState::Observed, "the guard mentioned a key", "room:gate", 1)
            .unwrap();
        l
    }

    #[test]
    fn quest_cites_clues() {
        let l = log();
        let q = l.get("q1").unwrap();
        assert_eq!(q.state, QuestState::Observed);
        assert_eq!(q.clues[0].cited_from, "room:gate");
        assert_eq!(q.clues[0].text, "the guard mentioned a key");
    }

    #[test]
    fn state_transitions_distinct() {
        let mut l = log();
        l.set_state("q1", QuestState::Completed, 2).unwrap();
        assert_eq!(l.get("q1").unwrap().state, QuestState::Completed);
        l.set_state("q1", QuestState::Failed, 3).unwrap();
        assert_eq!(l.get("q1").unwrap().state, QuestState::Failed);
        l.apply_correction("q1", "the quest is actually still active", 4).unwrap();
        assert_eq!(l.get("q1").unwrap().state, QuestState::UserCorrected);
        assert_eq!(l.get("q1").unwrap().corrections.len(), 1);
    }

    #[test]
    fn inferred_state_supported() {
        let mut l = log();
        l.track("q2", "Find the thief", QuestState::Inferred, "likely the hooded figure", "memory:crossroads", 5)
            .unwrap();
        assert_eq!(l.get("q2").unwrap().state, QuestState::Inferred);
    }

    #[test]
    fn validation_and_not_found() {
        let mut l = QuestLog::new();
        assert!(l.track("", "x", QuestState::Observed, "c", "s", 1).is_err());
        assert!(l.track("q", "x", QuestState::Observed, "", "s", 1).is_err());
        assert!(l.set_state("missing", QuestState::Completed, 1).is_err());
        assert!(l.apply_correction("missing", "note", 1).is_err());
    }

    #[test]
    fn bounded_log() {
        let mut l = QuestLog::new();
        l.max_quests = 3;
        for i in 0..3 {
            l.track(&format!("q{i}"), "t", QuestState::Observed, "c", "s", i).unwrap();
        }
        assert!(l.track("q3", "t", QuestState::Observed, "c", "s", 3).is_err());
    }

    #[test]
    fn safe_messages() {
        assert!(!QuestError::NotFound("x".into()).user_message().contains('/'));
        assert!(!QuestError::Exhaustion("full".into()).user_message().contains("stack"));
    }
}

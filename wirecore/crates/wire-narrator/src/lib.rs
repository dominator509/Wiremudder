//! WireMudder Personal Narrator (SPEC-015-R06, EP-020).
//!
//! Spoken or text summaries that disclose their source, respect privacy
//! (redaction), shed load when busy, and never send commands by
//! themselves. Summaries are deterministic text built from real state
//! (quest log, tactical snapshots); uncertainty is visible.

use serde::{Deserialize, Serialize};
use wire_quest::{QuestLog, QuestState};
use wire_tactical::TacticalHud;

pub const NARRATOR_SCHEMA_VERSION: u32 = 1;

/// A narrator summary with source disclosure and privacy flag.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct NarratorSummary {
    pub text: String,
    /// Source disclosure (SPEC-015-R06): which feature produced this.
    pub source: String,
    /// Citations for the summary content.
    pub cites: Vec<String>,
    /// True when any redaction was applied (privacy).
    pub redacted: bool,
    pub at_ms: u64,
}

/// Typed errors (SPEC-025).
#[derive(Debug, Clone, PartialEq)]
pub enum NarratorError {
    LoadShedding,
    Validation(String),
}

impl NarratorError {
    pub fn user_message(&self) -> String {
        match self {
            NarratorError::LoadShedding => "narrator is shedding load".into(),
            NarratorError::Validation(m) => m.clone(),
        }
    }
}

/// Personal Narrator. Bounded recent-summary buffer; load shedding drops
/// non-critical narration when busy.
#[derive(Debug, Clone, Default)]
pub struct Narrator {
    recent: Vec<NarratorSummary>,
    max_recent: usize,
    shedding: bool,
}

impl Narrator {
    pub fn new() -> Self {
        Self {
            recent: Vec::new(),
            max_recent: 50,
            shedding: false,
        }
    }

    pub fn set_load_shedding(&mut self, on: bool) {
        self.shedding = on;
    }

    pub fn shedding(&self) -> bool {
        self.shedding
    }

    /// Emit a summary. Under load shedding, non-critical narration is
    /// dropped (obligation: narrator respects load shedding).
    pub fn narrate(
        &mut self,
        text: &str,
        source: &str,
        cites: &[String],
        redacted: bool,
        at_ms: u64,
    ) -> Result<NarratorSummary, NarratorError> {
        if text.trim().is_empty() || source.trim().is_empty() {
            return Err(NarratorError::Validation("summary text and source required".into()));
        }
        if self.shedding {
            return Err(NarratorError::LoadShedding);
        }
        let s = NarratorSummary {
            text: text.to_string(),
            source: source.to_string(),
            cites: cites.to_vec(),
            redacted,
            at_ms,
        };
        self.recent.push(s.clone());
        if self.recent.len() > self.max_recent {
            self.recent.remove(0);
        }
        Ok(s)
    }

    /// Deterministic quest summary with citation and visible uncertainty
    /// (inferred/user-corrected states are marked).
    pub fn summarize_quest(&self, log: &QuestLog, quest_id: &str) -> Result<String, NarratorError> {
        let q = log
            .get(quest_id)
            .ok_or_else(|| NarratorError::Validation("quest not found".into()))?;
        let mut text = format!(
            "Quest '{}' is {}.",
            q.title,
            q.state.label()
        );
        for clue in q.clues.iter().rev().take(3) {
            text.push_str(&format!("\n- Clue ({}): {}", clue.cited_from, clue.text));
        }
        if q.state == QuestState::Inferred {
            text.push_str("\n(uncertainty: inferred, not yet observed)");
        }
        if q.state == QuestState::UserCorrected {
            text.push_str("\n(uncertainty: user correction applied)");
        }
        Ok(text)
    }

    /// Deterministic tactical summary from the HUD's bounded current
    /// snapshot.
    pub fn summarize_tactical(&self, hud: &TacticalHud) -> String {
        match hud.current() {
            None => "No tactical snapshot available.".to_string(),
            Some(s) => format!(
                "Tactical: {} | health {}% | energy {}% | threat {} | nearby: {}",
                s.room,
                s.health_pct,
                s.energy_pct,
                s.threat_level,
                if s.nearby_entities.is_empty() {
                    "none".to_string()
                } else {
                    s.nearby_entities.join(", ")
                }
            ),
        }
    }

    /// Redaction helper: replace secret-shaped tokens with [redacted]
    /// (privacy, SPEC-015-R06). The full token value after the marker is
    /// scrubbed up to whitespace or punctuation.
    pub fn redact(&self, input: &str) -> (String, bool) {
        let markers = ["sk-", "sbp_", "Bearer ", "password=", "api_key=", "secret="];
        let mut redacted = false;
        let mut out = input.to_string();
        for m in markers {
            let needle = m.to_lowercase();
            loop {
                let lower = out.to_lowercase();
                let Some(rel) = lower.find(needle.as_str()) else { break };
                let idx = rel;
                let end = out[idx + m.len()..]
                    .find(|c: char| c.is_whitespace() || c == ',' || c == ';' || c == '"' || c == '\'')
                    .map(|e| idx + m.len() + e)
                    .unwrap_or(out.len());
                out.replace_range(idx..end, "[redacted]");
                redacted = true;
            }
        }
        (out, redacted)
    }

    pub fn recent(&self) -> &[NarratorSummary] {
        &self.recent
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use wire_quest::{QuestLog, QuestState};
    use wire_tactical::{TacticalHud, TacticalSnapshot};

    #[test]
    fn narrator_discloses_source() {
        let mut n = Narrator::new();
        let s = n
            .narrate("You are at the crossroads.", "quest", &["q1".into()], false, 1)
            .unwrap();
        assert_eq!(s.source, "quest");
        assert_eq!(s.cites, vec!["q1".to_string()]);
    }

    #[test]
    fn load_shedding_drops_narration() {
        let mut n = Narrator::new();
        n.set_load_shedding(true);
        assert_eq!(
            n.narrate("busy", "quest", &[], false, 1),
            Err(NarratorError::LoadShedding)
        );
    }

    #[test]
    fn quest_summary_cites_and_marks_uncertainty() {
        let mut log = QuestLog::new();
        log.track("q1", "Find the key", QuestState::Inferred, "the guard mentioned a key", "room:gate", 1)
            .unwrap();
        let n = Narrator::new();
        let text = n.summarize_quest(&log, "q1").unwrap();
        assert!(text.contains("is inferred"));
        assert!(text.contains("(room:gate)"));
        assert!(text.contains("uncertainty"));
    }

    #[test]
    fn tactical_summary_from_bounded_snapshot() {
        let mut hud = TacticalHud::new();
        hud.update(
            TacticalSnapshot {
                room: "crossroads".into(),
                health_pct: 80,
                energy_pct: 50,
                nearby_entities: vec!["guard".into()],
                threat_level: "low".into(),
                at_ms: 1,
            },
            1,
        )
        .unwrap();
        let n = Narrator::new();
        let text = n.summarize_tactical(&hud);
        assert!(text.contains("crossroads"));
        assert!(text.contains("guard"));
    }

    #[test]
    fn redaction_removes_secrets() {
        let n = Narrator::new();
        let (out, redacted) = n.redact("key is sk-abcdef123 and password=hunter2");
        assert!(redacted);
        assert!(!out.contains("sk-abcdef123"));
        assert!(!out.contains("hunter2"));
        assert!(out.contains("[redacted]"));
    }

    #[test]
    fn redaction_scrubs_repeated_markers() {
        let n = Narrator::new();
        let (out, redacted) = n.redact("a=sk-one b=sk-two c=sk-three");
        assert!(redacted);
        assert!(!out.contains("sk-one"));
        assert!(!out.contains("sk-two"));
        assert!(!out.contains("sk-three"));
        assert_eq!(out.matches("[redacted]").count(), 3);
    }

    #[test]
    fn narrator_never_sends_commands() {
        // No command API exists on the narrator; summaries are text only.
        let n = Narrator::new();
        let _ = n;
    }
}

//! WireMudder Tactical HUD (SPEC-012-R07, EP-020).
//!
//! Consumes bounded current-state snapshots and never sends commands by
//! itself. The HUD keeps only the latest bounded snapshot; oversized or
//! stale updates are rejected or evicted deterministically.

use std::collections::VecDeque;

use serde::{Deserialize, Serialize};

pub const TACTICAL_SCHEMA_VERSION: u32 = 1;

/// One bounded tactical snapshot of current state.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TacticalSnapshot {
    pub room: String,
    pub health_pct: u32,
    pub energy_pct: u32,
    pub nearby_entities: Vec<String>,
    pub threat_level: String, // none | low | medium | high | critical
    pub at_ms: u64,
}

/// Typed errors (SPEC-025).
#[derive(Debug, Clone, PartialEq)]
pub enum TacticalError {
    Oversized,
    StaleSnapshot,
    Validation(String),
}

impl TacticalError {
    pub fn user_message(&self) -> String {
        match self {
            TacticalError::Oversized => "tactical snapshot is oversized".into(),
            TacticalError::StaleSnapshot => "tactical snapshot is stale".into(),
            TacticalError::Validation(m) => m.clone(),
        }
    }
}

/// Tactical HUD: bounded, observer-only.
#[derive(Debug, Clone, Default)]
pub struct TacticalHud {
    latest: Option<TacticalSnapshot>,
    history: VecDeque<TacticalSnapshot>,
    max_history: usize,
    max_entities: usize,
}

impl TacticalHud {
    pub fn new() -> Self {
        Self {
            latest: None,
            history: VecDeque::new(),
            max_history: 20,
            max_entities: 64,
        }
    }

    /// Update with a bounded snapshot. Rejects oversized and stale input.
    pub fn update(&mut self, snap: TacticalSnapshot, now_ms: u64) -> Result<(), TacticalError> {
        if snap.room.trim().is_empty() {
            return Err(TacticalError::Validation("room required".into()));
        }
        if snap.nearby_entities.len() > self.max_entities {
            return Err(TacticalError::Oversized);
        }
        if let Some(prev) = &self.latest {
            if snap.at_ms < prev.at_ms {
                return Err(TacticalError::StaleSnapshot);
            }
        }
        self.history.push_back(snap.clone());
        if self.history.len() > self.max_history {
            self.history.pop_front();
        }
        self.latest = Some(snap);
        let _ = now_ms;
        Ok(())
    }

    pub fn current(&self) -> Option<&TacticalSnapshot> {
        self.latest.as_ref()
    }

    pub fn history(&self) -> impl Iterator<Item = &TacticalSnapshot> {
        self.history.iter()
    }

    pub fn clear(&mut self) {
        self.latest = None;
        self.history.clear();
    }

    /// The HUD is an observer: it can never send commands (SPEC-012-R07).
    pub fn can_send_command(&self) -> bool {
        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn snap(room: &str, at: u64) -> TacticalSnapshot {
        TacticalSnapshot {
            room: room.into(),
            health_pct: 80,
            energy_pct: 50,
            nearby_entities: vec!["guard".into()],
            threat_level: "low".into(),
            at_ms: at,
        }
    }

    #[test]
    fn hud_consumes_bounded_snapshot() {
        let mut hud = TacticalHud::new();
        hud.update(snap("crossroads", 100), 100).unwrap();
        assert_eq!(hud.current().unwrap().room, "crossroads");
    }

    #[test]
    fn oversized_snapshot_rejected() {
        let mut hud = TacticalHud::new();
        hud.max_entities = 2;
        let mut s = snap("crossroads", 1);
        s.nearby_entities = vec!["a".into(), "b".into(), "c".into()];
        assert_eq!(hud.update(s, 1), Err(TacticalError::Oversized));
    }

    #[test]
    fn stale_snapshot_rejected() {
        let mut hud = TacticalHud::new();
        hud.update(snap("crossroads", 200), 200).unwrap();
        assert_eq!(hud.update(snap("inn", 100), 300), Err(TacticalError::StaleSnapshot));
    }

    #[test]
    fn history_bounded() {
        let mut hud = TacticalHud::new();
        hud.max_history = 3;
        for i in 0..5u64 {
            hud.update(snap(&format!("room{i}"), i), i).unwrap();
        }
        assert_eq!(hud.history().count(), 3);
        assert_eq!(hud.current().unwrap().room, "room4");
    }

    #[test]
    fn hud_never_sends_commands() {
        let hud = TacticalHud::new();
        assert!(!hud.can_send_command(), "Tactical HUD must never send commands");
    }
}

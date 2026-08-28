//! WireMudder Time Machine (SPEC-012-R09, EP-021).
//!
//! Background, compacted, exportable snapshots of world memory that are
//! reversible only to user-approved checkpoints. A snapshot is a bounded
//! point-in-time view; restore requires an explicit user-approved
//! checkpoint and replaces the hot view without destroying durable
//! history. Snapshots are exported as deterministic JSON.

use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

pub const TIME_MACHINE_SCHEMA_VERSION: u32 = 1;

/// One snapshot point-in-time view (compacted representation).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Snapshot {
    pub id: String,
    pub label: String,
    /// Compacted view: subject -> (attribute -> value).
    pub view: BTreeMap<String, BTreeMap<String, String>>,
    pub at_ms: u64,
    pub user_approved: bool,
    pub schema_version: u32,
}

/// Typed errors (SPEC-025).
#[derive(Debug, Clone, PartialEq)]
pub enum TimeMachineError {
    Validation(String),
    NotFound(String),
    NotApproved(String),
    Exhaustion(String),
}

impl TimeMachineError {
    pub fn user_message(&self) -> String {
        match self {
            TimeMachineError::Validation(m) => m.clone(),
            TimeMachineError::NotFound(m) => format!("snapshot not found: {m}"),
            TimeMachineError::NotApproved(m) => m.clone(),
            TimeMachineError::Exhaustion(m) => m.clone(),
        }
    }
}

/// Time Machine: bounded snapshot history.
#[derive(Debug, Clone, Default)]
pub struct TimeMachine {
    snapshots: BTreeMap<String, Snapshot>,
    max_snapshots: usize,
}

impl TimeMachine {
    pub fn new() -> Self {
        Self {
            snapshots: BTreeMap::new(),
            max_snapshots: 50,
        }
    }

    /// Take a background snapshot (not user-approved yet). Compacts the
    /// view to subject/attribute/value.
    pub fn snapshot(
        &mut self,
        label: &str,
        view: BTreeMap<String, BTreeMap<String, String>>,
        at_ms: u64,
    ) -> Result<Snapshot, TimeMachineError> {
        if label.trim().is_empty() {
            return Err(TimeMachineError::Validation("snapshot label required".into()));
        }
        if self.snapshots.len() >= self.max_snapshots {
            return Err(TimeMachineError::Exhaustion("time machine full".into()));
        }
        let id = format!("snap-{:08x}", self.snapshots.len() + 1);
        let snap = Snapshot {
            id,
            label: label.to_string(),
            view,
            at_ms,
            user_approved: false,
            schema_version: TIME_MACHINE_SCHEMA_VERSION,
        };
        self.snapshots.insert(snap.id.clone(), snap.clone());
        Ok(snap)
    }

    /// Approve a checkpoint: restore is only possible from user-approved
    /// snapshots (SPEC-012-R09 reversible to user-approved checkpoints).
    pub fn approve(&mut self, id: &str) -> Result<(), TimeMachineError> {
        let snap = self
            .snapshots
            .get_mut(id)
            .ok_or_else(|| TimeMachineError::NotFound(id.to_string()))?;
        snap.user_approved = true;
        Ok(())
    }

    /// Restore the approved checkpoint's view. Fails closed if the
    /// snapshot is not user-approved. Durable history is untouched.
    pub fn restore(&self, id: &str) -> Result<BTreeMap<String, BTreeMap<String, String>>, TimeMachineError> {
        let snap = self
            .snapshots
            .get(id)
            .ok_or_else(|| TimeMachineError::NotFound(id.to_string()))?;
        if !snap.user_approved {
            return Err(TimeMachineError::NotApproved(
                "snapshot is not user-approved; restore denied".into(),
            ));
        }
        Ok(snap.view.clone())
    }

    pub fn get(&self, id: &str) -> Option<&Snapshot> {
        self.snapshots.get(id)
    }

    pub fn count(&self) -> usize {
        self.snapshots.len()
    }

    /// Export all snapshots as deterministic JSON (SPEC-012-R09 exportable).
    pub fn export_json(&self) -> Result<String, TimeMachineError> {
        let doc = serde_json::json!({
            "schema_version": TIME_MACHINE_SCHEMA_VERSION,
            "snapshots": self.snapshots,
        });
        serde_json::to_string_pretty(&doc)
            .map_err(|e| TimeMachineError::Validation(format!("export failed: {e}")))
    }

    /// The Time Machine is an observer: it can never send commands.
    pub fn can_send_command(&self) -> bool {
        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::BTreeMap;

    fn view(room: &str, exit: &str) -> BTreeMap<String, BTreeMap<String, String>> {
        let mut inner = BTreeMap::new();
        inner.insert("exit.north".to_string(), exit.to_string());
        let mut v = BTreeMap::new();
        v.insert(room.to_string(), inner);
        v
    }

    #[test]
    fn snapshot_requires_approval_to_restore() {
        let mut tm = TimeMachine::new();
        let s = tm.snapshot("checkpoint-1", view("room:crossroads", "room:gate"), 1).unwrap();
        // Fails closed without approval.
        assert_eq!(
            tm.restore(&s.id),
            Err(TimeMachineError::NotApproved("snapshot is not user-approved; restore denied".into()))
        );
        tm.approve(&s.id).unwrap();
        let restored = tm.restore(&s.id).unwrap();
        assert_eq!(restored["room:crossroads"]["exit.north"], "room:gate");
    }

    #[test]
    fn snapshots_are_compacted_and_bounded() {
        let mut tm = TimeMachine::new();
        tm.max_snapshots = 2;
        tm.snapshot("a", view("r1", "g"), 1).unwrap();
        tm.snapshot("b", view("r2", "g"), 2).unwrap();
        assert!(tm.snapshot("c", view("r3", "g"), 3).is_err());
        // Compaction: snapshot is subject/attribute/value only.
        let s = tm.get("snap-00000001").unwrap();
        assert!(s.view.contains_key("r1"));
    }

    #[test]
    fn export_is_deterministic() {
        let mut tm = TimeMachine::new();
        tm.snapshot("checkpoint-1", view("room:crossroads", "room:gate"), 1).unwrap();
        let d1 = tm.export_json().unwrap();
        let d2 = tm.export_json().unwrap();
        assert_eq!(d1, d2);
        assert!(d1.contains("snap-00000001"));
    }

    #[test]
    fn validation_and_not_found() {
        let mut tm = TimeMachine::new();
        assert!(tm.snapshot("", view("r", "g"), 1).is_err());
        assert!(tm.approve("missing").is_err());
        assert!(tm.restore("missing").is_err());
    }

    #[test]
    fn time_machine_never_sends_commands() {
        let tm = TimeMachine::new();
        assert!(!tm.can_send_command());
    }
}

//! Threat model (SPEC-022-R08).
//!
//! Threat models include data flow, assets, actors, entry points, trust
//! boundaries, misuse cases, mitigations, residual risk, and verification.

use serde::{Deserialize, Serialize};

/// One threat-model element category.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum ElementKind {
    DataFlow,
    Asset,
    Actor,
    EntryPoint,
    TrustBoundary,
    MisuseCase,
    Mitigation,
    ResidualRisk,
    Verification,
}

/// A single named element in a threat model.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ThreatElement {
    pub kind: ElementKind,
    pub name: String,
    pub detail: String,
    /// Trust-boundary names this element covers. Only meaningful for
    /// Mitigation elements; other kinds carry an empty list.
    #[serde(default)]
    pub covers: Vec<String>,
}

/// A complete threat model covering the SPEC-022-R08 element set.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ThreatModel {
    pub id: String,
    pub scope: String,
    pub elements: Vec<ThreatElement>,
}

/// Validation error for an incomplete threat model.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ThreatModelError(pub String);

impl ThreatModel {
    pub fn new(id: &str, scope: &str) -> Self {
        Self {
            id: id.to_string(),
            scope: scope.to_string(),
            elements: Vec::new(),
        }
    }

    pub fn add(&mut self, kind: ElementKind, name: &str, detail: &str) {
        self.elements.push(ThreatElement {
            kind,
            name: name.to_string(),
            detail: detail.to_string(),
            covers: Vec::new(),
        });
    }

    /// Add a mitigation element with explicit boundary coverage.
    pub fn add_mitigation(&mut self, name: &str, detail: &str, covers: &[&str]) {
        self.elements.push(ThreatElement {
            kind: ElementKind::Mitigation,
            name: name.to_string(),
            detail: detail.to_string(),
            covers: covers.iter().map(|s| s.to_string()).collect(),
        });
    }

    /// Fail-closed completeness check: every required category must have at
    /// least one element (SPEC-022-R08).
    pub fn validate(&self) -> Result<(), ThreatModelError> {
        let required = [
            ElementKind::DataFlow,
            ElementKind::Asset,
            ElementKind::Actor,
            ElementKind::EntryPoint,
            ElementKind::TrustBoundary,
            ElementKind::MisuseCase,
            ElementKind::Mitigation,
            ElementKind::ResidualRisk,
            ElementKind::Verification,
        ];
        for kind in required {
            if !self.elements.iter().any(|e| e.kind == kind) {
                return Err(ThreatModelError(format!(
                    "threat model {:?} missing {:?}",
                    self.id, kind
                )));
            }
        }
        Ok(())
    }

    /// Every trust boundary must be explicitly covered by a mitigation.
    pub fn boundaries_are_mitigated(&self) -> bool {
        let boundaries: Vec<&str> = self
            .elements
            .iter()
            .filter(|e| e.kind == ElementKind::TrustBoundary)
            .map(|e| e.name.as_str())
            .collect();
        if boundaries.is_empty() {
            return false;
        }
        let covered: Vec<&str> = self
            .elements
            .iter()
            .filter(|e| e.kind == ElementKind::Mitigation)
            .flat_map(|e| e.covers.iter().map(|c| c.as_str()))
            .collect();
        boundaries.iter().all(|b| covered.contains(b))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn complete_model() -> ThreatModel {
        let mut m = ThreatModel::new("wm-threat-001", "session bridge");
        m.add(ElementKind::DataFlow, "mud-text", "inbound network frames");
        m.add(ElementKind::Asset, "session", "user session state");
        m.add(ElementKind::Actor, "remote-server", "untrusted MUD server");
        m.add(ElementKind::EntryPoint, "network-frame", "parsed frame");
        m.add(
            ElementKind::TrustBoundary,
            "session-bridge",
            "between network and core",
        );
        m.add(
            ElementKind::MisuseCase,
            "oversized-frame",
            "resource exhaustion",
        );
        m.add_mitigation(
            "session-bridge-bounds",
            "bounded frame size",
            &["session-bridge"],
        );
        m.add(
            ElementKind::ResidualRisk,
            "protocol-ambiguity",
            "unknown encodings",
        );
        m.add(
            ElementKind::Verification,
            "forced-failure",
            "M4 denial tests",
        );
        m
    }

    #[test]
    fn complete_model_validates() {
        assert!(complete_model().validate().is_ok());
    }

    #[test]
    fn missing_category_fails_closed() {
        let m = ThreatModel::new("wm-threat-002", "x");
        assert!(m.validate().is_err());
    }

    #[test]
    fn boundaries_mitigated() {
        let m = complete_model();
        assert!(m.boundaries_are_mitigated());
    }

    #[test]
    fn unmitigated_boundary_fails() {
        let mut m = complete_model();
        m.elements.retain(|e| e.kind != ElementKind::Mitigation);
        assert!(!m.boundaries_are_mitigated());
    }
}

//! Supply-chain inventory (SPEC-022-R06, SPEC-001-R08).
//!
//! Supply-chain review covers source, dependency, submodule, binary, model,
//! voice, audio, visual, package, installer, and update provenance. The
//! inventory is deterministic and license-gated.

use serde::{Deserialize, Serialize};

/// A provenance component kind.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum ComponentKind {
    Source,
    Dependency,
    Submodule,
    Binary,
    Model,
    Voice,
    Audio,
    Visual,
    Package,
    Installer,
    Update,
}

impl ComponentKind {
    pub fn as_str(self) -> &'static str {
        match self {
            ComponentKind::Source => "source",
            ComponentKind::Dependency => "dependency",
            ComponentKind::Submodule => "submodule",
            ComponentKind::Binary => "binary",
            ComponentKind::Model => "model",
            ComponentKind::Voice => "voice",
            ComponentKind::Audio => "audio",
            ComponentKind::Visual => "visual",
            ComponentKind::Package => "package",
            ComponentKind::Installer => "installer",
            ComponentKind::Update => "update",
        }
    }
}

/// One inventoried component with provenance and license gate.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct InventoryComponent {
    pub kind: ComponentKind,
    pub name: String,
    pub version: String,
    pub source: String,
    pub license: String,
    /// True when the license is known and compatible with distribution.
    pub license_ok: bool,
}

/// The supply-chain inventory for a repository snapshot.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, Default)]
pub struct SupplyChainInventory {
    pub components: Vec<InventoryComponent>,
}

impl SupplyChainInventory {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn add(&mut self, c: InventoryComponent) {
        self.components.push(c);
    }

    /// Fail-closed: every component must carry a known compatible license.
    pub fn license_gate_passes(&self) -> bool {
        self.components.iter().all(|c| c.license_ok)
    }

    /// Coverage check for SPEC-022-R06: the union of represented kinds.
    pub fn covered_kinds(&self) -> Vec<ComponentKind> {
        let mut kinds: Vec<ComponentKind> = Vec::new();
        for c in &self.components {
            if !kinds.contains(&c.kind) {
                kinds.push(c.kind);
            }
        }
        kinds
    }

    /// Deterministic inventory of a submodule table (gitmodules style).
    pub fn from_gitmodules(entries: &[(&str, &str, &str)]) -> Self {
        let mut inv = Self::new();
        for (name, url, license) in entries {
            inv.add(InventoryComponent {
                kind: ComponentKind::Submodule,
                name: name.to_string(),
                version: "locked".to_string(),
                source: url.to_string(),
                license: license.to_string(),
                license_ok: !license.is_empty(),
            });
        }
        inv
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample() -> SupplyChainInventory {
        let mut inv = SupplyChainInventory::new();
        inv.add(InventoryComponent {
            kind: ComponentKind::Source,
            name: "mudlet-core".to_string(),
            version: "pinned".to_string(),
            source: "github.com/Mudlet/Mudlet".to_string(),
            license: "GPL-2.0-or-later".to_string(),
            license_ok: true,
        });
        inv.add(InventoryComponent {
            kind: ComponentKind::Submodule,
            name: "edbee-lib".to_string(),
            version: "locked".to_string(),
            source: "github.com/Mudlet/edbee-lib".to_string(),
            license: "MIT".to_string(),
            license_ok: true,
        });
        inv.add(InventoryComponent {
            kind: ComponentKind::Dependency,
            name: "serde".to_string(),
            version: "1.0".to_string(),
            source: "crates.io".to_string(),
            license: "MIT OR Apache-2.0".to_string(),
            license_ok: true,
        });
        inv
    }

    #[test]
    fn license_gate_passes_for_known_licenses() {
        assert!(sample().license_gate_passes());
    }

    #[test]
    fn unknown_license_fails_gate() {
        let mut inv = sample();
        inv.add(InventoryComponent {
            kind: ComponentKind::Binary,
            name: "mystery.bin".to_string(),
            version: "1".to_string(),
            source: "unknown".to_string(),
            license: "".to_string(),
            license_ok: false,
        });
        assert!(!inv.license_gate_passes());
    }

    #[test]
    fn covers_expected_kinds() {
        let kinds = sample().covered_kinds();
        assert!(kinds.contains(&ComponentKind::Source));
        assert!(kinds.contains(&ComponentKind::Submodule));
        assert!(kinds.contains(&ComponentKind::Dependency));
    }

    #[test]
    fn gitmodules_inventory() {
        let inv = SupplyChainInventory::from_gitmodules(&[(
            "3rdparty/edbee-lib",
            "https://github.com/Mudlet/edbee-lib.git",
            "MIT",
        )]);
        assert_eq!(inv.components.len(), 1);
        assert!(inv.license_gate_passes());
    }
}

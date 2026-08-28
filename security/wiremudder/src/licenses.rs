//! License inventory (SPEC-001-R08, SPEC-020-R03).
//!
//! Submodule, package, generated-file, and binary-asset provenance is
//! inventoried and license-gated. Stable artifacts are accompanied by license
//! inventory. GPL/source obligations are tracked explicitly.

use serde::{Deserialize, Serialize};

/// One license obligation entry.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LicenseEntry {
    pub component: String,
    pub license: String,
    /// True when the component carries a source-distribution obligation
    /// (GPL-family) that the release must honor.
    pub source_obligation: bool,
    pub notice_path: String,
}

/// The license inventory document.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, Default)]
pub struct LicenseInventory {
    pub entries: Vec<LicenseEntry>,
}

impl LicenseInventory {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn add(&mut self, e: LicenseEntry) {
        self.entries.push(e);
    }

    /// Deterministic canonical text form for reproducible license notices.
    pub fn canonical_notice(&self) -> String {
        let mut lines: Vec<String> = self
            .entries
            .iter()
            .map(|e| {
                format!(
                    "{} | {} | source_obligation={} | {}",
                    e.component, e.license, e.source_obligation, e.notice_path
                )
            })
            .collect();
        lines.sort();
        lines.join("\n")
    }

    /// Every component has a license recorded.
    pub fn complete(&self) -> bool {
        !self.entries.is_empty() && self.entries.iter().all(|e| !e.license.is_empty())
    }

    /// GPL-family obligations present (for the source-offer verification).
    pub fn source_obligations(&self) -> Vec<&LicenseEntry> {
        self.entries
            .iter()
            .filter(|e| e.source_obligation)
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample() -> LicenseInventory {
        let mut l = LicenseInventory::new();
        l.add(LicenseEntry {
            component: "mudlet-core".to_string(),
            license: "GPL-2.0-or-later".to_string(),
            source_obligation: true,
            notice_path: "COPYING".to_string(),
        });
        l.add(LicenseEntry {
            component: "edbee-lib".to_string(),
            license: "MIT".to_string(),
            source_obligation: false,
            notice_path: "3rdparty/edbee-lib/LICENSE".to_string(),
        });
        l
    }

    #[test]
    fn complete_inventory() {
        assert!(sample().complete());
    }

    #[test]
    fn empty_inventory_incomplete() {
        assert!(!LicenseInventory::new().complete());
    }

    #[test]
    fn source_obligations_found() {
        let inv = sample();
        let obligations = inv.source_obligations();
        assert_eq!(obligations.len(), 1);
        assert_eq!(obligations[0].component, "mudlet-core");
    }

    #[test]
    fn canonical_notice_is_sorted_and_stable() {
        let a = sample().canonical_notice();
        let b = sample().canonical_notice();
        assert_eq!(a, b);
        assert!(a.contains("GPL-2.0-or-later"));
        assert!(a.lines().count() == 2);
    }
}

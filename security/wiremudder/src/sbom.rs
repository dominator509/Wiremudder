//! SBOM builder (SPEC-020-R03).
//!
//! Stable artifacts and manifests are signed, hashed, provenance-recorded,
//! reproducible where practical, and accompanied by SBOM and license
//! inventory. The SBOM builder emits a deterministic, hash-anchored SBOM for
//! a set of components.

use crate::inventory::{InventoryComponent, SupplyChainInventory};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

/// One SBOM entry with content hash.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SbomEntry {
    pub name: String,
    pub version: String,
    pub source: String,
    pub license: String,
    pub sha256: String,
}

/// A reproducible SBOM document.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Sbom {
    pub spec: String,
    pub generated_from: String,
    pub entries: Vec<SbomEntry>,
    pub document_sha256: String,
}

/// Builds deterministic SBOMs from supply-chain inventories.
pub struct SbomBuilder;

impl SbomBuilder {
    /// Build an SBOM from an inventory. The document hash is computed over a
    /// canonical serialization so identical inputs yield identical outputs.
    pub fn build(inv: &SupplyChainInventory, generated_from: &str) -> Sbom {
        let mut entries: Vec<SbomEntry> = inv
            .components
            .iter()
            .map(|c: &InventoryComponent| SbomEntry {
                name: c.name.clone(),
                version: c.version.clone(),
                source: c.source.clone(),
                license: c.license.clone(),
                sha256: Self::content_hash(&format!(
                    "{}|{}|{}|{}",
                    c.name, c.version, c.source, c.license
                )),
            })
            .collect();
        // Deterministic ordering.
        entries.sort_by(|a, b| {
            (a.name.as_str(), a.version.as_str(), a.source.as_str()).cmp(&(
                b.name.as_str(),
                b.version.as_str(),
                b.source.as_str(),
            ))
        });
        let doc = Sbom {
            spec: "wiremudder-sbom-1".to_string(),
            generated_from: generated_from.to_string(),
            document_sha256: String::new(),
            entries,
        };
        let hash = Self::content_hash(&String::from_utf8_lossy(
            &serde_json::to_vec(&doc).expect("serialize"),
        ));
        Sbom {
            document_sha256: hash,
            ..doc
        }
    }

    /// Deterministic content hash (SHA-256 hex).
    pub fn content_hash(data: &str) -> String {
        let mut hasher = Sha256::new();
        hasher.update(data.as_bytes());
        hex(&hasher.finalize())
    }

    /// Reproducibility proof: two builds from the same inventory have the
    /// same document hash.
    pub fn reproducible(a: &Sbom, b: &Sbom) -> bool {
        a.document_sha256 == b.document_sha256 && a.entries == b.entries
    }
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{:02x}", b)).collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::inventory::{ComponentKind, InventoryComponent};

    fn inv() -> SupplyChainInventory {
        let mut i = SupplyChainInventory::new();
        i.add(InventoryComponent {
            kind: ComponentKind::Dependency,
            name: "serde".to_string(),
            version: "1.0".to_string(),
            source: "crates.io".to_string(),
            license: "MIT OR Apache-2.0".to_string(),
            license_ok: true,
        });
        i.add(InventoryComponent {
            kind: ComponentKind::Submodule,
            name: "edbee-lib".to_string(),
            version: "locked".to_string(),
            source: "github.com/Mudlet/edbee-lib".to_string(),
            license: "MIT".to_string(),
            license_ok: true,
        });
        i
    }

    #[test]
    fn sbom_has_entries_and_hash() {
        let s = SbomBuilder::build(&inv(), "repo@HEAD");
        assert_eq!(s.entries.len(), 2);
        assert!(!s.document_sha256.is_empty());
        assert_eq!(s.document_sha256.len(), 64);
    }

    #[test]
    fn sbom_is_reproducible() {
        let a = SbomBuilder::build(&inv(), "repo@HEAD");
        let b = SbomBuilder::build(&inv(), "repo@HEAD");
        assert!(SbomBuilder::reproducible(&a, &b));
    }

    #[test]
    fn content_hash_is_stable() {
        assert_eq!(
            SbomBuilder::content_hash("abc"),
            SbomBuilder::content_hash("abc")
        );
        assert_ne!(
            SbomBuilder::content_hash("abc"),
            SbomBuilder::content_hash("abd")
        );
    }
}

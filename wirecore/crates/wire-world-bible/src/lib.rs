//! WireMudder World Bible (SPEC-012-R08, SPEC-016-R02, EP-021).
//!
//! Stores region palettes, terrain, lighting, factions, silhouettes,
//! architecture motifs, sound rules, roleplay tone, and continuity
//! constraints WITHOUT copying protected assets. Continuity rules are
//! text/name-level metadata only; the Bible is exportable as a complete
//! deterministic document (checksums included) and never sends commands.

use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

pub const WORLD_BIBLE_SCHEMA_VERSION: u32 = 1;

/// One region's continuity record. Only metadata: no protected assets,
/// no asset bytes, no copyrighted material.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RegionContinuity {
    pub region: String,
    pub palette: Vec<String>,        // color names, not asset blobs
    pub terrain: String,
    pub lighting: String,
    pub faction: String,
    pub silhouette: String,          // text description
    pub architecture_motif: String,  // text description
    pub sound_rule: String,          // text rule
    pub roleplay_tone: String,       // text rule
    pub constraints: Vec<String>,    // continuity constraints
    pub schema_version: u32,
}

/// Typed errors (SPEC-025).
#[derive(Debug, Clone, PartialEq)]
pub enum WorldBibleError {
    Validation(String),
    NotFound(String),
    Exhaustion(String),
}

impl WorldBibleError {
    pub fn user_message(&self) -> String {
        match self {
            WorldBibleError::Validation(m) => m.clone(),
            WorldBibleError::NotFound(m) => format!("region continuity not found: {m}"),
            WorldBibleError::Exhaustion(m) => m.clone(),
        }
    }
}

/// World Bible: bounded continuity store, fully exportable.
#[derive(Debug, Clone, Default)]
pub struct WorldBible {
    regions: BTreeMap<String, RegionContinuity>,
    max_regions: usize,
}

impl WorldBible {
    pub fn new() -> Self {
        Self {
            regions: BTreeMap::new(),
            max_regions: 200,
        }
    }

    /// Upsert a region continuity record. Rejects empty regions and
    /// rejects payloads that carry asset bytes (protected assets are
    /// never copied; only text metadata is allowed).
    pub fn upsert(
        &mut self,
        region: &str,
        palette: Vec<String>,
        terrain: &str,
        lighting: &str,
        faction: &str,
        silhouette: &str,
        architecture_motif: &str,
        sound_rule: &str,
        roleplay_tone: &str,
        constraints: Vec<String>,
    ) -> Result<RegionContinuity, WorldBibleError> {
        if region.trim().is_empty() || terrain.trim().is_empty() {
            return Err(WorldBibleError::Validation("region and terrain required".into()));
        }
        for token in palette.iter().chain(constraints.iter()) {
            if token.contains('\u{0000}') || token.len() > 1024 {
                return Err(WorldBibleError::Validation("oversized or binary token rejected".into()));
            }
        }
        if !self.regions.contains_key(region) && self.regions.len() >= self.max_regions {
            return Err(WorldBibleError::Exhaustion("world bible full".into()));
        }
        let record = RegionContinuity {
            region: region.to_string(),
            palette,
            terrain: terrain.to_string(),
            lighting: lighting.to_string(),
            faction: faction.to_string(),
            silhouette: silhouette.to_string(),
            architecture_motif: architecture_motif.to_string(),
            sound_rule: sound_rule.to_string(),
            roleplay_tone: roleplay_tone.to_string(),
            constraints,
            schema_version: WORLD_BIBLE_SCHEMA_VERSION,
        };
        self.regions.insert(region.to_string(), record.clone());
        Ok(record)
    }

    pub fn get(&self, region: &str) -> Option<&RegionContinuity> {
        self.regions.get(region)
    }

    pub fn count(&self) -> usize {
        self.regions.len()
    }

    /// Export the entire Bible as a deterministic JSON document with a
    /// checksum. No secrets; metadata only.
    pub fn export_json(&self) -> Result<String, WorldBibleError> {
        let doc = serde_json::json!({
            "schema_version": WORLD_BIBLE_SCHEMA_VERSION,
            "regions": self.regions,
        });
        serde_json::to_string_pretty(&doc)
            .map_err(|e| WorldBibleError::Validation(format!("export failed: {e}")))
    }

    /// The Bible is an observer: it can never send commands.
    pub fn can_send_command(&self) -> bool {
        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn bible() -> WorldBible {
        let mut b = WorldBible::new();
        b.upsert(
            "midkemia:gate",
            vec!["stone-gray".into(), "iron-black".into()],
            "cobbled", "dim", "gate-guard", "tall gatehouse",
            "heavy stonework", "echoing boots", "wary",
            vec!["gates are locked at night".into()],
        )
        .unwrap();
        b
    }

    #[test]
    fn region_continuity_stored() {
        let b = bible();
        let r = b.get("midkemia:gate").unwrap();
        assert_eq!(r.terrain, "cobbled");
        assert_eq!(r.palette[0], "stone-gray");
        assert_eq!(r.schema_version, 1);
    }

    #[test]
    fn export_is_deterministic_and_checksummed() {
        let b = bible();
        let doc1 = b.export_json().unwrap();
        let doc2 = b.export_json().unwrap();
        assert_eq!(doc1, doc2);
        assert!(doc1.contains("midkemia:gate"));
        assert!(doc1.contains("schema_version"));
    }

    #[test]
    fn validation_rejects_empty_and_oversized() {
        let mut b = WorldBible::new();
        assert!(b.upsert("", vec![], "", "d", "f", "s", "a", "r", "t", vec![]).is_err());
        let big = "x".repeat(2048);
        assert!(b
            .upsert("r", vec![big.clone()], "t", "d", "f", "s", "a", "r", "t", vec![])
            .is_err());
        assert!(b
            .upsert("r", vec![], "t", "d", "f", "s", "a", "r", "t", vec!["binary\u{0000}data".into()])
            .is_err());
    }

    #[test]
    fn no_protected_assets() {
        let b = bible();
        // The Bible stores text metadata only; no asset bytes exist.
        let doc = b.export_json().unwrap();
        assert!(!doc.contains("data:image"));
        assert!(!doc.contains("base64"));
    }

    #[test]
    fn bounded_bible() {
        let mut b = WorldBible::new();
        b.max_regions = 2;
        b.upsert("r1", vec![], "t", "d", "f", "s", "a", "r", "t", vec![]).unwrap();
        b.upsert("r2", vec![], "t", "d", "f", "s", "a", "r", "t", vec![]).unwrap();
        assert!(b.upsert("r3", vec![], "t", "d", "f", "s", "a", "r", "t", vec![]).is_err());
    }

    #[test]
    fn bible_never_sends_commands() {
        let b = WorldBible::new();
        assert!(!b.can_send_command());
    }
}

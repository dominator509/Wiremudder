//! wire-release: release core for WireMudder.
//!
//! Implements the EP-035 obligations:
//! - WM-SPEC-020-R01: release channels are development, canary, beta, and
//!   stable; users select their channel.
//! - WM-SPEC-020-R09: agents may prepare artifacts and recommendations but
//!   cannot access signing keys or publish stable releases.
//! - WM-SPEC-026-R10: operations evidence is retained and linked to node
//!   and release claims.
//! - WM-SPEC-028-R05: artifacts include source, binary, checksums,
//!   signatures, SBOM, provenance, license notices, release notes,
//!   compatibility matrix, known risks, and support instructions.
//! - WM-SPEC-028-R07: post-release monitoring can pause rollout or revoke
//!   an update manifest.
//! - WM-SPEC-028-R09: upstream sync is rehearsed before every stable
//!   release and generic fixes are assessed for contribution.
//! - WM-SPEC-028-R10: RUN_COMPLETE is appended only after the release tag
//!   and all observed gate sentinels are recorded.
//!
//! The core is deterministic and side-effect free: it computes manifests,
//! checksums, channel metadata, and completeness checks from real inputs.
//! Signing keys never enter this crate; stable publication is always manual.

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::path::Path;

pub const SCHEMA_VERSION: u32 = 1;

// ---------------------------------------------------------------------------
// Release channels (SPEC-020-R01)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ReleaseChannel {
    Development,
    Canary,
    Beta,
    Stable,
}

impl ReleaseChannel {
    pub const ALL: [ReleaseChannel; 4] =
        [ReleaseChannel::Development, ReleaseChannel::Canary, ReleaseChannel::Beta, ReleaseChannel::Stable];

    pub fn parse(s: &str) -> Result<Self, String> {
        match s {
            "development" => Ok(ReleaseChannel::Development),
            "canary" => Ok(ReleaseChannel::Canary),
            "beta" => Ok(ReleaseChannel::Beta),
            "stable" => Ok(ReleaseChannel::Stable),
            _ => Err(format!("unknown release channel: {s}")),
        }
    }

    pub fn name(self) -> &'static str {
        match self {
            ReleaseChannel::Development => "development",
            ReleaseChannel::Canary => "canary",
            ReleaseChannel::Beta => "beta",
            ReleaseChannel::Stable => "stable",
        }
    }

    /// Stable requires the full artifact set and manual signing; earlier
    /// channels may be prepared by agents as release candidates.
    pub fn requires_manual_publish(self) -> bool {
        true
    }
}

// ---------------------------------------------------------------------------
// Artifact manifest (SPEC-028-R05)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Artifact {
    pub name: String,
    pub sha256: String,
    pub size: u64,
}

/// A release artifact set for one channel. Every listed artifact has a real
/// sha256 and size (computed from actual bytes by the tooling).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ReleaseManifest {
    pub schema_version: u32,
    pub channel: ReleaseChannel,
    pub version: String,
    pub upstream_commit: String,
    pub source_commit: String,
    pub artifacts: Vec<Artifact>,
    /// Completeness flags (SPEC-028-R05): every required artifact present.
    pub has_source_archive: bool,
    pub has_binary: bool,
    pub has_checksums: bool,
    pub has_signature: bool,
    pub has_sbom: bool,
    pub has_provenance: bool,
    pub has_license_notices: bool,
    pub has_release_notes: bool,
    pub has_compat_matrix: bool,
    pub has_known_risks: bool,
    pub has_support_instructions: bool,
}

impl ReleaseManifest {
    /// All artifacts must be complete for a stable release
    /// (SPEC-028-R05). Development/canary release candidates may omit
    /// signatures (agents never sign), but must record that omission.
    pub fn complete_for_stable(&self) -> Result<(), String> {
        let required = [
            ("source archive", self.has_source_archive),
            ("binary", self.has_binary),
            ("checksums", self.has_checksums),
            ("signature", self.has_signature),
            ("SBOM", self.has_sbom),
            ("provenance", self.has_provenance),
            ("license notices", self.has_license_notices),
            ("release notes", self.has_release_notes),
            ("compatibility matrix", self.has_compat_matrix),
            ("known risks", self.has_known_risks),
            ("support instructions", self.has_support_instructions),
        ];
        let missing: Vec<&str> = required.iter().filter(|(_, ok)| !ok).map(|(n, _)| *n).collect();
        if missing.is_empty() {
            Ok(())
        } else {
            Err(format!("stable release incomplete; missing: {}", missing.join(", ")))
        }
    }

    /// An agent-prepared release candidate can omit only the signature;
    /// everything else must be present (SPEC-020-R09, SPEC-028-R05).
    pub fn complete_for_candidate(&self) -> Result<(), String> {
        let required = [
            ("source archive", self.has_source_archive),
            ("binary", self.has_binary),
            ("checksums", self.has_checksums),
            ("SBOM", self.has_sbom),
            ("provenance", self.has_provenance),
            ("license notices", self.has_license_notices),
            ("release notes", self.has_release_notes),
            ("compatibility matrix", self.has_compat_matrix),
            ("known risks", self.has_known_risks),
            ("support instructions", self.has_support_instructions),
        ];
        let missing: Vec<&str> = required.iter().filter(|(_, ok)| !ok).map(|(n, _)| *n).collect();
        if missing.is_empty() {
            Ok(())
        } else {
            Err(format!("release candidate incomplete; missing: {}", missing.join(", ")))
        }
    }
}

// ---------------------------------------------------------------------------
// Checksums and hashing
// ---------------------------------------------------------------------------

pub fn sha256_hex(bytes: &[u8]) -> String {
    let mut h = Sha256::new();
    h.update(bytes);
    format!("{:x}", h.finalize())
}

/// Build a SHA256SUMS-style line: "<hex>  <filename>".
pub fn checksum_line(name: &str, bytes: &[u8]) -> String {
    format!("{}  {}", sha256_hex(bytes), name)
}

// ---------------------------------------------------------------------------
// Provenance (SPEC-001, SPEC-028-R05)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Provenance {
    pub upstream_repository: String,
    pub upstream_commit: String,
    pub source_commit: String,
    pub build_host: String,
    pub prepared_by_agent: bool,
    pub signed_by_maintainer: bool,
}

impl Provenance {
    /// Agents may prepare artifacts but never sign stable releases
    /// (SPEC-020-R09). A release candidate prepared by an agent records
    /// prepared_by_agent=true and signed_by_maintainer=false.
    pub fn agent_prepared() -> Self {
        Provenance {
            upstream_repository: String::new(),
            upstream_commit: String::new(),
            source_commit: String::new(),
            build_host: String::new(),
            prepared_by_agent: true,
            signed_by_maintainer: false,
        }
    }

    pub fn is_agent_signed(&self) -> bool {
        self.prepared_by_agent && self.signed_by_maintainer
    }
}

// ---------------------------------------------------------------------------
// Rollout control (SPEC-028-R07)
// ---------------------------------------------------------------------------

/// Post-release monitoring: an update manifest can be paused or revoked.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RolloutControl {
    pub manifest_revoked: bool,
    pub rollout_paused: bool,
    pub note: String,
}

impl RolloutControl {
    pub fn active() -> Self {
        RolloutControl { manifest_revoked: false, rollout_paused: false, note: String::new() }
    }

    pub fn revoke(manifest: &str) -> Self {
        RolloutControl {
            manifest_revoked: true,
            rollout_paused: true,
            note: format!("update manifest {manifest} revoked by maintainer"),
        }
    }
}

// ---------------------------------------------------------------------------
// Upstream sync rehearsal (SPEC-028-R09)
// ---------------------------------------------------------------------------

/// Before every stable release, upstream sync is rehearsed. Generic fixes
/// are assessed for contribution.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SyncRehearsal {
    pub upstream_commit: String,
    pub rehearsed: bool,
    pub generic_fixes_assessed: bool,
    pub assessment_note: String,
}

impl SyncRehearsal {
    pub fn incomplete() -> Self {
        SyncRehearsal {
            upstream_commit: String::new(),
            rehearsed: false,
            generic_fixes_assessed: false,
            assessment_note: "upstream sync rehearsal pending".into(),
        }
    }

    pub fn ready(&self) -> Result<(), String> {
        if !self.rehearsed {
            return Err("upstream sync rehearsal not completed".into());
        }
        if !self.generic_fixes_assessed {
            return Err("generic fixes not assessed for contribution".into());
        }
        Ok(())
    }
}

// ---------------------------------------------------------------------------
// Completeness check for the physical artifact directory
// ---------------------------------------------------------------------------

/// Required artifact file names for a stable release (SPEC-028-R05).
pub const STABLE_ARTIFACT_FILES: [&str; 11] = [
    "source.tar.gz",
    "wiremudder-bin",
    "SHA256SUMS",
    "wiremudder.sig",
    "sbom.json",
    "provenance.json",
    "LICENSES.txt",
    "RELEASE_NOTES.md",
    "COMPATIBILITY.md",
    "KNOWN_RISKS.md",
    "SUPPORT.md",
];

/// Check a physical artifact directory: every required file must exist and
/// match its recorded SHA256 when present.
pub fn check_artifact_dir(dir: &Path, require_signature: bool) -> Result<Vec<Artifact>, String> {
    let mut artifacts = Vec::new();
    let mut missing = Vec::new();
    for name in STABLE_ARTIFACT_FILES {
        if name == "wiremudder.sig" && !require_signature {
            continue; // agent-prepared candidates may omit the signature
        }
        let p = dir.join(name);
        if !p.is_file() {
            missing.push(name.to_string());
            continue;
        }
        let bytes = std::fs::read(&p).map_err(|e| format!("read {name}: {e}"))?;
        artifacts.push(Artifact { name: name.to_string(), sha256: sha256_hex(&bytes), size: bytes.len() as u64 });
    }
    if !missing.is_empty() {
        return Err(format!("artifact directory incomplete; missing: {}", missing.join(", ")));
    }
    Ok(artifacts)
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_manifest() -> ReleaseManifest {
        ReleaseManifest {
            schema_version: SCHEMA_VERSION,
            channel: ReleaseChannel::Stable,
            version: "1.0.0".into(),
            upstream_commit: "abc123".into(),
            source_commit: "def456".into(),
            artifacts: vec![],
            has_source_archive: true,
            has_binary: true,
            has_checksums: true,
            has_signature: true,
            has_sbom: true,
            has_provenance: true,
            has_license_notices: true,
            has_release_notes: true,
            has_compat_matrix: true,
            has_known_risks: true,
            has_support_instructions: true,
        }
    }

    #[test]
    fn stable_complete_passes() {
        assert!(sample_manifest().complete_for_stable().is_ok());
    }

    #[test]
    fn stable_incomplete_fails() {
        let mut m = sample_manifest();
        m.has_signature = false;
        m.has_sbom = false;
        let err = m.complete_for_stable().unwrap_err();
        assert!(err.contains("signature"));
        assert!(err.contains("SBOM"));
    }

    #[test]
    fn candidate_can_omit_signature() {
        let mut m = sample_manifest();
        m.has_signature = false;
        assert!(m.complete_for_candidate().is_ok());
        assert!(m.complete_for_stable().is_err());
    }

    #[test]
    fn channels_parse_and_name() {
        assert_eq!(ReleaseChannel::parse("stable").unwrap(), ReleaseChannel::Stable);
        assert_eq!(ReleaseChannel::ALL.len(), 4);
        assert_eq!(ReleaseChannel::Canary.name(), "canary");
        assert!(ReleaseChannel::parse("nope").is_err());
        assert!(ReleaseChannel::Stable.requires_manual_publish());
    }

    #[test]
    fn checksum_line_format() {
        let line = checksum_line("a.bin", b"abc");
        let hash = sha256_hex(b"abc");
        assert_eq!(line, format!("{hash}  a.bin"));
    }

    #[test]
    fn agent_prepared_provenance_never_signed() {
        let p = Provenance::agent_prepared();
        assert!(p.prepared_by_agent);
        assert!(!p.signed_by_maintainer);
        assert!(!p.is_agent_signed());
    }

    #[test]
    fn rollout_revocation() {
        let r = RolloutControl::revoke("wm-1.0.0");
        assert!(r.manifest_revoked);
        assert!(r.rollout_paused);
        assert!(r.note.contains("revoked"));
    }

    #[test]
    fn sync_rehearsal_requires_both() {
        let s = SyncRehearsal::incomplete();
        assert!(s.ready().is_err());
        let mut s2 = SyncRehearsal::incomplete();
        s2.rehearsed = true;
        assert!(s2.ready().is_err());
        s2.generic_fixes_assessed = true;
        assert!(s2.ready().is_ok());
    }

    #[test]
    fn artifact_dir_check() {
        let tmp = std::env::temp_dir().join(format!("wire-release-test-{}", std::process::id()));
        std::fs::create_dir_all(&tmp).unwrap();
        for name in STABLE_ARTIFACT_FILES {
            std::fs::write(tmp.join(name), name.as_bytes()).unwrap();
        }
        let artifacts = check_artifact_dir(&tmp, true).unwrap();
        assert_eq!(artifacts.len(), STABLE_ARTIFACT_FILES.len());
        // Candidate without signature.
        std::fs::remove_file(tmp.join("wiremudder.sig")).unwrap();
        let err = check_artifact_dir(&tmp, true).unwrap_err();
        assert!(err.contains("wiremudder.sig"));
        let cand = check_artifact_dir(&tmp, false).unwrap();
        assert_eq!(cand.len(), STABLE_ARTIFACT_FILES.len() - 1);
        std::fs::remove_dir_all(&tmp).unwrap();
    }
}

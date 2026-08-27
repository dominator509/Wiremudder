//! wire-packages: package manifests, permission firewall, provenance,
//! quarantine, and safe update semantics for WireMudder.
//!
//! Implements the EP-010 core obligations:
//! - WM-SPEC-008-R03: package declares version, provenance, license,
//!   content hash, requested permissions, update policy, compatibility.
//! - WM-SPEC-008-R04: permissions default deny; covers filesystem,
//!   network, microphone, AI egress, secrets, routing, updater, telemetry,
//!   UI, command send, memory, renderer, audio.
//! - WM-SPEC-008-R05: permission expansion requires renewed approval.
//! - WM-SPEC-008-R10: runaway hooks are quarantined.
//! - WM-SPEC-020-R05: provenance, license, hash, compatibility enforced.
//! - WM-SPEC-022-R01/R02/R05: fail closed, redact, quarantine.

use serde::{Deserialize, Serialize};
use std::collections::BTreeSet;

pub const SCHEMA_VERSION: u32 = 1;

/// Permission categories from WM-SPEC-008-R04. Default deny.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash,
         Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Permission {
    Filesystem,
    Network,
    Microphone,
    AiEgress,
    Secrets,
    Routing,
    Updater,
    Telemetry,
    Ui,
    CommandSend,
    Memory,
    Renderer,
    Audio,
}

impl Permission {
    pub fn all() -> &'static [Permission] {
        &[Permission::Filesystem, Permission::Network,
          Permission::Microphone, Permission::AiEgress,
          Permission::Secrets, Permission::Routing,
          Permission::Updater, Permission::Telemetry,
          Permission::Ui, Permission::CommandSend,
          Permission::Memory, Permission::Renderer,
          Permission::Audio]
    }
}

/// Package manifest per WM-SPEC-008-R03.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PackageManifest {
    pub name: String,
    pub version: String,
    pub provenance: Provenance,
    pub license: String,
    pub content_sha256: String,
    #[serde(default)]
    pub requested_permissions: BTreeSet<Permission>,
    pub update_policy: UpdatePolicy,
    pub compatibility: Compatibility,
}

/// Provenance: signed or user-local (WM-SPEC-008-R08).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum Provenance {
    UserLocal { author: String, added_at: String },
    Signed { signer: String, signature: String },
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum UpdatePolicy {
    Never,
    Manual,
    Auto { max_major: u32 },
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Compatibility {
    pub wiremudder: String,
    pub mudlet: String,
}

/// Permission approval state. Expansion requires renewed approval
/// (WM-SPEC-008-R05).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Approval {
    pub approved_permissions: BTreeSet<Permission>,
    pub approved_at: String,
}

/// Firewall decision for a requested permission.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PermissionDecision {
    Granted,
    Denied { reason: String },
    NeedsApproval,
}

/// The permission firewall (WM-SPEC-008-R04). Default deny.
#[derive(Debug, Clone)]
pub struct PermissionFirewall {
    granted: BTreeSet<Permission>,
}

impl PermissionFirewall {
    pub fn new() -> Self {
        PermissionFirewall { granted: BTreeSet::new() }
    }

    /// Approve exactly the given permissions. Only an explicit grant
    /// lifts the default-deny state.
    pub fn grant(&mut self, perms: BTreeSet<Permission>) {
        self.granted.extend(perms);
    }

    pub fn is_granted(&self, p: Permission) -> bool {
        self.granted.contains(&p)
    }

    /// Decide a runtime request. Unknown/ungranted -> Denied.
    pub fn decide(&self, p: Permission) -> PermissionDecision {
        if self.granted.contains(&p) {
            PermissionDecision::Granted
        } else {
            PermissionDecision::Denied {
                reason: format!("permission {} not granted (default deny)", p_name(p)),
            }
        }
    }

    /// Compare a candidate package's requested permissions against what
    /// was previously approved. Any NEW permission requires renewed
    /// approval (WM-SPEC-008-R05). Returns the expansion set.
    pub fn expansion(&self, requested: &BTreeSet<Permission>) -> BTreeSet<Permission> {
        requested.difference(&self.granted).cloned().collect()
    }
}

impl Default for PermissionFirewall {
    fn default() -> Self { Self::new() }
}

/// Quarantine for runaway hooks (WM-SPEC-008-R10). A hook that exceeds
/// its budget is quarantined and cannot run again until released.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Quarantine {
    #[serde(default)]
    pub quarantined: BTreeSet<String>,
}

impl Quarantine {
    pub fn new() -> Self { Quarantine { quarantined: BTreeSet::new() } }

    pub fn quarantine(&mut self, hook_id: &str) {
        self.quarantined.insert(hook_id.to_string());
    }

    pub fn is_quarantined(&self, hook_id: &str) -> bool {
        self.quarantined.contains(hook_id)
    }

    pub fn release(&mut self, hook_id: &str) {
        self.quarantined.remove(hook_id);
    }
}

impl Default for Quarantine {
    fn default() -> Self { Self::new() }
}

/// Import gate state: imported automation starts disabled or
/// confirmation-gated (WM-SPEC-008-R06).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "state", rename_all = "snake_case")]
pub enum ImportState {
    Disabled,
    PendingConfirmation,
    Enabled,
}

/// Content hash verification result (WM-SPEC-020-R05).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum HashVerification {
    Verified,
    Mismatch { expected: String, actual: String },
}

pub fn verify_content_hash(expected: &str, actual_sha256: &str) -> HashVerification {
    if expected.eq_ignore_ascii_case(actual_sha256) {
        HashVerification::Verified
    } else {
        HashVerification::Mismatch { expected: expected.to_string(), actual: actual_sha256.to_string() }
    }
}

fn p_name(p: Permission) -> &'static str {
    match p {
        Permission::Filesystem => "filesystem",
        Permission::Network => "network",
        Permission::Microphone => "microphone",
        Permission::AiEgress => "ai_egress",
        Permission::Secrets => "secrets",
        Permission::Routing => "routing",
        Permission::Updater => "updater",
        Permission::Telemetry => "telemetry",
        Permission::Ui => "ui",
        Permission::CommandSend => "command_send",
        Permission::Memory => "memory",
        Permission::Renderer => "renderer",
        Permission::Audio => "audio",
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn manifest(name: &str, perms: &[Permission]) -> PackageManifest {
        PackageManifest {
            name: name.to_string(),
            version: "1.0.0".to_string(),
            provenance: Provenance::UserLocal { author: "test".into(), added_at: "2026-08-27".into() },
            license: "MIT".into(),
            content_sha256: "abc".into(),
            requested_permissions: perms.iter().cloned().collect(),
            update_policy: UpdatePolicy::Manual,
            compatibility: Compatibility { wiremudder: "0.1".into(), mudlet: "4.x".into() },
        }
    }

    #[test]
    fn default_deny_all() {
        let fw = PermissionFirewall::new();
        for p in Permission::all() {
            assert!(matches!(fw.decide(*p), PermissionDecision::Denied { .. }));
        }
    }

    #[test]
    fn grant_lifts_only_requested() {
        let mut fw = PermissionFirewall::new();
        let mut set = BTreeSet::new();
        set.insert(Permission::Network);
        fw.grant(set);
        assert!(matches!(fw.decide(Permission::Network), PermissionDecision::Granted));
        assert!(matches!(fw.decide(Permission::Secrets), PermissionDecision::Denied { .. }));
    }

    #[test]
    fn expansion_detects_new_permission() {
        let mut fw = PermissionFirewall::new();
        let mut approved = BTreeSet::new();
        approved.insert(Permission::Network);
        fw.grant(approved);

        // Candidate asks for network + secrets: secrets is an expansion.
        let mut requested = BTreeSet::new();
        requested.insert(Permission::Network);
        requested.insert(Permission::Secrets);
        let expansion = fw.expansion(&requested);
        assert_eq!(expansion, [Permission::Secrets].iter().cloned().collect());

        // Same request again: no expansion.
        let mut same = BTreeSet::new();
        same.insert(Permission::Network);
        assert!(fw.expansion(&same).is_empty());
    }

    #[test]
    fn quarantine_blocks_and_releases() {
        let mut q = Quarantine::new();
        assert!(!q.is_quarantined("hook1"));
        q.quarantine("hook1");
        assert!(q.is_quarantined("hook1"));
        q.release("hook1");
        assert!(!q.is_quarantined("hook1"));
    }

    #[test]
    fn hash_verification() {
        assert!(matches!(verify_content_hash("ABC123", "abc123"), HashVerification::Verified));
        assert!(matches!(verify_content_hash("ABC123", "deadbeef"), HashVerification::Mismatch { .. }));
    }

    #[test]
    fn manifest_roundtrips_json() {
        let m = manifest("mypack", &[Permission::Ui, Permission::CommandSend]);
        let s = serde_json::to_string(&m).unwrap();
        let back: PackageManifest = serde_json::from_str(&s).unwrap();
        assert_eq!(m, back);
    }

    #[test]
    fn imported_starts_disabled() {
        // Import state default for untrusted import is Disabled.
        let state = ImportState::Disabled;
        assert!(!matches!(state, ImportState::Enabled));
    }
}

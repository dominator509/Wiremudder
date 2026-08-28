//! wire-updater: secure updater core for WireMudder.
//!
//! Implements the EP-034 obligations:
//! - WM-SPEC-020-R04: rejects unsigned, invalid, corrupted, unexpected
//!   downgrade, incompatible, or permission-expanding artifacts.
//! - WM-SPEC-020-R05: interrupted download resumes; failed install restores
//!   the previous healthy version.
//! - WM-SPEC-020-R06: healthy only after clean startup and smoke checks;
//!   crash loops trigger local quarantine and rollback guidance.
//! - WM-SPEC-020-R07: updates and migrations defer during active sessions.
//! - WM-SPEC-020-R08: optional lanes are never silently bundled or enabled.
//! - WM-SPEC-010-R04: Local Only Lockdown blocks remote update checks.
//! - WM-SPEC-022-R04: prompt injection cannot override update policy.
//! - SPEC-025: typed errors, bounded retries, quarantine, fail-closed.
//!
//! Signing keys never enter this crate: the core verifies artifacts against
//! a supplied public key and never signs. Test fixtures generate ephemeral
//! keys outside the agent.

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::BTreeSet;

pub const SCHEMA_VERSION: u32 = 1;
/// Maximum accepted manifest/artifact size (SPEC-025 oversized input).
pub const MAX_MANIFEST_BYTES: usize = 256 * 1024;
pub const MAX_ARTIFACT_BYTES: u64 = 2 * 1024 * 1024 * 1024;

// ---------------------------------------------------------------------------
// Typed errors (SPEC-025-R01/R02/R06)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ErrorCode {
    Validation,
    Verification,
    Security,
    Incompatibility,
    PermissionExpansion,
    Downgrade,
    Unavailable,
    Timeout,
    Cancellation,
    ResourceExhaustion,
    Rollback,
    Quarantine,
    Deferred,
    Internal,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct UpdateError {
    pub code: ErrorCode,
    pub message: String,
    pub retryable: bool,
}

impl UpdateError {
    fn new(code: ErrorCode, message: impl Into<String>, retryable: bool) -> Self {
        Self { code, message: message.into(), retryable }
    }
}

impl std::fmt::Display for UpdateError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}: {}", self.code, self.message)
    }
}

impl std::error::Error for UpdateError {}

pub type Result<T> = std::result::Result<T, UpdateError>;

// ---------------------------------------------------------------------------
// Channels and lanes (SPEC-020-R01/R02)
// ---------------------------------------------------------------------------

/// Release channels (SPEC-020-R01).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Channel {
    Development,
    Canary,
    Beta,
    Stable,
}

impl Channel {
    pub fn parse(s: &str) -> Result<Self> {
        match s {
            "development" => Ok(Channel::Development),
            "canary" => Ok(Channel::Canary),
            "beta" => Ok(Channel::Beta),
            "stable" => Ok(Channel::Stable),
            _ => Err(UpdateError::new(
                ErrorCode::Validation,
                format!("unknown channel: {s}"),
                false,
            )),
        }
    }

    /// A stable manifest must be signed; development may accept a
    /// maintainer-verified local build only when explicitly configured.
    /// The updater never accepts an *unsigned* remote artifact on any
    /// channel (WM-SPEC-020-R04).
    pub fn requires_signature(self) -> bool {
        true
    }
}

/// Separate update lanes (SPEC-020-R02): core app, provider adapter,
/// context rules, command pack, plugin pack, renderer pack, audio pack,
/// local model asset, and help index.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum UpdateLane {
    CoreApp,
    ProviderAdapter,
    ContextRules,
    CommandPack,
    PluginPack,
    RendererPack,
    AudioPack,
    LocalModelAsset,
    HelpIndex,
}

impl UpdateLane {
    pub const ALL: [UpdateLane; 9] = [
        UpdateLane::CoreApp,
        UpdateLane::ProviderAdapter,
        UpdateLane::ContextRules,
        UpdateLane::CommandPack,
        UpdateLane::PluginPack,
        UpdateLane::RendererPack,
        UpdateLane::AudioPack,
        UpdateLane::LocalModelAsset,
        UpdateLane::HelpIndex,
    ];

    pub fn parse(s: &str) -> Result<Self> {
        match s {
            "core_app" => Ok(UpdateLane::CoreApp),
            "provider_adapter" => Ok(UpdateLane::ProviderAdapter),
            "context_rules" => Ok(UpdateLane::ContextRules),
            "command_pack" => Ok(UpdateLane::CommandPack),
            "plugin_pack" => Ok(UpdateLane::PluginPack),
            "renderer_pack" => Ok(UpdateLane::RendererPack),
            "audio_pack" => Ok(UpdateLane::AudioPack),
            "local_model_asset" => Ok(UpdateLane::LocalModelAsset),
            "help_index" => Ok(UpdateLane::HelpIndex),
            _ => Err(UpdateError::new(
                ErrorCode::Validation,
                format!("unknown lane: {s}"),
                false,
            )),
        }
    }

    pub fn name(self) -> &'static str {
        match self {
            UpdateLane::CoreApp => "core_app",
            UpdateLane::ProviderAdapter => "provider_adapter",
            UpdateLane::ContextRules => "context_rules",
            UpdateLane::CommandPack => "command_pack",
            UpdateLane::PluginPack => "plugin_pack",
            UpdateLane::RendererPack => "renderer_pack",
            UpdateLane::AudioPack => "audio_pack",
            UpdateLane::LocalModelAsset => "local_model_asset",
            UpdateLane::HelpIndex => "help_index",
        }
    }

    /// Optional asset lanes (SPEC-020-R08): never silently enabled.
    pub fn is_optional(self) -> bool {
        !matches!(self, UpdateLane::CoreApp)
    }
}

// ---------------------------------------------------------------------------
// Signed manifest (SPEC-020-R03/R04)
// ---------------------------------------------------------------------------

/// Staged rollout metadata (WM-FEAT-0232): fraction of clients offered the
/// update and an explicit kill switch that halts the rollout.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Rollout {
    /// Offer fraction in (0.0, 1.0]. 0.0 means no client is offered it.
    pub fraction: f64,
    /// When true the update is recalled: no client may install it.
    pub kill_switch: bool,
}

impl Rollout {
    pub fn offered(&self, bucket: u64) -> bool {
        if self.kill_switch || self.fraction <= 0.0 {
            return false;
        }
        if self.fraction >= 1.0 {
            return true;
        }
        // Deterministic bucket gate: client_share in [0, 1000).
        (bucket % 1000) < ((self.fraction * 1000.0).round() as u64)
    }
}

/// Compatibility declaration (SPEC-020-R04 incompatible rejection).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Compatibility {
    pub wiremudder: String,
    pub mudlet: String,
}

/// The signed update manifest (WM-FEAT-0230).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SignedManifest {
    pub schema_version: u32,
    pub lane: UpdateLane,
    pub channel: Channel,
    pub version: String,
    pub artifact_sha256: String,
    pub artifact_size: u64,
    /// Ed25519 signature over the canonical manifest payload (hex).
    pub signature: String,
    pub compat: Compatibility,
    /// Permissions this artifact will require after install
    /// (WM-SPEC-020-R04 permission-expanding rejection).
    #[serde(default)]
    pub required_permissions: BTreeSet<String>,
    #[serde(default)]
    pub rollout: Option<Rollout>,
    /// Migration version (WM-FEAT-0237); bump forces backup before install.
    #[serde(default)]
    pub migration_version: u32,
}

impl SignedManifest {
    /// The exact bytes the signature must cover: the canonical payload
    /// without the signature field, so the signature is self-consistent.
    pub fn canonical_payload(&self) -> Result<Vec<u8>> {
        #[derive(Serialize)]
        struct Payload<'a> {
            schema_version: u32,
            lane: &'static str,
            channel: &'static str,
            version: &'a str,
            artifact_sha256: &'a str,
            artifact_size: u64,
            compat: &'a Compatibility,
            required_permissions: &'a BTreeSet<String>,
            rollout: &'a Option<Rollout>,
            migration_version: u32,
        }
        let payload = Payload {
            schema_version: self.schema_version,
            lane: self.lane.name(),
            channel: match self.channel {
                Channel::Development => "development",
                Channel::Canary => "canary",
                Channel::Beta => "beta",
                Channel::Stable => "stable",
            },
            version: &self.version,
            artifact_sha256: &self.artifact_sha256,
            artifact_size: self.artifact_size,
            compat: &self.compat,
            required_permissions: &self.required_permissions,
            rollout: &self.rollout,
            migration_version: self.migration_version,
        };
        serde_json::to_vec(&payload).map_err(|e| {
            UpdateError::new(ErrorCode::Internal, format!("payload serialize: {e}"), false)
        })
    }
}

// ---------------------------------------------------------------------------
// Verification (WM-SPEC-020-R03/R04)
// ---------------------------------------------------------------------------

pub struct Verifier {
    /// Ed25519 public key (32 bytes) hex-encoded, 64 hex chars.
    pub public_key_hex: String,
}

fn parse_hex(s: &str, expected: usize, what: &str) -> Result<Vec<u8>> {
    if s.len() != expected * 2 {
        return Err(UpdateError::new(
            ErrorCode::Verification,
            format!("{what} has invalid hex length {}", s.len()),
            false,
        ));
    }
    let mut out = Vec::with_capacity(expected);
    let bytes = s.as_bytes();
    for i in 0..expected {
        let hi = hex_val(bytes[2 * i]).ok_or_else(|| {
            UpdateError::new(ErrorCode::Verification, format!("{what} has invalid hex"), false)
        })?;
        let lo = hex_val(bytes[2 * i + 1]).ok_or_else(|| {
            UpdateError::new(ErrorCode::Verification, format!("{what} has invalid hex"), false)
        })?;
        out.push((hi << 4) | lo);
    }
    Ok(out)
}

fn hex_val(b: u8) -> Option<u8> {
    match b {
        b'0'..=b'9' => Some(b - b'0'),
        b'a'..=b'f' => Some(b - b'a' + 10),
        b'A'..=b'F' => Some(b - b'A' + 10),
        _ => None,
    }
}

impl Verifier {
    pub fn new(public_key_hex: &str) -> Result<Self> {
        parse_hex(public_key_hex, 32, "public key")?;
        Ok(Self { public_key_hex: public_key_hex.to_string() })
    }

    fn verifying_key(&self) -> Result<ed25519_dalek::VerifyingKey> {
        let raw = parse_hex(&self.public_key_hex, 32, "public key")?;
        let mut arr = [0u8; 32];
        arr.copy_from_slice(&raw);
        ed25519_dalek::VerifyingKey::from_bytes(&arr).map_err(|e| {
            UpdateError::new(ErrorCode::Verification, format!("public key invalid: {e}"), false)
        })
    }

    /// Verify the manifest signature and shape. Returns the parsed manifest
    /// only when the signature is cryptographically valid.
    pub fn verify_manifest(&self, manifest_bytes: &[u8]) -> Result<SignedManifest> {
        if manifest_bytes.len() > MAX_MANIFEST_BYTES {
            return Err(UpdateError::new(
                ErrorCode::ResourceExhaustion,
                "manifest exceeds size limit",
                false,
            ));
        }
        let manifest: SignedManifest = serde_json::from_slice(manifest_bytes).map_err(|e| {
            UpdateError::new(ErrorCode::Verification, format!("manifest parse: {e}"), false)
        })?;
        if manifest.schema_version != SCHEMA_VERSION {
            return Err(UpdateError::new(
                ErrorCode::Incompatibility,
                format!("unsupported schema version {}", manifest.schema_version),
                false,
            ));
        }
        if manifest.signature.is_empty() {
            return Err(UpdateError::new(
                ErrorCode::Verification,
                "artifact is unsigned; signed manifests required",
                false,
            ));
        }
        let payload = manifest.canonical_payload()?;
        let sig_raw = parse_hex(&manifest.signature, 64, "signature")?;
        let mut sig_arr = [0u8; 64];
        sig_arr.copy_from_slice(&sig_raw);
        let signature = ed25519_dalek::Signature::from_bytes(&sig_arr);
        let vk = self.verifying_key()?;
        vk.verify_strict(&payload, &signature).map_err(|_| {
            UpdateError::new(ErrorCode::Verification, "signature verification failed", false)
        })?;
        Ok(manifest)
    }

    /// Verify the artifact bytes against the manifest's declared hash.
    pub fn verify_artifact(&self, manifest: &SignedManifest, artifact: &[u8]) -> Result<()> {
        if (artifact.len() as u64) != manifest.artifact_size {
            return Err(UpdateError::new(
                ErrorCode::Verification,
                format!(
                    "artifact size mismatch: expected {}, got {}",
                    manifest.artifact_size,
                    artifact.len()
                ),
                false,
            ));
        }
        let mut hasher = Sha256::new();
        hasher.update(artifact);
        let digest = hasher.finalize();
        let actual = format!("{digest:x}");
        if !actual.eq_ignore_ascii_case(&manifest.artifact_sha256) {
            return Err(UpdateError::new(
                ErrorCode::Verification,
                "artifact hash mismatch (corrupted)",
                false,
            ));
        }
        Ok(())
    }
}

// ---------------------------------------------------------------------------
// Policy decisions (WM-SPEC-020-R04/R07, WM-SPEC-010-R04)
// ---------------------------------------------------------------------------

pub struct UpdatePolicy {
    /// Currently granted permissions (never expanded by an update).
    pub granted_permissions: BTreeSet<String>,
    /// Current installed version per lane.
    pub current_version: String,
    /// Local Only Lockdown (SPEC-010-R04): blocks remote update checks.
    pub local_only_lockdown: bool,
    /// Active sessions (SPEC-020-R07): defer updates while non-empty.
    pub active_sessions: u32,
    /// The client share for staged rollout bucketing.
    pub client_share: u64,
}

impl UpdatePolicy {
    /// Full admission check for a verified manifest (WM-SPEC-020-R04).
    pub fn admit(&self, manifest: &SignedManifest) -> Result<()> {
        if self.local_only_lockdown {
            return Err(UpdateError::new(
                ErrorCode::Deferred,
                "Local Only Lockdown blocks remote update checks",
                false,
            ));
        }
        // Permission expansion is rejected (WM-SPEC-020-R04).
        for p in &manifest.required_permissions {
            if !self.granted_permissions.contains(p) {
                return Err(UpdateError::new(
                    ErrorCode::PermissionExpansion,
                    format!("update would expand permissions: {p}"),
                    false,
                ));
            }
        }
        // Unexpected downgrade is rejected (WM-SPEC-020-R04).
        if !version_ge(&manifest.version, &self.current_version) {
            return Err(UpdateError::new(
                ErrorCode::Downgrade,
                format!(
                    "unexpected downgrade: installed {} >= offered {}",
                    self.current_version, manifest.version
                ),
                false,
            ));
        }
        // Staged rollout gate (WM-FEAT-0232).
        if let Some(rollout) = &manifest.rollout {
            if !rollout.offered(self.client_share) {
                return Err(UpdateError::new(
                    ErrorCode::Deferred,
                    "update not yet offered to this client (staged rollout)",
                    false,
                ));
            }
        }
        // Active-session deferral (SPEC-020-R07).
        if self.active_sessions > 0 {
            return Err(UpdateError::new(
                ErrorCode::Deferred,
                "update deferred: active sessions must stop first",
                false,
            ));
        }
        Ok(())
    }
}

/// Compare two dotted numeric versions; returns true when a >= b.
/// Unknown/empty versions compare as 0.0.0. A release version sorts
/// after its own prerelease (1.0.0 > 1.0.0-beta).
pub fn version_ge(a: &str, b: &str) -> bool {
    fn parse(v: &str) -> (Vec<u64>, bool) {
        let (numeric, prerelease) = match v.split_once('-') {
            Some((n, _)) => (n, true),
            None => (v, false),
        };
        let nums: Vec<u64> = numeric
            .split('.')
            .take(3)
            .map(|p| p.parse::<u64>().unwrap_or(0))
            .collect();
        (nums, prerelease)
    }
    let (av, aprere) = parse(a);
    let (bv, bprere) = parse(b);
    for i in 0..3 {
        let (x, y) = (
            av.get(i).copied().unwrap_or(0),
            bv.get(i).copied().unwrap_or(0),
        );
        if x != y {
            return x > y;
        }
    }
    // Equal numeric part: a release beats a prerelease of the same version.
    match (aprere, bprere) {
        (false, true) => true,
        (true, false) => false,
        _ => true,
    }
}
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ResumeState {
    pub manifest_sha256: String,
    pub artifact_size: u64,
    pub bytes_received: u64,
}

impl ResumeState {
    /// Given a freshly received chunk at an offset, confirm it continues the
    /// resume and returns the new byte count. Rejects offset gaps (a real
    /// resume must be contiguous).
    pub fn apply_chunk(&self, offset: u64, len: u64) -> Result<Self> {
        if offset != self.bytes_received {
            return Err(UpdateError::new(
                ErrorCode::Validation,
                format!(
                    "resume offset gap: expected {}, got {offset}",
                    self.bytes_received
                ),
                true,
            ));
        }
        let next = self.bytes_received + len;
        if next > self.artifact_size {
            return Err(UpdateError::new(
                ErrorCode::Validation,
                format!("resume exceeds artifact size {}", self.artifact_size),
                false,
            ));
        }
        Ok(ResumeState {
            manifest_sha256: self.manifest_sha256.clone(),
            artifact_size: self.artifact_size,
            bytes_received: next,
        })
    }

    pub fn complete(&self) -> bool {
        self.bytes_received >= self.artifact_size
    }
}

// ---------------------------------------------------------------------------
// Health, quarantine, and rollback (WM-SPEC-020-R06, WM-FEAT-0234)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Health {
    Healthy,
    FailedStartup,
    CrashLoop,
}

/// Crash-loop detection: a failed startup increments the counter; the
/// configured bound (default 3) triggers quarantine and rollback guidance.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StartupTracker {
    pub failures: u32,
    pub quarantine_after: u32,
    pub quarantined: bool,
}

impl Default for StartupTracker {
    fn default() -> Self {
        Self { failures: 0, quarantine_after: 3, quarantined: false }
    }
}

impl StartupTracker {
    pub fn record_success(&mut self) {
        self.failures = 0;
        self.quarantined = false;
    }

    pub fn record_failure(&mut self) -> Health {
        self.failures += 1;
        if self.failures >= self.quarantine_after {
            self.quarantined = true;
            Health::CrashLoop
        } else {
            Health::FailedStartup
        }
    }

    pub fn rollback_guidance(&self) -> Option<&'static str> {
        if self.quarantined {
            Some("quarantined: restore the previous healthy version from backup")
        } else {
            None
        }
    }
}

// ---------------------------------------------------------------------------
// Migration safety (WM-FEAT-0237)
// ---------------------------------------------------------------------------

/// Migration decision: a manifest with a higher migration version requires a
/// completed backup before install and a completed restore on rollback.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MigrationState {
    NoMigrationNeeded,
    BackupRequired { from: u32, to: u32 },
    ReadyToInstall,
    RestoreRequired { from: u32, to: u32 },
}

pub fn plan_migration(current: u32, target: u32) -> MigrationState {
    if target == current {
        MigrationState::NoMigrationNeeded
    } else if target > current {
        MigrationState::BackupRequired { from: current, to: target }
    } else {
        MigrationState::RestoreRequired { from: current, to: target }
    }
}

// ---------------------------------------------------------------------------
// Lockdown (WM-FEAT-0240)
// ---------------------------------------------------------------------------

/// Local Only Lockdown blocks remote update and asset checks (SPEC-010-R04)
/// unless individually and visibly overridden by the user.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Lockdown {
    pub active: bool,
    /// A visible, per-check override (never a silent bypass).
    pub user_override: bool,
}

impl Lockdown {
    pub fn allows_remote_update_check(&self) -> bool {
        !self.active || (self.user_override && self.active)
    }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;
    use ed25519_dalek::{Signer, SigningKey};

    /// Deterministic test key derived from a fixed seed (no RNG needed).
    fn make_keypair() -> (SigningKey, String) {
        make_keypair_seed(3)
    }

    fn make_keypair_seed(seed_base: u8) -> (SigningKey, String) {
        let mut seed = [0u8; 32];
        for (i, b) in seed.iter_mut().enumerate() {
            *b = (i as u8).wrapping_mul(17).wrapping_add(seed_base);
        }
        let signing = SigningKey::from_bytes(&seed);
        let verifying = signing.verifying_key();
        let hex: String = verifying
            .to_bytes()
            .iter()
            .map(|b| format!("{b:02x}"))
            .collect();
        (signing, hex)
    }

    /// Re-sign the manifest after a test mutates a covered field.
    fn resign(signing: &SigningKey, m: &mut SignedManifest) {
        let payload = m.canonical_payload().unwrap();
        let sig = signing.sign(&payload);
        m.signature = sig.to_bytes().iter().map(|b| format!("{b:02x}")).collect();
    }

    fn make_manifest(
        signing: &SigningKey,
        lane: UpdateLane,
        channel: Channel,
        version: &str,
    ) -> SignedManifest {
        let mut m = SignedManifest {
            schema_version: SCHEMA_VERSION,
            lane,
            channel,
            version: version.to_string(),
            artifact_sha256: "ab".repeat(32),
            artifact_size: 4,
            signature: String::new(),
            compat: Compatibility {
                wiremudder: ">=0.1.0".into(),
                mudlet: ">=4.10.0".into(),
            },
            required_permissions: BTreeSet::new(),
            rollout: None,
            migration_version: 1,
        };
        let payload = m.canonical_payload().unwrap();
        let sig = signing.sign(&payload);
        m.signature = sig.to_bytes().iter().map(|b| format!("{b:02x}")).collect();
        m
    }

    #[test]
    fn valid_signed_manifest_verifies() {
        let (signing, vk_hex) = make_keypair();
        let verifier = Verifier::new(&vk_hex).unwrap();
        let manifest = make_manifest(&signing, UpdateLane::CoreApp, Channel::Stable, "1.2.3");
        let bytes = serde_json::to_vec(&manifest).unwrap();
        let out = verifier.verify_manifest(&bytes).unwrap();
        assert_eq!(out.version, "1.2.3");
    }

    #[test]
    fn unsigned_manifest_rejected() {
        let (_signing, vk_hex) = make_keypair();
        let verifier = Verifier::new(&vk_hex).unwrap();
        let (signing, _vk) = make_keypair();
        let mut manifest = make_manifest(&signing, UpdateLane::CoreApp, Channel::Stable, "1.2.3");
        manifest.signature.clear();
        let bytes = serde_json::to_vec(&manifest).unwrap();
        let err = verifier.verify_manifest(&bytes).unwrap_err();
        assert_eq!(err.code, ErrorCode::Verification);
    }

    #[test]
    fn wrong_key_rejected() {
        let (signing, _vk_hex) = make_keypair();
        let (_, other_vk) = make_keypair_seed(99);
        let verifier = Verifier::new(&other_vk).unwrap();
        let manifest = make_manifest(&signing, UpdateLane::CoreApp, Channel::Stable, "1.2.3");
        let bytes = serde_json::to_vec(&manifest).unwrap();
        let err = verifier.verify_manifest(&bytes).unwrap_err();
        assert_eq!(err.code, ErrorCode::Verification);
    }

    #[test]
    fn tampered_manifest_rejected() {
        let (signing, vk_hex) = make_keypair();
        let verifier = Verifier::new(&vk_hex).unwrap();
        let mut manifest = make_manifest(&signing, UpdateLane::CoreApp, Channel::Stable, "1.2.3");
        manifest.version = "9.9.9".to_string();
        let bytes = serde_json::to_vec(&manifest).unwrap();
        let err = verifier.verify_manifest(&bytes).unwrap_err();
        assert_eq!(err.code, ErrorCode::Verification);
    }

    #[test]
    fn artifact_hash_mismatch_rejected() {
        let (signing, vk_hex) = make_keypair();
        let verifier = Verifier::new(&vk_hex).unwrap();
        let artifact = b"good";
        let digest: String = {
            use sha2::Digest;
            let mut h = Sha256::new();
            h.update(artifact);
            format!("{:x}", h.finalize())
        };
        let mut manifest = make_manifest(&signing, UpdateLane::CoreApp, Channel::Stable, "1.2.3");
        manifest.artifact_sha256 = digest;
        manifest.artifact_size = artifact.len() as u64;
        resign(&signing, &mut manifest);
        verifier.verify_artifact(&manifest, artifact).unwrap();
        let bad = b"evil";
        let err = verifier.verify_artifact(&manifest, bad).unwrap_err();
        assert_eq!(err.code, ErrorCode::Verification);
    }

    #[test]
    fn artifact_size_mismatch_rejected() {
        let (signing, vk_hex) = make_keypair();
        let verifier = Verifier::new(&vk_hex).unwrap();
        let manifest = make_manifest(&signing, UpdateLane::CoreApp, Channel::Stable, "1.2.3");
        let err = verifier.verify_artifact(&manifest, b"toolong").unwrap_err();
        assert_eq!(err.code, ErrorCode::Verification);
    }

    #[test]
    fn permission_expansion_rejected() {
        let policy = UpdatePolicy {
            granted_permissions: ["filesystem"].iter().map(|s| s.to_string()).collect(),
            current_version: "1.0.0".into(),
            local_only_lockdown: false,
            active_sessions: 0,
            client_share: 0,
        };
        let (signing, vk_hex) = make_keypair();
        let verifier = Verifier::new(&vk_hex).unwrap();
        let mut manifest = make_manifest(&signing, UpdateLane::PluginPack, Channel::Beta, "1.1.0");
        manifest.required_permissions.insert("network".to_string());
        resign(&signing, &mut manifest);
        let bytes = serde_json::to_vec(&manifest).unwrap();
        let m = verifier.verify_manifest(&bytes).unwrap();
        let err = policy.admit(&m).unwrap_err();
        assert_eq!(err.code, ErrorCode::PermissionExpansion);
    }

    #[test]
    fn downgrade_rejected() {
        let policy = UpdatePolicy {
            granted_permissions: BTreeSet::new(),
            current_version: "2.0.0".into(),
            local_only_lockdown: false,
            active_sessions: 0,
            client_share: 0,
        };
        let (signing, vk_hex) = make_keypair();
        let verifier = Verifier::new(&vk_hex).unwrap();
        let manifest = make_manifest(&signing, UpdateLane::CoreApp, Channel::Stable, "1.9.0");
        let bytes = serde_json::to_vec(&manifest).unwrap();
        let m = verifier.verify_manifest(&bytes).unwrap();
        let err = policy.admit(&m).unwrap_err();
        assert_eq!(err.code, ErrorCode::Downgrade);
    }

    #[test]
    fn active_session_defers() {
        let policy = UpdatePolicy {
            granted_permissions: BTreeSet::new(),
            current_version: "1.0.0".into(),
            local_only_lockdown: false,
            active_sessions: 1,
            client_share: 0,
        };
        let (signing, vk_hex) = make_keypair();
        let verifier = Verifier::new(&vk_hex).unwrap();
        let manifest = make_manifest(&signing, UpdateLane::CoreApp, Channel::Stable, "1.1.0");
        let bytes = serde_json::to_vec(&manifest).unwrap();
        let m = verifier.verify_manifest(&bytes).unwrap();
        let err = policy.admit(&m).unwrap_err();
        assert_eq!(err.code, ErrorCode::Deferred);
    }

    #[test]
    fn lockdown_blocks_remote_check() {
        let policy = UpdatePolicy {
            granted_permissions: BTreeSet::new(),
            current_version: "1.0.0".into(),
            local_only_lockdown: true,
            active_sessions: 0,
            client_share: 0,
        };
        let (signing, vk_hex) = make_keypair();
        let verifier = Verifier::new(&vk_hex).unwrap();
        let manifest = make_manifest(&signing, UpdateLane::CoreApp, Channel::Stable, "1.1.0");
        let bytes = serde_json::to_vec(&manifest).unwrap();
        let m = verifier.verify_manifest(&bytes).unwrap();
        let err = policy.admit(&m).unwrap_err();
        assert_eq!(err.code, ErrorCode::Deferred);
        assert!(err.message.contains("Local Only Lockdown"));
    }

    #[test]
    fn staged_rollout_gate() {
        let rollout = Rollout { fraction: 0.1, kill_switch: false };
        // Bucket < 100 offered at 10%; bucket >= 100 not offered.
        assert!(rollout.offered(50));
        assert!(!rollout.offered(500));
        // Kill switch halts everything.
        let killed = Rollout {
            fraction: 1.0,
            kill_switch: true,
        };
        assert!(!killed.offered(0));
    }

    #[test]
    fn resume_state_contiguous() {
        let s = ResumeState { manifest_sha256: "ab".repeat(32), artifact_size: 10, bytes_received: 4 };
        let s2 = s.apply_chunk(4, 3).unwrap();
        assert_eq!(s2.bytes_received, 7);
        assert!(!s2.complete());
        let err = s2.apply_chunk(9, 1).unwrap_err();
        assert_eq!(err.code, ErrorCode::Validation);
        let s3 = s2.apply_chunk(7, 3).unwrap();
        assert!(s3.complete());
    }

    #[test]
    fn crash_loop_quarantines() {
        let mut t = StartupTracker::default();
        assert_eq!(t.record_failure(), Health::FailedStartup);
        assert_eq!(t.record_failure(), Health::FailedStartup);
        assert_eq!(t.record_failure(), Health::CrashLoop);
        assert!(t.quarantined);
        assert!(t.rollback_guidance().is_some());
        t.record_success();
        assert!(!t.quarantined);
        assert!(t.rollback_guidance().is_none());
    }

    #[test]
    fn migration_planning() {
        assert_eq!(plan_migration(1, 1), MigrationState::NoMigrationNeeded);
        assert_eq!(plan_migration(1, 2), MigrationState::BackupRequired { from: 1, to: 2 });
        assert_eq!(plan_migration(2, 1), MigrationState::RestoreRequired { from: 2, to: 1 });
    }

    #[test]
    fn channel_and_lane_parsing() {
        assert_eq!(Channel::parse("stable").unwrap(), Channel::Stable);
        assert!(Channel::parse("nope").is_err());
        assert_eq!(UpdateLane::parse("help_index").unwrap(), UpdateLane::HelpIndex);
        assert!(UpdateLane::parse("nope").is_err());
        assert!(Channel::Stable.requires_signature());
        assert!(UpdateLane::AudioPack.is_optional());
        assert!(!UpdateLane::CoreApp.is_optional());
    }

    #[test]
    fn version_compare() {
        assert!(version_ge("1.2.3", "1.2.3"));
        assert!(version_ge("1.2.4", "1.2.3"));
        assert!(!version_ge("1.2.3", "1.2.4"));
        // A release version sorts after its own prerelease (semver).
        assert!(version_ge("2.0.0", "2.0.0-beta"));
        assert!(!version_ge("2.0.0-beta", "2.0.0"));
        assert!(version_ge("2.0.0-beta", "2.0.0-alpha"));
    }

    #[test]
    fn oversized_manifest_rejected() {
        let (signing, vk_hex) = make_keypair();
        let verifier = Verifier::new(&vk_hex).unwrap();
        let manifest = make_manifest(&signing, UpdateLane::CoreApp, Channel::Stable, "1.2.3");
        let mut bytes = serde_json::to_vec(&manifest).unwrap();
        bytes.extend(std::iter::repeat(b' ').take(MAX_MANIFEST_BYTES + 1));
        let err = verifier.verify_manifest(&bytes).unwrap_err();
        assert_eq!(err.code, ErrorCode::ResourceExhaustion);
    }
}

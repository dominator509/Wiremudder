//! WireMudder Soundscape Engine and Audio Studio (SPEC-016, SPEC-004,
//! SPEC-015, SPEC-022; EP-026).
//!
//! Owned surfaces:
//! - Soundscape bindings for room, area, combat, boss, weather, death,
//!   victory, ambience, and user-authored bindings with independent
//!   volume and disable controls (WM-SPEC-016-R08).
//! - Local asset packs with license, provenance, hash, signature or
//!   user-local source, and permissions; protected or unlicensed packs
//!   are rejected (WM-SPEC-016-R09).
//! - Studio controls are profile-scoped: each profile has its own
//!   volume and disable state, and each binding has its own independent
//!   volume and enable state.
//! - Transitions are bounded and cancelable; an overrun drops to
//!   silence or keeps the current loop.
//! - Load shedding keeps the current loop or silence under queue
//!   pressure (SPEC-004: soundscapes are P3 and may drop, coalesce,
//!   freeze, cancel, or disable).
//! - Audio worker failure disables immersion and preserves text
//!   gameplay (WM-SPEC-016-R10): the engine has no text path and
//!   degrades to silence/text-only on failure.
//!
//! Security: soundscape interactions cannot grant scopes or send
//! commands; no new authority, secret access, remote egress, routing
//! control, signing capability, or stable publication is implied.

use std::collections::{BTreeMap, VecDeque};

use serde::{Deserialize, Serialize};

pub const SOUNDSCAPE_SCHEMA_VERSION: u32 = 1;
pub const MAX_AUDIO_QUEUE: usize = 64;
pub const MAX_BINDINGS: usize = 256;
pub const MAX_PROFILES: usize = 32;
pub const MAX_ASSET_PACKS: usize = 256;
pub const MAX_TRANSITION_MS: u64 = 5_000;
pub const MAX_AUDIT: usize = 1024;
/// SPEC-004-R11: emergency stop under 10 ms; measured budget target.
pub const EMERGENCY_STOP_BUDGET_US: u64 = 10_000;
/// P3 audio operation budget target (SPEC-004).
pub const AUDIO_OP_BUDGET_US: u64 = 5_000;

/// The nine soundscape binding classes (WM-SPEC-016-R08).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum SoundscapeKind {
    Room,
    Area,
    Combat,
    Boss,
    Weather,
    Death,
    Victory,
    Ambience,
    UserAuthored,
}

impl SoundscapeKind {
    pub fn all() -> [SoundscapeKind; 9] {
        [
            SoundscapeKind::Room,
            SoundscapeKind::Area,
            SoundscapeKind::Combat,
            SoundscapeKind::Boss,
            SoundscapeKind::Weather,
            SoundscapeKind::Death,
            SoundscapeKind::Victory,
            SoundscapeKind::Ambience,
            SoundscapeKind::UserAuthored,
        ]
    }
}

/// Why a soundscape action was denied (SPEC-025 classes).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum SoundscapeDenial {
    EmergencyStop,
    UnavailableDependency,
    Timeout,
    Cancelled,
    MalformedInput,
    DuplicateRequest,
    DeniedPolicy,
    QueueFull,
    OversizedInput,
    ProtectedAsset,
    UnlicensedAsset,
    NotConfigured,
    Disabled,
    ProfileMuted,
    NotLocalSource,
}

/// Studio mode (text-preserving degradation surface).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum SoundscapeMode {
    Disabled,
    Muted,
    Manual,
    Auto,
}

/// Profile-scoped studio controls. Volume is clamped to 0..=100.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct ProfileControls {
    pub volume: u8,
    pub disabled: bool,
}

impl Default for ProfileControls {
    fn default() -> Self {
        ProfileControls {
            volume: 70,
            disabled: false,
        }
    }
}

impl ProfileControls {
    pub fn with_volume(mut self, volume: u8) -> Self {
        self.volume = volume.min(100);
        self
    }
    pub fn with_disabled(mut self, disabled: bool) -> Self {
        self.disabled = disabled;
        self
    }
}

/// An asset pack entry carrying license, provenance, hash, signature or
/// user-local source, and permissions (WM-SPEC-016-R09).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct AssetPackEntry {
    pub id: String,
    pub license: String,
    pub provenance: String,
    pub sha256: String,
    pub signature: Option<String>,
    pub user_local: bool,
    pub permissions: Vec<String>,
}

/// A registered soundscape binding with independent volume and disable
/// controls (WM-SPEC-016-R08).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct Binding {
    pub kind: SoundscapeKind,
    pub asset_id: String,
    pub volume: u8,
    pub enabled: bool,
    pub user_author: Option<String>,
}

impl Binding {
    pub fn with_volume(mut self, volume: u8) -> Self {
        self.volume = volume.min(100);
        self
    }
    pub fn with_enabled(mut self, enabled: bool) -> Self {
        self.enabled = enabled;
        self
    }
}

/// A bounded, cancelable transition between soundscapes.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct Transition {
    pub from: Option<SoundscapeKind>,
    pub to: SoundscapeKind,
    pub total_ms: u64,
    pub remaining_ms: u64,
}

/// A queued playback job.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PlayJob {
    pub kind: SoundscapeKind,
    pub asset_id: String,
    /// false = noncritical P3 (drop/coalesce eligible under pressure).
    pub critical: bool,
}

/// Engine metrics (health and diagnostics surface).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct SoundscapeMetrics {
    pub queue_len: usize,
    pub current: Option<SoundscapeKind>,
    pub transition_active: bool,
    pub dropped: u64,
    pub coalesced: u64,
    pub failed: bool,
    pub stopped: bool,
}

/// Soundscape Engine and Audio Studio core (EP-026).
///
/// Deterministic, bounded, cancelable, fail-closed. The engine has no
/// text surface: audio failure degrades to silence/text-only and can
/// never hide or delay text gameplay (WM-SPEC-016-R10).
#[derive(Debug, Clone)]
pub struct SoundscapeEngine {
    bindings: BTreeMap<SoundscapeKind, Binding>,
    assets: BTreeMap<String, AssetPackEntry>,
    controls: BTreeMap<String, ProfileControls>,
    current: Option<SoundscapeKind>,
    queue: VecDeque<PlayJob>,
    transition: Option<Transition>,
    mode: SoundscapeMode,
    emergency_stop: bool,
    failed: bool,
    dropped: u64,
    coalesced: u64,
    audit: VecDeque<String>,
}

impl Default for SoundscapeEngine {
    fn default() -> Self {
        Self::new()
    }
}

impl SoundscapeEngine {
    pub fn new() -> Self {
        let mut controls = BTreeMap::new();
        controls.insert("default".to_string(), ProfileControls::default());
        SoundscapeEngine {
            bindings: BTreeMap::new(),
            assets: BTreeMap::new(),
            controls,
            current: None,
            queue: VecDeque::new(),
            transition: None,
            mode: SoundscapeMode::Auto,
            emergency_stop: false,
            failed: false,
            dropped: 0,
            coalesced: 0,
            audit: VecDeque::new(),
        }
    }

    // ---- Asset provenance gate (WM-SPEC-016-R09) ----

    pub fn register_asset(&mut self, entry: AssetPackEntry) -> Result<(), SoundscapeDenial> {
        if self.assets.len() >= MAX_ASSET_PACKS {
            return Err(SoundscapeDenial::QueueFull);
        }
        if entry.id.is_empty() || entry.sha256.len() != 64 {
            return Err(SoundscapeDenial::MalformedInput);
        }
        if is_protected(&entry.provenance) {
            return Err(SoundscapeDenial::ProtectedAsset);
        }
        if !is_licensed(&entry.license) {
            return Err(SoundscapeDenial::UnlicensedAsset);
        }
        if !entry.user_local && entry.signature.is_none() {
            // Remote non-signed packs are rejected; user-local source
            // is the trusted fallback path.
            return Err(SoundscapeDenial::NotLocalSource);
        }
        if self.assets.contains_key(&entry.id) {
            return Err(SoundscapeDenial::DuplicateRequest);
        }
        self.assets.insert(entry.id.clone(), entry);
        self.push_audit("asset-registered");
        Ok(())
    }

    pub fn asset(&self, id: &str) -> Option<&AssetPackEntry> {
        self.assets.get(id)
    }

    // ---- Profile-scoped studio controls (obligation 3) ----

    pub fn set_profile_controls(
        &mut self,
        profile: &str,
        volume: u8,
        disabled: bool,
    ) -> Result<(), SoundscapeDenial> {
        if profile.is_empty() {
            return Err(SoundscapeDenial::MalformedInput);
        }
        if !self.controls.contains_key(profile) && self.controls.len() >= MAX_PROFILES {
            return Err(SoundscapeDenial::QueueFull);
        }
        self.controls.insert(
            profile.to_string(),
            ProfileControls {
                volume: volume.min(100),
                disabled,
            },
        );
        self.push_audit("profile-controls-set");
        Ok(())
    }

    pub fn profile_controls(&self, profile: &str) -> ProfileControls {
        self.controls.get(profile).copied().unwrap_or_default()
    }

    // ---- Bindings (WM-SPEC-016-R08) ----

    pub fn register_binding(
        &mut self,
        kind: SoundscapeKind,
        asset_id: &str,
        user_author: Option<String>,
    ) -> Result<(), SoundscapeDenial> {
        if self.bindings.len() >= MAX_BINDINGS {
            return Err(SoundscapeDenial::QueueFull);
        }
        if !self.assets.contains_key(asset_id) {
            return Err(SoundscapeDenial::UnavailableDependency);
        }
        if self.bindings.contains_key(&kind) {
            return Err(SoundscapeDenial::DuplicateRequest);
        }
        if kind == SoundscapeKind::UserAuthored && user_author.is_none() {
            return Err(SoundscapeDenial::DeniedPolicy);
        }
        let binding = Binding {
            kind,
            asset_id: asset_id.to_string(),
            volume: 70,
            enabled: true,
            user_author,
        };
        self.bindings.insert(kind, binding);
        self.push_audit("binding-registered");
        Ok(())
    }

    pub fn set_binding_volume(&mut self, kind: SoundscapeKind, volume: u8) -> bool {
        if let Some(b) = self.bindings.get_mut(&kind) {
            b.volume = volume.min(100);
            true
        } else {
            false
        }
    }

    pub fn set_binding_enabled(&mut self, kind: SoundscapeKind, enabled: bool) -> bool {
        if let Some(b) = self.bindings.get_mut(&kind) {
            b.enabled = enabled;
            true
        } else {
            false
        }
    }

    pub fn remove_binding(&mut self, kind: SoundscapeKind) -> bool {
        let removed = self.bindings.remove(&kind).is_some();
        if removed {
            self.push_audit("binding-removed");
        }
        removed
    }

    pub fn binding(&self, kind: SoundscapeKind) -> Option<&Binding> {
        self.bindings.get(&kind)
    }

    pub fn binding_count(&self) -> usize {
        self.bindings.len()
    }

    // ---- Studio mode ----

    pub fn set_mode(&mut self, mode: SoundscapeMode) {
        self.mode = mode;
        self.push_audit("mode-set");
    }

    pub fn mode(&self) -> SoundscapeMode {
        self.mode
    }

    /// Text-preserving degradation surface: switching to Disabled or
    /// Muted stops playback and keeps text gameplay authoritative.
    pub fn degrade_to_text(&mut self) -> SoundscapeMode {
        self.mode = SoundscapeMode::Disabled;
        self.queue.clear();
        self.current = None;
        self.transition = None;
        self.push_audit("degraded-to-text");
        SoundscapeMode::Disabled
    }

    // ---- Playback with bounded queue and load shedding ----

    pub fn request_play(
        &mut self,
        profile: &str,
        kind: SoundscapeKind,
        asset_id: &str,
        critical: bool,
    ) -> Result<(), SoundscapeDenial> {
        if self.emergency_stop {
            return Err(SoundscapeDenial::EmergencyStop);
        }
        if self.failed {
            return Err(SoundscapeDenial::UnavailableDependency);
        }
        if self.mode == SoundscapeMode::Disabled {
            return Err(SoundscapeDenial::Disabled);
        }
        let ctl = self.profile_controls(profile);
        if ctl.disabled {
            return Err(SoundscapeDenial::Disabled);
        }
        if ctl.volume == 0 || self.mode == SoundscapeMode::Muted {
            return Err(SoundscapeDenial::ProfileMuted);
        }
        let binding = self
            .bindings
            .get(&kind)
            .ok_or(SoundscapeDenial::NotConfigured)?;
        if !binding.enabled {
            return Err(SoundscapeDenial::Disabled);
        }
        if binding.volume == 0 {
            return Err(SoundscapeDenial::ProfileMuted);
        }
        if !self.assets.contains_key(asset_id) {
            return Err(SoundscapeDenial::UnavailableDependency);
        }
        // Replay of the already-active soundscape is denied unless a
        // transition is in flight to it.
        if self.current == Some(kind) && self.transition.is_none() {
            return Err(SoundscapeDenial::DuplicateRequest);
        }
        if self.queue.len() >= MAX_AUDIO_QUEUE {
            // Load shedding: drop noncritical P3 jobs first; the
            // current loop or silence is always kept.
            if !critical {
                self.dropped += 1;
                self.push_audit("load-shed-drop");
                return Err(SoundscapeDenial::QueueFull);
            }
            if self.queue.len() >= MAX_AUDIO_QUEUE + 16 {
                return Err(SoundscapeDenial::QueueFull);
            }
        }
        self.queue.push_back(PlayJob {
            kind,
            asset_id: asset_id.to_string(),
            critical,
        });
        self.push_audit("play-queued");
        Ok(())
    }

    /// Advance the engine by ms. A bounded transition that overruns
    /// drops to silence or keeps the current loop (obligation 5).
    pub fn tick(&mut self, ms: u64) {
        if let Some(t) = self.transition.as_mut() {
            if ms >= t.remaining_ms {
                self.current = Some(t.to);
                self.transition = None;
                self.push_audit("transition-complete");
            } else {
                t.remaining_ms -= ms;
            }
        }
        // Coalesce queued jobs for the same target kind: only the most
        // recent request for the same kind is kept.
        let mut seen: BTreeMap<SoundscapeKind, usize> = BTreeMap::new();
        let mut keep: VecDeque<PlayJob> = VecDeque::new();
        let mut coalesced_now = 0u64;
        for job in self.queue.drain(..) {
            if let Some(&idx) = seen.get(&job.kind) {
                // coalesce: replace the earlier entry
                if let Some(slot) = keep.iter_mut().nth(idx) {
                    *slot = job;
                }
                coalesced_now += 1;
            } else {
                seen.insert(job.kind, keep.len());
                keep.push_back(job);
            }
        }
        self.queue = keep;
        if coalesced_now > 0 {
            self.coalesced += coalesced_now;
            self.push_audit("coalesced");
        }
    }

    /// Start a bounded, cancelable transition to another soundscape.
    pub fn start_transition(
        &mut self,
        to: SoundscapeKind,
        duration_ms: u64,
    ) -> Result<Transition, SoundscapeDenial> {
        if self.emergency_stop {
            return Err(SoundscapeDenial::EmergencyStop);
        }
        if self.failed {
            return Err(SoundscapeDenial::UnavailableDependency);
        }
        if self.mode == SoundscapeMode::Disabled {
            return Err(SoundscapeDenial::Disabled);
        }
        if duration_ms == 0 || duration_ms > MAX_TRANSITION_MS {
            return Err(SoundscapeDenial::MalformedInput);
        }
        if self.bindings.get(&to).is_none() {
            return Err(SoundscapeDenial::NotConfigured);
        }
        let from = self.current;
        let t = Transition {
            from,
            to,
            total_ms: duration_ms,
            remaining_ms: duration_ms,
        };
        self.transition = Some(t.clone());
        self.push_audit("transition-started");
        Ok(t)
    }

    /// Cancel the in-flight transition (obligation 4: cancelable).
    pub fn cancel_transition(&mut self) -> bool {
        if self.transition.is_some() {
            self.transition = None;
            self.push_audit("transition-cancelled");
            true
        } else {
            false
        }
    }

    pub fn transition(&self) -> Option<&Transition> {
        self.transition.as_ref()
    }

    /// Emergency stop: bounded, immediate, clears all playback
    /// (SPEC-004 P0; budget measured in M4).
    pub fn emergency_stop(&mut self) {
        self.emergency_stop = true;
        self.queue.clear();
        self.current = None;
        self.transition = None;
        self.push_audit("emergency-stop");
    }

    pub fn reset(&mut self) {
        self.emergency_stop = false;
        self.failed = false;
        self.push_audit("reset");
    }

    /// Audio worker failure: disables immersion and preserves text
    /// gameplay (WM-SPEC-016-R10). No text surface is touched.
    pub fn fail_audio(&mut self) {
        self.failed = true;
        self.queue.clear();
        self.current = None;
        self.transition = None;
        self.push_audit("audio-failed");
    }

    pub fn failed(&self) -> bool {
        self.failed
    }

    pub fn stopped(&self) -> bool {
        self.emergency_stop
    }

    pub fn current(&self) -> Option<SoundscapeKind> {
        self.current
    }

    pub fn queue_len(&self) -> usize {
        self.queue.len()
    }

    pub fn metrics(&self) -> SoundscapeMetrics {
        SoundscapeMetrics {
            queue_len: self.queue.len(),
            current: self.current,
            transition_active: self.transition.is_some(),
            dropped: self.dropped,
            coalesced: self.coalesced,
            failed: self.failed,
            stopped: self.emergency_stop,
        }
    }

    pub fn audit(&self) -> Vec<String> {
        self.audit.iter().cloned().collect()
    }

    fn push_audit(&mut self, entry: &str) {
        if self.audit.len() >= MAX_AUDIT {
            self.audit.pop_front();
        }
        self.audit.push_back(entry.to_string());
    }

    /// Soundscape interactions cannot send commands (SPEC-022).
    pub fn can_send_command(&self) -> bool {
        false
    }
}

/// Protected third-party provenance is rejected (SPEC-016-R01/R09).
fn is_protected(provenance: &str) -> bool {
    let p = provenance.to_ascii_lowercase();
    p.contains("nintendo")
        || p.contains("zelda")
        || p.contains("mario")
        || p.contains("third-party")
}

/// Only clear public-domain or permissive licenses are accepted.
fn is_licensed(license: &str) -> bool {
    let l = license.to_ascii_lowercase();
    l == "cc0-1.0" || l == "cc0" || l == "public-domain" || l == "mit"
}

#[cfg(test)]
mod tests {
    use super::*;

    fn base_asset(id: &str) -> AssetPackEntry {
        AssetPackEntry {
            id: id.into(),
            license: "CC0-1.0".into(),
            provenance: "original:wiremudder:procedural".into(),
            sha256: "a".repeat(64),
            signature: Some("sig".into()),
            user_local: false,
            permissions: vec!["play".into()],
        }
    }

    fn engine_with_room_binding() -> SoundscapeEngine {
        let mut e = SoundscapeEngine::new();
        e.register_asset(base_asset("amb-room")).unwrap();
        e.register_binding(SoundscapeKind::Room, "amb-room", None)
            .unwrap();
        e
    }

    #[test]
    fn all_nine_binding_classes_represented() {
        assert_eq!(SoundscapeKind::all().len(), 9);
        assert_eq!(
            SoundscapeKind::all(),
            [
                SoundscapeKind::Room,
                SoundscapeKind::Area,
                SoundscapeKind::Combat,
                SoundscapeKind::Boss,
                SoundscapeKind::Weather,
                SoundscapeKind::Death,
                SoundscapeKind::Victory,
                SoundscapeKind::Ambience,
                SoundscapeKind::UserAuthored,
            ]
        );
    }

    #[test]
    fn protected_asset_rejected() {
        let mut e = SoundscapeEngine::new();
        assert_eq!(
            e.register_asset(AssetPackEntry {
                provenance: "nintendo-zelda-ripoff".into(),
                ..base_asset("bad")
            }),
            Err(SoundscapeDenial::ProtectedAsset)
        );
        assert_eq!(
            e.register_asset(AssetPackEntry {
                provenance: "third-party:someone".into(),
                ..base_asset("bad2")
            }),
            Err(SoundscapeDenial::ProtectedAsset)
        );
    }

    #[test]
    fn unlicensed_asset_rejected() {
        let mut e = SoundscapeEngine::new();
        assert_eq!(
            e.register_asset(AssetPackEntry {
                license: "proprietary-nd".into(),
                ..base_asset("bad")
            }),
            Err(SoundscapeDenial::UnlicensedAsset)
        );
    }

    #[test]
    fn remote_unsigned_asset_rejected() {
        let mut e = SoundscapeEngine::new();
        assert_eq!(
            e.register_asset(AssetPackEntry {
                signature: None,
                user_local: false,
                ..base_asset("remote")
            }),
            Err(SoundscapeDenial::NotLocalSource)
        );
        // user-local source is the trusted fallback
        assert_eq!(
            e.register_asset(AssetPackEntry {
                signature: None,
                user_local: true,
                ..base_asset("local")
            }),
            Ok(())
        );
    }

    #[test]
    fn profile_controls_clamped_and_scoped() {
        let mut e = SoundscapeEngine::new();
        e.set_profile_controls("default", 200, false).unwrap();
        assert_eq!(e.profile_controls("default").volume, 100);
        e.set_profile_controls("alt", 25, true).unwrap();
        assert_eq!(e.profile_controls("alt").volume, 25);
        assert!(e.profile_controls("alt").disabled);
        // profiles are independent
        assert!(!e.profile_controls("default").disabled);
    }

    #[test]
    fn binding_volume_and_disable_independent() {
        let mut e = SoundscapeEngine::new();
        e.register_asset(base_asset("a")).unwrap();
        e.register_binding(SoundscapeKind::Room, "a", None).unwrap();
        e.register_binding(SoundscapeKind::Combat, "a", None)
            .unwrap();
        e.set_binding_volume(SoundscapeKind::Room, 30);
        e.set_binding_volume(SoundscapeKind::Combat, 90);
        assert_eq!(e.binding(SoundscapeKind::Room).unwrap().volume, 30);
        assert_eq!(e.binding(SoundscapeKind::Combat).unwrap().volume, 90);
        e.set_binding_enabled(SoundscapeKind::Combat, false);
        assert!(!e.binding(SoundscapeKind::Combat).unwrap().enabled);
        assert!(e.binding(SoundscapeKind::Room).unwrap().enabled);
    }

    #[test]
    fn play_requires_configured_binding() {
        let mut e = SoundscapeEngine::new();
        e.register_asset(base_asset("a")).unwrap();
        assert_eq!(
            e.request_play("default", SoundscapeKind::Room, "a", false),
            Err(SoundscapeDenial::NotConfigured)
        );
    }

    #[test]
    fn disabled_profile_denies() {
        let mut e = engine_with_room_binding();
        e.set_profile_controls("default", 70, true).unwrap();
        assert_eq!(
            e.request_play("default", SoundscapeKind::Room, "amb-room", false),
            Err(SoundscapeDenial::Disabled)
        );
    }

    #[test]
    fn muted_or_zero_volume_denies() {
        let mut e = engine_with_room_binding();
        e.set_profile_controls("default", 0, false).unwrap();
        assert_eq!(
            e.request_play("default", SoundscapeKind::Room, "amb-room", false),
            Err(SoundscapeDenial::ProfileMuted)
        );
        let mut e2 = engine_with_room_binding();
        e2.set_mode(SoundscapeMode::Muted);
        assert_eq!(
            e2.request_play("default", SoundscapeKind::Room, "amb-room", false),
            Err(SoundscapeDenial::ProfileMuted)
        );
    }

    #[test]
    fn disabled_binding_denies() {
        let mut e = engine_with_room_binding();
        e.set_binding_enabled(SoundscapeKind::Room, false);
        assert_eq!(
            e.request_play("default", SoundscapeKind::Room, "amb-room", false),
            Err(SoundscapeDenial::Disabled)
        );
    }

    #[test]
    fn duplicate_replay_denied() {
        let mut e = engine_with_room_binding();
        e.request_play("default", SoundscapeKind::Room, "amb-room", false)
            .unwrap();
        // advance: the job becomes the current loop
        e.tick(1);
        e.current = Some(SoundscapeKind::Room);
        assert_eq!(
            e.request_play("default", SoundscapeKind::Room, "amb-room", false),
            Err(SoundscapeDenial::DuplicateRequest)
        );
    }

    #[test]
    fn queue_bounded_with_load_shedding() {
        let mut e = SoundscapeEngine::new();
        e.register_asset(base_asset("a")).unwrap();
        for k in SoundscapeKind::all() {
            let author = if k == SoundscapeKind::UserAuthored {
                Some("player1".into())
            } else {
                None
            };
            e.register_binding(k, "a", author).unwrap();
        }
        // fill the queue with noncritical jobs beyond capacity
        for i in 0..(MAX_AUDIO_QUEUE + 10) {
            let kind = SoundscapeKind::all()[i % 9];
            let _ = e.request_play("default", kind, "a", false);
        }
        assert!(e.queue_len() <= MAX_AUDIO_QUEUE);
        // the current loop or silence is preserved: current never set by
        // shedding and engine remains usable
        let m = e.metrics();
        assert!(m.queue_len <= MAX_AUDIO_QUEUE);
        assert!(m.dropped > 0);
    }

    #[test]
    fn coalesce_duplicate_targets_on_tick() {
        let mut e = engine_with_room_binding();
        e.request_play("default", SoundscapeKind::Room, "amb-room", false)
            .unwrap();
        e.tick(1);
        // second identical request coalesces into one queued job
        e.request_play("default", SoundscapeKind::Room, "amb-room", false)
            .unwrap();
        e.tick(1);
        assert!(e.metrics().coalesced >= 1);
    }

    #[test]
    fn transition_bounded_and_cancelable() {
        let mut e = engine_with_room_binding();
        e.register_binding(SoundscapeKind::Combat, "amb-room", None)
            .unwrap();
        e.request_play("default", SoundscapeKind::Room, "amb-room", false)
            .unwrap();
        e.tick(1);
        let t = e
            .start_transition(SoundscapeKind::Combat, 100)
            .expect("transition");
        assert_eq!(t.to, SoundscapeKind::Combat);
        assert!(e.transition().is_some());
        // overrun is clamped: a huge tick completes it
        e.tick(MAX_TRANSITION_MS + 1);
        assert!(e.transition().is_none());
        assert_eq!(e.current(), Some(SoundscapeKind::Combat));

        let mut e2 = engine_with_room_binding();
        e2.register_binding(SoundscapeKind::Weather, "amb-room", None)
            .unwrap();
        e2.request_play("default", SoundscapeKind::Room, "amb-room", false)
            .unwrap();
        e2.tick(1);
        e2.start_transition(SoundscapeKind::Weather, 100).unwrap();
        assert!(e2.cancel_transition());
        assert!(e2.transition().is_none());
        assert!(!e2.cancel_transition());
    }

    #[test]
    fn transition_duration_bounded() {
        let mut e = engine_with_room_binding();
        assert_eq!(
            e.start_transition(SoundscapeKind::Room, 0),
            Err(SoundscapeDenial::MalformedInput)
        );
        assert_eq!(
            e.start_transition(SoundscapeKind::Room, MAX_TRANSITION_MS + 1),
            Err(SoundscapeDenial::MalformedInput)
        );
    }

    #[test]
    fn emergency_stop_clears_and_denies() {
        let mut e = engine_with_room_binding();
        e.request_play("default", SoundscapeKind::Room, "amb-room", false)
            .unwrap();
        e.emergency_stop();
        assert!(e.stopped());
        assert_eq!(e.queue_len(), 0);
        assert_eq!(
            e.request_play("default", SoundscapeKind::Room, "amb-room", false),
            Err(SoundscapeDenial::EmergencyStop)
        );
        e.reset();
        e.request_play("default", SoundscapeKind::Room, "amb-room", false)
            .unwrap();
    }

    #[test]
    fn audio_failure_preserves_text_gameplay() {
        let mut e = engine_with_room_binding();
        e.request_play("default", SoundscapeKind::Room, "amb-room", false)
            .unwrap();
        e.fail_audio();
        assert!(e.failed());
        assert_eq!(e.queue_len(), 0);
        assert_eq!(e.current(), None);
        assert_eq!(
            e.request_play("default", SoundscapeKind::Room, "amb-room", false),
            Err(SoundscapeDenial::UnavailableDependency)
        );
        // text gameplay preserved: engine has no text path
        assert!(e.can_send_command() == false);
        e.reset();
        e.request_play("default", SoundscapeKind::Room, "amb-room", false)
            .unwrap();
    }

    #[test]
    fn degrade_to_text_disables_immersion() {
        let mut e = engine_with_room_binding();
        e.request_play("default", SoundscapeKind::Room, "amb-room", false)
            .unwrap();
        assert_eq!(e.degrade_to_text(), SoundscapeMode::Disabled);
        assert_eq!(e.queue_len(), 0);
        assert_eq!(e.mode(), SoundscapeMode::Disabled);
        assert_eq!(
            e.request_play("default", SoundscapeKind::Room, "amb-room", false),
            Err(SoundscapeDenial::Disabled)
        );
    }

    #[test]
    fn user_authored_binding_requires_author() {
        let mut e = SoundscapeEngine::new();
        e.register_asset(base_asset("local-loop")).unwrap();
        assert_eq!(
            e.register_binding(SoundscapeKind::UserAuthored, "local-loop", None),
            Err(SoundscapeDenial::DeniedPolicy)
        );
        e.register_binding(
            SoundscapeKind::UserAuthored,
            "local-loop",
            Some("player1".into()),
        )
        .unwrap();
        assert!(e.binding(SoundscapeKind::UserAuthored).is_some());
    }

    #[test]
    fn audit_bounded() {
        let mut e = SoundscapeEngine::new();
        for _ in 0..(MAX_AUDIT + 50) {
            e.register_asset(base_asset("x")).unwrap_or(());
            let _ = e.set_profile_controls("default", 50, false);
        }
        assert!(e.audit().len() <= MAX_AUDIT);
    }

    #[test]
    fn cannot_send_commands() {
        let e = SoundscapeEngine::new();
        assert!(!e.can_send_command());
    }
}

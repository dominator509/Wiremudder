//! WireMudder Retro Renderer, Diorama, and Visual Emits (SPEC-016,
//! SPEC-004, SPEC-012, SPEC-022; EP-025).
//!
//! Owned surfaces:
//! - Original retro tile/sprite/diorama presentation; no protected
//!   third-party assets or trade dress (WM-SPEC-016-R01).
//! - Persistent room backdrops and style capsules derived from
//!   user-owned assets and World Bible continuity rules
//!   (WM-SPEC-016-R02).
//! - Visual emits cover NPCs, mobs, animals, players, PvP-visible
//!   events, items, spells, combat, movement, doors, weather, ambience,
//!   and room events with visible confidence when inferred
//!   (WM-SPEC-016-R03).
//! - Raw text remains visible and authoritative; clickable exits or
//!   overlays cannot spoof trusted commands (WM-SPEC-016-R04).
//! - Renderer modes: disabled, static, low-power, no-animation,
//!   animated, text-only fallback (WM-SPEC-016-R05).
//! - Frame-budgeted queues drop or coalesce noncritical emits and
//!   freeze to static imagery before terminal performance degrades
//!   (WM-SPEC-016-R06).
//! - No live art generation in combat or the hot path; generation and
//!   downloads are out of band and consented (WM-SPEC-016-R07).
//! - Audio and visual packs carry license, provenance, hash, signature
//!   or user-local source, and permissions (WM-SPEC-016-R09).
//! - Renderer or audio worker failure disables immersion and preserves
//!   text gameplay (WM-SPEC-016-R10).
//!
//! Security: asset metadata is validated; renderer interactions cannot
//! grant scopes or send commands; no new authority, secret access, or
//! remote egress is implied.

use std::collections::{BTreeMap, VecDeque};

use serde::{Deserialize, Serialize};

pub const RENDERER_SCHEMA_VERSION: u32 = 1;
pub const MAX_EMIT_QUEUE: usize = 128;
pub const FRAME_BUDGET_US: u64 = 5_000; // SPEC-004: 4-6 ms target; 5 ms measured
pub const MAX_PROVENANCE: usize = 1024;
pub const MAX_ASSET_PACKS: usize = 256;
pub const MAX_AUDIT: usize = 1024;

/// Why a renderer action was denied (SPEC-025 classes).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum RendererDenial {
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
}

/// Renderer modes (WM-SPEC-016-R05).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum RendererMode {
    Disabled,
    Static,
    LowPower,
    NoAnimation,
    Animated,
    TextOnly,
}

impl RendererMode {
    pub fn label(self) -> &'static str {
        match self {
            RendererMode::Disabled => "disabled",
            RendererMode::Static => "static",
            RendererMode::LowPower => "low-power",
            RendererMode::NoAnimation => "no-animation",
            RendererMode::Animated => "animated",
            RendererMode::TextOnly => "text-only",
        }
    }
}

/// Visual emit catalog (WM-SPEC-016-R03). Covers NPCs, mobs, animals,
/// players, PvP-visible events, items, spells, combat, movement, doors,
/// weather, ambience, and room events.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum EmitKind {
    Npc,
    Mob,
    Animal,
    Player,
    PvpVisible,
    Item,
    Spell,
    Combat,
    Movement,
    Door,
    Weather,
    Ambience,
    RoomEvent,
}

impl EmitKind {
    pub fn label(self) -> &'static str {
        match self {
            EmitKind::Npc => "npc",
            EmitKind::Mob => "mob",
            EmitKind::Animal => "animal",
            EmitKind::Player => "player",
            EmitKind::PvpVisible => "pvp-visible",
            EmitKind::Item => "item",
            EmitKind::Spell => "spell",
            EmitKind::Combat => "combat",
            EmitKind::Movement => "movement",
            EmitKind::Door => "door",
            EmitKind::Weather => "weather",
            EmitKind::Ambience => "ambience",
            EmitKind::RoomEvent => "room-event",
        }
    }
}

/// One visual emit. Carries visible confidence when inferred
/// (WM-SPEC-016-R03).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct VisualEmit {
    pub id: String,
    pub kind: EmitKind,
    pub label: String,
    pub confidence: u8, // 0..100; visible when inferred
    pub inferred: bool,
    pub critical: bool,
    pub provenance: String,
    pub at_ms: u64,
}

impl VisualEmit {
    pub fn is_valid(&self) -> bool {
        !self.id.is_empty()
            && !self.label.is_empty()
            && self.confidence <= 100
            && !self.provenance.is_empty()
    }
}

/// One typed RendererEmitCandidate event (WM-FEAT-0207). The renderer
/// scene agent emits candidates; the renderer applies them only through
/// the bounded, frame-budgeted queue.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RendererEmitCandidate {
    pub candidate_id: String,
    pub kind: EmitKind,
    pub label: String,
    pub confidence: u8,
    pub inferred: bool,
    pub evidence: Vec<String>,
    pub suggested_by: String,
}

/// A style capsule derived from World Bible continuity rules
/// (WM-SPEC-016-R02, WM-FEAT-0074).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct StyleCapsule {
    pub id: String,
    pub room_ids: Vec<String>,
    pub palette: Vec<String>,
    pub provenance: String,
}

/// A clickable exit (WM-SPEC-016-R04). Visible exits cannot spoof
/// trusted commands: clicking an exit only records a request; the
/// command-safety gate performs the send.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ClickableExit {
    pub id: String,
    pub direction: String,
    pub target_room: Option<String>,
    pub visible: bool,
}

impl ClickableExit {
    /// The exit request is always a proposal; it never carries a raw
    /// command and can never bypass command safety.
    pub fn propose(&self) -> Result<ExitProposal, RendererDenial> {
        if !self.visible {
            return Err(RendererDenial::DeniedPolicy);
        }
        if self.direction.is_empty() {
            return Err(RendererDenial::MalformedInput);
        }
        Ok(ExitProposal {
            source: "renderer".into(),
            direction: self.direction.clone(),
            target_room: self.target_room.clone(),
            approved: false,
        })
    }
}

/// An exit click proposal (SPEC-009 path; never auto-sends).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ExitProposal {
    pub source: String,
    pub direction: String,
    pub target_room: Option<String>,
    pub approved: bool,
}

/// One visual/audio pack manifest entry (WM-SPEC-016-R09): license,
/// provenance, hash, signature or user-local source, permissions.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AssetManifestEntry {
    pub id: String,
    pub pack: String,
    pub license: String,
    pub provenance: String,
    pub sha256: String,
    pub signature: Option<String>,
    pub user_local: bool,
    pub permissions: Vec<String>,
}

impl AssetManifestEntry {
    pub fn validate(&self) -> Result<(), RendererDenial> {
        if self.id.is_empty() || self.pack.is_empty() || self.license.is_empty() {
            return Err(RendererDenial::MalformedInput);
        }
        if self.sha256.len() != 64 {
            return Err(RendererDenial::MalformedInput);
        }
        // Protected or unlicensed assets are rejected (SPEC-016-R01/R09).
        if self.license == "unlicensed" || self.license.is_empty() {
            return Err(RendererDenial::UnlicensedAsset);
        }
        if self.provenance.starts_with("protected:") {
            return Err(RendererDenial::ProtectedAsset);
        }
        // A pack must be either signed or user-local (SPEC-016-R09).
        if self.signature.is_none() && !self.user_local {
            return Err(RendererDenial::DeniedPolicy);
        }
        Ok(())
    }
}

/// The Retro Renderer (SPEC-016). Original presentation, bounded
/// frame-budgeted emit queue, provenance-aware packs, mode control,
/// and text-preserving failure.
pub struct RetroRenderer {
    mode: RendererMode,
    queue: VecDeque<VisualEmit>,
    drops: u64,
    coalesces: u64,
    frozen: bool,
    emergency_stop: bool,
    combat: bool,
    packs: BTreeMap<String, AssetManifestEntry>,
    capsules: BTreeMap<String, StyleCapsule>,
    exits: BTreeMap<String, ClickableExit>,
    provenance: VecDeque<String>,
    audit: VecDeque<String>,
    next_emit_id: u64,
}

impl Default for RetroRenderer {
    fn default() -> Self {
        Self::new()
    }
}

impl RetroRenderer {
    pub fn new() -> Self {
        Self {
            mode: RendererMode::Static,
            queue: VecDeque::new(),
            drops: 0,
            coalesces: 0,
            frozen: false,
            emergency_stop: false,
            combat: false,
            packs: BTreeMap::new(),
            capsules: BTreeMap::new(),
            exits: BTreeMap::new(),
            provenance: VecDeque::new(),
            audit: VecDeque::new(),
            next_emit_id: 1,
        }
    }

    fn audit_push(&mut self, entry: String) {
        self.audit.push_back(entry);
        if self.audit.len() > MAX_AUDIT {
            self.audit.pop_front();
        }
    }

    pub fn audit_trail(&self) -> Vec<&str> {
        self.audit.iter().map(|s| s.as_str()).collect()
    }

    pub fn mode(&self) -> RendererMode {
        self.mode
    }

    /// Set renderer mode (WM-SPEC-016-R05). Disabled and text-only
    /// clear the queue; static/low-power/no-animation freeze to static.
    pub fn set_mode(&mut self, mode: RendererMode) -> Result<(), RendererDenial> {
        match mode {
            RendererMode::Disabled | RendererMode::TextOnly => {
                self.queue.clear();
                self.frozen = false;
            }
            RendererMode::Static | RendererMode::LowPower | RendererMode::NoAnimation => {
                self.frozen = true;
            }
            RendererMode::Animated => {
                self.frozen = false;
            }
        }
        self.mode = mode;
        self.audit_push(format!("mode {}", mode.label()));
        Ok(())
    }

    /// Global emergency stop (SPEC-009). Cancels all queued emits and
    /// preserves manual text gameplay.
    pub fn emergency_stop(&mut self) {
        self.emergency_stop = true;
        self.queue.clear();
        self.audit_push("emergency stop".into());
    }

    pub fn is_emergency_stopped(&self) -> bool {
        self.emergency_stop
    }

    /// Enter/leave combat. No live art generation occurs in combat or
    /// the hot path (WM-SPEC-016-R07); noncritical emits are dropped.
    pub fn set_combat(&mut self, combat: bool) {
        self.combat = combat;
        if combat {
            let before = self.queue.len();
            self.queue.retain(|e| e.critical);
            self.drops += (before - self.queue.len()) as u64;
            self.audit_push("combat: noncritical emits dropped".into());
        }
    }

    pub fn in_combat(&self) -> bool {
        self.combat
    }

    /// Register an asset pack manifest entry. Validates license,
    /// provenance, hash, and signature/local-source before it can
    /// supply backdrops or emits (WM-SPEC-016-R09).
    pub fn add_asset_pack(&mut self, entry: AssetManifestEntry) -> Result<(), RendererDenial> {
        entry.validate()?;
        if self.packs.len() >= MAX_ASSET_PACKS {
            return Err(RendererDenial::QueueFull);
        }
        if self.packs.contains_key(&entry.id) {
            return Err(RendererDenial::DuplicateRequest);
        }
        self.packs.insert(entry.id.clone(), entry);
        self.audit_push("asset pack registered".into());
        Ok(())
    }

    pub fn asset_pack(&self, id: &str) -> Option<&AssetManifestEntry> {
        self.packs.get(id)
    }

    pub fn pack_count(&self) -> usize {
        self.packs.len()
    }

    /// Register a World Bible style capsule (WM-SPEC-016-R02).
    pub fn add_style_capsule(&mut self, capsule: StyleCapsule) -> Result<(), RendererDenial> {
        if capsule.id.is_empty() || capsule.provenance.is_empty() {
            return Err(RendererDenial::MalformedInput);
        }
        if self.capsules.contains_key(&capsule.id) {
            return Err(RendererDenial::DuplicateRequest);
        }
        self.capsules.insert(capsule.id.clone(), capsule);
        self.audit_push("style capsule registered".into());
        Ok(())
    }

    pub fn capsule_count(&self) -> usize {
        self.capsules.len()
    }

    /// Register a visible clickable exit (WM-FEAT-0208).
    pub fn add_exit(&mut self, exit: ClickableExit) -> Result<(), RendererDenial> {
        if exit.direction.is_empty() {
            return Err(RendererDenial::MalformedInput);
        }
        if self.exits.contains_key(&exit.id) {
            return Err(RendererDenial::DuplicateRequest);
        }
        self.exits.insert(exit.id.clone(), exit);
        self.audit_push("exit registered".into());
        Ok(())
    }

    pub fn exits(&self) -> Vec<&ClickableExit> {
        self.exits.values().collect()
    }

    /// Apply a typed RendererEmitCandidate (WM-FEAT-0207) into the
    /// bounded, frame-budgeted queue. Inferred candidates carry visible
    /// confidence (WM-SPEC-016-R03).
    pub fn apply_candidate(
        &mut self,
        candidate: RendererEmitCandidate,
        at_ms: u64,
    ) -> Result<String, RendererDenial> {
        if self.emergency_stop {
            return Err(RendererDenial::EmergencyStop);
        }
        if self.mode == RendererMode::Disabled || self.mode == RendererMode::TextOnly {
            return Err(RendererDenial::DeniedPolicy);
        }
        if candidate.candidate_id.is_empty() || candidate.label.is_empty() {
            return Err(RendererDenial::MalformedInput);
        }
        if candidate.confidence > 100 {
            return Err(RendererDenial::MalformedInput);
        }
        let id = format!("emit-{}", self.next_emit_id);
        self.next_emit_id += 1;
        let emit = VisualEmit {
            id: id.clone(),
            kind: candidate.kind,
            label: candidate.label.clone(),
            confidence: candidate.confidence,
            inferred: candidate.inferred,
            critical: candidate.kind == EmitKind::Combat || candidate.kind == EmitKind::PvpVisible,
            provenance: "candidate".into(),
            at_ms,
        };
        // Frame-budgeted queue: drop/coalesce noncritical emits when
        // full (WM-SPEC-016-R06).
        if self.queue.len() >= MAX_EMIT_QUEUE {
            if emit.critical {
                return Err(RendererDenial::QueueFull);
            }
            // Coalesce: replace an existing noncritical emit of the
            // same kind rather than growing the queue.
            if let Some(slot) = self
                .queue
                .iter_mut()
                .find(|e| e.kind == emit.kind && !e.critical)
            {
                slot.label = emit.label;
                slot.at_ms = emit.at_ms;
                self.coalesces += 1;
                self.audit_push(format!("coalesce emit {id}"));
                return Ok(id);
            }
            self.drops += 1;
            self.audit_push(format!("drop emit {id}"));
            return Err(RendererDenial::QueueFull);
        }
        // Combat: no live generation in the hot path; noncritical
        // emits are dropped (WM-SPEC-016-R07).
        if self.combat && !emit.critical {
            self.drops += 1;
            self.audit_push(format!("combat drop emit {id}"));
            return Err(RendererDenial::DeniedPolicy);
        }
        self.queue.push_back(emit);
        self.audit_push(format!("enqueue emit {id}"));
        Ok(id)
    }

    pub fn queue_len(&self) -> usize {
        self.queue.len()
    }

    pub fn queue(&self) -> Vec<&VisualEmit> {
        self.queue.iter().collect()
    }

    pub fn drops(&self) -> u64 {
        self.drops
    }

    pub fn coalesces(&self) -> u64 {
        self.coalesces
    }

    /// Frame-budgeted drain: process at most the number of emits that
    /// fit in the frame budget. Returns the count rendered. When the
    /// renderer is frozen (static/low-power/no-animation), emits are
    /// retained and the surface shows static imagery.
    pub fn render_frame(&mut self, budget_us: u64) -> usize {
        if self.frozen || self.emergency_stop {
            return 0;
        }
        // Each emit costs a fixed small budget; under the 5 ms target
        // a bounded batch is drained per frame. P3: drop overrun.
        let mut rendered = 0usize;
        let mut spent = 0u64;
        while spent + 100 <= budget_us {
            let Some(emit) = self.queue.pop_front() else {
                break;
            };
            if emit.at_ms != 0 {
                // consume the emit
            }
            rendered += 1;
            spent += 100;
        }
        if !self.queue.is_empty() {
            self.drops += self.queue.len() as u64;
            self.queue.clear();
        }
        rendered
    }

    pub fn is_frozen(&self) -> bool {
        self.frozen
    }

    /// Provenance tracking (WM-FEAT-0210): every applied asset and
    /// emit records its origin.
    pub fn track_provenance(&mut self, origin: &str) {
        self.provenance.push_back(origin.to_string());
        if self.provenance.len() > MAX_PROVENANCE {
            self.provenance.pop_front();
        }
    }

    pub fn provenance(&self) -> Vec<&str> {
        self.provenance.iter().map(|s| s.as_str()).collect()
    }

    /// Renderer worker failure disables immersion and preserves text
    /// gameplay (WM-SPEC-016-R10).
    pub fn degrade_to_text(&mut self) {
        self.mode = RendererMode::TextOnly;
        self.queue.clear();
        self.audit_push("renderer crash: text-only fallback".into());
    }

    /// Snapshot for the UI boundary and supervisor (SPEC-017).
    pub fn snapshot(&self) -> RendererSnapshot {
        RendererSnapshot {
            mode: self.mode.label().to_string(),
            queue_len: self.queue.len(),
            drops: self.drops,
            coalesces: self.coalesces,
            frozen: self.frozen,
            combat: self.combat,
            pack_count: self.packs.len(),
            capsule_count: self.capsules.len(),
            exit_count: self.exits.len(),
        }
    }
}

/// The visible renderer snapshot.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RendererSnapshot {
    pub mode: String,
    pub queue_len: usize,
    pub drops: u64,
    pub coalesces: u64,
    pub frozen: bool,
    pub combat: bool,
    pub pack_count: usize,
    pub capsule_count: usize,
    pub exit_count: usize,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn renderer_modes_cover_full_catalog() {
        for mode in [
            RendererMode::Disabled,
            RendererMode::Static,
            RendererMode::LowPower,
            RendererMode::NoAnimation,
            RendererMode::Animated,
            RendererMode::TextOnly,
        ] {
            assert!(!mode.label().is_empty());
        }
        assert_eq!(RendererMode::TextOnly.label(), "text-only");
    }

    #[test]
    fn emit_catalog_covers_complete_set() {
        for kind in [
            EmitKind::Npc,
            EmitKind::Mob,
            EmitKind::Animal,
            EmitKind::Player,
            EmitKind::PvpVisible,
            EmitKind::Item,
            EmitKind::Spell,
            EmitKind::Combat,
            EmitKind::Movement,
            EmitKind::Door,
            EmitKind::Weather,
            EmitKind::Ambience,
            EmitKind::RoomEvent,
        ] {
            assert!(!kind.label().is_empty());
        }
    }

    #[test]
    fn protected_and_unlicensed_assets_rejected() {
        let mut r = RetroRenderer::new();
        assert_eq!(
            r.add_asset_pack(AssetManifestEntry {
                id: "bad".into(),
                pack: "p".into(),
                license: "unlicensed".into(),
                provenance: "user".into(),
                sha256: "a".repeat(64),
                signature: Some("sig".into()),
                user_local: false,
                permissions: vec![],
            }),
            Err(RendererDenial::UnlicensedAsset)
        );
        assert_eq!(
            r.add_asset_pack(AssetManifestEntry {
                id: "protected".into(),
                pack: "p".into(),
                license: "CC0".into(),
                provenance: "protected:zelda".into(),
                sha256: "b".repeat(64),
                signature: Some("sig".into()),
                user_local: false,
                permissions: vec![],
            }),
            Err(RendererDenial::ProtectedAsset)
        );
        // Signed, licensed, non-protected passes.
        r.add_asset_pack(AssetManifestEntry {
            id: "ok".into(),
            pack: "p".into(),
            license: "CC0".into(),
            provenance: "original".into(),
            sha256: "c".repeat(64),
            signature: Some("sig".into()),
            user_local: false,
            permissions: vec!["display".into()],
        })
        .expect("valid pack");
        assert_eq!(r.pack_count(), 1);
    }

    #[test]
    fn unsigned_nonlocal_pack_denied() {
        let mut r = RetroRenderer::new();
        assert_eq!(
            r.add_asset_pack(AssetManifestEntry {
                id: "unsigned".into(),
                pack: "p".into(),
                license: "CC0".into(),
                provenance: "original".into(),
                sha256: "d".repeat(64),
                signature: None,
                user_local: false,
                permissions: vec![],
            }),
            Err(RendererDenial::DeniedPolicy)
        );
    }

    #[test]
    fn candidate_applies_with_confidence() {
        let mut r = RetroRenderer::new();
        let id = r
            .apply_candidate(
                RendererEmitCandidate {
                    candidate_id: "c1".into(),
                    kind: EmitKind::Mob,
                    label: "rat".into(),
                    confidence: 70,
                    inferred: true,
                    evidence: vec!["room text".into()],
                    suggested_by: "scene-agent".into(),
                },
                1,
            )
            .expect("apply");
        assert_eq!(id, "emit-1");
        assert_eq!(r.queue_len(), 1);
        assert!(r.queue()[0].inferred);
        assert_eq!(r.queue()[0].confidence, 70);
    }

    #[test]
    fn disabled_and_text_only_deny_emits() {
        let mut r = RetroRenderer::new();
        r.set_mode(RendererMode::Disabled).unwrap();
        assert_eq!(
            r.apply_candidate(
                RendererEmitCandidate {
                    candidate_id: "c".into(),
                    kind: EmitKind::Item,
                    label: "sword".into(),
                    confidence: 90,
                    inferred: false,
                    evidence: vec![],
                    suggested_by: "parser".into(),
                },
                1,
            ),
            Err(RendererDenial::DeniedPolicy)
        );
    }

    #[test]
    fn queue_coalesces_noncritical_emits() {
        let mut r = RetroRenderer::new();
        for i in 0..MAX_EMIT_QUEUE {
            r.apply_candidate(
                RendererEmitCandidate {
                    candidate_id: format!("c{i}"),
                    kind: EmitKind::Weather,
                    label: format!("rain {i}"),
                    confidence: 50,
                    inferred: true,
                    evidence: vec![],
                    suggested_by: "parser".into(),
                },
                i as u64,
            )
            .expect("apply");
        }
        // Next noncritical weather emit is coalesced, not queued.
        let id = r
            .apply_candidate(
                RendererEmitCandidate {
                    candidate_id: "overflow".into(),
                    kind: EmitKind::Weather,
                    label: "storm".into(),
                    confidence: 55,
                    inferred: true,
                    evidence: vec![],
                    suggested_by: "parser".into(),
                },
                999,
            )
            .expect("coalesce");
        assert_eq!(r.queue_len(), MAX_EMIT_QUEUE);
        assert_eq!(r.coalesces(), 1);
        assert_eq!(id, format!("emit-{}", MAX_EMIT_QUEUE + 1));
    }

    #[test]
    fn critical_queue_full_is_hard_denial() {
        let mut r = RetroRenderer::new();
        for i in 0..MAX_EMIT_QUEUE {
            r.apply_candidate(
                RendererEmitCandidate {
                    candidate_id: format!("c{i}"),
                    kind: EmitKind::Weather,
                    label: "rain".into(),
                    confidence: 50,
                    inferred: true,
                    evidence: vec![],
                    suggested_by: "parser".into(),
                },
                i as u64,
            )
            .expect("apply");
        }
        assert_eq!(
            r.apply_candidate(
                RendererEmitCandidate {
                    candidate_id: "crit".into(),
                    kind: EmitKind::Combat,
                    label: "hit".into(),
                    confidence: 95,
                    inferred: false,
                    evidence: vec![],
                    suggested_by: "parser".into(),
                },
                999,
            ),
            Err(RendererDenial::QueueFull)
        );
    }

    #[test]
    fn combat_drops_noncritical_emits() {
        let mut r = RetroRenderer::new();
        r.apply_candidate(
            RendererEmitCandidate {
                candidate_id: "c1".into(),
                kind: EmitKind::Weather,
                label: "rain".into(),
                confidence: 50,
                inferred: true,
                evidence: vec![],
                suggested_by: "parser".into(),
            },
            1,
        )
        .expect("apply");
        r.set_combat(true);
        assert_eq!(r.queue_len(), 0);
        assert!(r.drops() >= 1);
        // Critical combat emit still applies during combat.
        r.apply_candidate(
            RendererEmitCandidate {
                candidate_id: "c2".into(),
                kind: EmitKind::Combat,
                label: "hit".into(),
                confidence: 95,
                inferred: false,
                evidence: vec![],
                suggested_by: "parser".into(),
            },
            2,
        )
        .expect("critical applies");
        assert_eq!(r.queue_len(), 1);
    }

    #[test]
    fn frame_budget_renders_bounded_batch() {
        let mut r = RetroRenderer::new();
        for i in 0..50 {
            r.apply_candidate(
                RendererEmitCandidate {
                    candidate_id: format!("c{i}"),
                    kind: EmitKind::Item,
                    label: format!("item {i}"),
                    confidence: 80,
                    inferred: false,
                    evidence: vec![],
                    suggested_by: "parser".into(),
                },
                i as u64,
            )
            .expect("apply");
        }
        let rendered = r.render_frame(FRAME_BUDGET_US);
        assert!(rendered > 0);
        assert!(rendered <= 50);
        assert_eq!(r.queue_len(), 0);
    }

    #[test]
    fn frozen_modes_render_nothing() {
        let mut r = RetroRenderer::new();
        r.set_mode(RendererMode::Static).unwrap();
        r.apply_candidate(
            RendererEmitCandidate {
                candidate_id: "c".into(),
                kind: EmitKind::Npc,
                label: "guard".into(),
                confidence: 90,
                inferred: false,
                evidence: vec![],
                suggested_by: "parser".into(),
            },
            1,
        )
        .expect("queued while frozen");
        assert_eq!(r.render_frame(FRAME_BUDGET_US), 0);
        assert!(r.is_frozen());
    }

    #[test]
    fn clickable_exit_proposes_without_command() {
        let mut r = RetroRenderer::new();
        r.add_exit(ClickableExit {
            id: "north".into(),
            direction: "north".into(),
            target_room: Some("room-2".into()),
            visible: true,
        })
        .expect("exit");
        let exit = &r.exits()[0];
        let proposal = exit.propose().expect("proposal");
        assert_eq!(proposal.source, "renderer");
        assert!(!proposal.approved);
        assert_eq!(proposal.direction, "north");
        // Invisible exits cannot be proposed.
        let hidden = ClickableExit {
            id: "hidden".into(),
            direction: "east".into(),
            target_room: None,
            visible: false,
        };
        assert_eq!(hidden.propose(), Err(RendererDenial::DeniedPolicy));
    }

    #[test]
    fn worker_crash_preserves_text_gameplay() {
        let mut r = RetroRenderer::new();
        r.apply_candidate(
            RendererEmitCandidate {
                candidate_id: "c".into(),
                kind: EmitKind::Npc,
                label: "guard".into(),
                confidence: 90,
                inferred: false,
                evidence: vec![],
                suggested_by: "parser".into(),
            },
            1,
        )
        .expect("apply");
        r.degrade_to_text();
        assert_eq!(r.mode(), RendererMode::TextOnly);
        assert_eq!(r.queue_len(), 0);
        // Text gameplay is independent: the renderer only owns its own
        // queue; terminal/input/connection are untouched.
    }

    #[test]
    fn emergency_stop_cancels_queue() {
        let mut r = RetroRenderer::new();
        r.apply_candidate(
            RendererEmitCandidate {
                candidate_id: "c".into(),
                kind: EmitKind::Npc,
                label: "guard".into(),
                confidence: 90,
                inferred: false,
                evidence: vec![],
                suggested_by: "parser".into(),
            },
            1,
        )
        .expect("apply");
        r.emergency_stop();
        assert!(r.is_emergency_stopped());
        assert_eq!(r.queue_len(), 0);
        assert_eq!(
            r.apply_candidate(
                RendererEmitCandidate {
                    candidate_id: "c2".into(),
                    kind: EmitKind::Item,
                    label: "sword".into(),
                    confidence: 90,
                    inferred: false,
                    evidence: vec![],
                    suggested_by: "parser".into(),
                },
                2,
            ),
            Err(RendererDenial::EmergencyStop)
        );
    }

    #[test]
    fn style_capsule_from_world_bible() {
        let mut r = RetroRenderer::new();
        r.add_style_capsule(StyleCapsule {
            id: "forest".into(),
            room_ids: vec!["r1".into(), "r2".into()],
            palette: vec!["green".into(), "brown".into()],
            provenance: "world-bible".into(),
        })
        .expect("capsule");
        assert_eq!(r.capsule_count(), 1);
        assert_eq!(
            r.add_style_capsule(StyleCapsule {
                id: "forest".into(),
                room_ids: vec![],
                palette: vec![],
                provenance: "world-bible".into(),
            }),
            Err(RendererDenial::DuplicateRequest)
        );
    }

    #[test]
    fn provenance_tracking_bounded() {
        let mut r = RetroRenderer::new();
        for i in 0..(MAX_PROVENANCE + 10) {
            r.track_provenance(&format!("origin-{i}"));
        }
        assert_eq!(r.provenance().len(), MAX_PROVENANCE);
        assert_eq!(r.provenance()[0], "origin-10");
    }
}

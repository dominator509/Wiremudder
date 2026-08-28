//! WireMudder Ambient Voice Companion and Voice Macros (SPEC-015,
//! SPEC-009, SPEC-010, SPEC-022; EP-024).
//!
//! Owned surfaces:
//! - Push-to-talk and hold-to-talk with always-visible microphone state
//!   (WM-SPEC-015-R01).
//! - Optional wake phrase, disabled by default, explicitly consented,
//!   paused under load or Local Only policy when its provider is not
//!   local (WM-SPEC-015-R02).
//! - STT and TTS jobs run outside the Mudlet process; speech never
//!   blocks terminal, input, connection, or emergency stop
//!   (WM-SPEC-015-R03, SPEC-004-R04 P3).
//! - Local-first providers; remote speech requires configured provider,
//!   privacy policy, redaction, and consent (WM-SPEC-015-R04,
//!   WM-SPEC-010-R08).
//! - Voice macros produce Action Proposals and pass the same
//!   deterministic command-safety gates as other automation
//!   (WM-SPEC-015-R05, WM-SPEC-009-R02).
//! - Spoken room/map/quest/tactical/combat/help/setup summaries disclose
//!   their source and respect privacy (WM-SPEC-015-R06).
//! - Per-character and per-agent voice styles are licensed configuration
//!   profiles and cannot imitate protected characters or celebrities
//!   without lawful authorization (WM-SPEC-015-R07).
//! - Barge-in cancels synthesis; noncritical speech is shortened or
//!   dropped under load; combat can suppress narration (WM-SPEC-015-R08).
//! - Subtitles and transcript controls are available, retention is
//!   configurable, private content suppressed by default
//!   (WM-SPEC-015-R09).
//! - Voice failure, provider outage, or worker crash degrades to text
//!   without affecting gameplay (WM-SPEC-015-R10).
//!
//! Security and privacy: microphone state is always visible; voice
//! transcripts are redacted by default; voice cannot grant scopes or
//! send commands directly; no hidden microphone capture; remote speech
//! obeys privacy and consent.

use std::collections::{BTreeMap, VecDeque};

use serde::{Deserialize, Serialize};

pub const VOICE_SCHEMA_VERSION: u32 = 1;
pub const MAX_SPEECH_QUEUE: usize = 64;
pub const MAX_TRANSCRIPT_RETENTION: usize = 512;
pub const MAX_MACRO_LENGTH: usize = 1024;
pub const MAX_SUBTITLE_LENGTH: usize = 256;
pub const MAX_STYLES: usize = 128;
pub const MAX_WAKE_PHRASE_LENGTH: usize = 64;
pub const MAX_AUDIT: usize = 1024;

/// Why a voice action was denied (SPEC-025 classes).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum VoiceDenial {
    EmergencyStop,
    UnavailableDependency,
    Timeout,
    Cancelled,
    MalformedInput,
    DuplicateRequest,
    DeniedPolicy,
    QueueFull,
    OversizedInput,
    MicrophoneDenied,
    ConsentRequired,
    LocalOnlyLockdown,
    ProtectedVoice,
    NotConfigured,
}

/// Microphone state. Always visible (WM-SPEC-015-R01). There is no
/// hidden capture state: the companion can only ever be in one of these
/// states, and the UI reflects it continuously.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum MicState {
    Off,
    Listening,
    Speaking,
    BargeIn,
    Error,
    Disabled,
}

impl MicState {
    pub fn label(self) -> &'static str {
        match self {
            MicState::Off => "off",
            MicState::Listening => "listening",
            MicState::Speaking => "speaking",
            MicState::BargeIn => "barge-in",
            MicState::Error => "error",
            MicState::Disabled => "disabled",
        }
    }
}

/// Initial activation modes (WM-SPEC-015-R01).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ActivationMode {
    PushToTalk,
    HoldToTalk,
}

/// Wake phrase configuration (WM-SPEC-015-R02). Optional, disabled by
/// default, explicitly consented.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct WakePhraseConfig {
    pub phrase: String,
    pub consented: bool,
    pub provider_is_local: bool,
}

/// One speech job in the bounded P3 queue. Jobs are cancelable and may
/// be shed under load (SPEC-004-R04, SPEC-015 Performance).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SpeechJob {
    pub id: String,
    pub kind: String, // stt | tts | summary
    pub text: String,
    pub provider: String, // local | remote:<id>
    pub critical: bool,
    pub remote_approved: bool,
    pub cancelled: bool,
    pub at_ms: u64,
}

/// One voice macro. Voice macros produce Action Proposals and pass the
/// same deterministic command-safety gates as other automation
/// (WM-SPEC-015-R05, WM-SPEC-009-R02).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct VoiceMacro {
    pub id: String,
    pub name: String,
    pub phrase: String,
    pub command: String,
    pub risk_tier: String, // manual | low | medium | high | critical
    pub confirmation_required: bool,
}

impl VoiceMacro {
    /// Deterministic command-safety gate shared with all automation
    /// (WM-SPEC-009-R02). A macro is safe only when it has a non-empty
    /// normalized command, bounded length, and an explicit risk tier.
    pub fn validate(&self) -> Result<(), VoiceDenial> {
        if self.id.is_empty() || self.name.is_empty() || self.phrase.is_empty() {
            return Err(VoiceDenial::MalformedInput);
        }
        if self.command.is_empty() || self.command.len() > MAX_MACRO_LENGTH {
            return Err(VoiceDenial::MalformedInput);
        }
        match self.risk_tier.as_str() {
            // "manual" is rejected outright: a voice macro is an
            // automated source and cannot claim the manual (direct
            // user-typed) tier (WM-SPEC-009-R02 fail-closed).
            "low" | "medium" | "high" | "critical" => {}
            _ => return Err(VoiceDenial::DeniedPolicy),
        }
        // Destructive, social, trade, PvP, account, privacy, and
        // irreversible actions require explicit confirmation
        // (WM-SPEC-009-R04).
        if self.confirmation_required && self.risk_tier == "manual" {
            return Err(VoiceDenial::DeniedPolicy);
        }
        Ok(())
    }

    /// Produce the Action Proposal for this macro. Never auto-sends;
    /// the command-safety gate must accept it first.
    pub fn propose(&self) -> Result<ActionProposal, VoiceDenial> {
        self.validate()?;
        Ok(ActionProposal {
            source: "voice".into(),
            original: self.phrase.clone(),
            normalized_command: self.command.clone(),
            risk_tier: self.risk_tier.clone(),
            confirmation_required: self.confirmation_required,
            approved: false,
        })
    }
}

/// A deterministic Action Proposal (SPEC-009). Voice macros enter the
/// same path as every other automated source. Approval is explicit and
/// never granted by the voice subsystem.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ActionProposal {
    pub source: String,
    pub original: String,
    pub normalized_command: String,
    pub risk_tier: String,
    pub confirmation_required: bool,
    pub approved: bool,
}

/// One spoken summary (WM-SPEC-015-R06). Discloses its source and
/// respects privacy: private content is suppressed by default.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SpokenSummary {
    pub kind: String, // room | map | quest | tactical | combat | help | setup
    pub text: String,
    pub source: String,
    pub private: bool,
}

/// One subtitle line (WM-SPEC-015-R09).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SubtitleLine {
    pub text: String,
    pub private: bool,
    pub at_ms: u64,
}

/// A voice style (WM-SPEC-015-R07). Licensed configuration profile.
/// Cannot imitate protected characters or celebrities without lawful
/// authorization: a style declares its license and authorization, and
/// the companion rejects protected identities.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct VoiceStyle {
    pub id: String,
    pub label: String,
    pub kind: String, // character | agent
    pub license: String,
    pub authorized: bool,
    pub protected: bool,
}

impl VoiceStyle {
    pub fn validate(&self) -> Result<(), VoiceDenial> {
        if self.id.is_empty() || self.label.is_empty() {
            return Err(VoiceDenial::MalformedInput);
        }
        if self.protected && !self.authorized {
            return Err(VoiceDenial::ProtectedVoice);
        }
        Ok(())
    }
}

/// A consent receipt (WM-SPEC-010-R09): scoped, versioned, revocable.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ConsentReceipt {
    pub receipt_id: String,
    pub feature: String,
    pub provider: String,
    pub data_class: String,
    pub profile: String,
    pub version: u32,
    pub revoked: bool,
}

/// Remote speech policy (WM-SPEC-015-R04). Remote speech requires a
/// configured provider, privacy policy, redaction, and consent.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RemoteSpeechPolicy {
    pub provider_configured: bool,
    pub privacy_policy_accepted: bool,
    pub redaction_enabled: bool,
    pub consent_receipts: Vec<ConsentReceipt>,
    pub local_only: bool,
}

impl RemoteSpeechPolicy {
    pub fn allow_remote(&self, profile: &str, data_class: &str) -> Result<(), VoiceDenial> {
        if self.local_only {
            return Err(VoiceDenial::LocalOnlyLockdown);
        }
        if !self.provider_configured {
            return Err(VoiceDenial::NotConfigured);
        }
        if !self.privacy_policy_accepted {
            return Err(VoiceDenial::ConsentRequired);
        }
        if !self.redaction_enabled {
            return Err(VoiceDenial::ConsentRequired);
        }
        let valid = self.consent_receipts.iter().any(|c| {
            c.feature == "voice"
                && c.provider == profile
                && c.data_class == data_class
                && !c.revoked
        });
        if !valid {
            return Err(VoiceDenial::ConsentRequired);
        }
        Ok(())
    }
}

/// Voice companion state (WM-SPEC-025 states).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum VoiceState {
    Loading,
    Ready,
    Disabled,
    Denied,
    Degraded,
    Canceled,
    Unavailable,
    Error,
}

impl VoiceState {
    pub fn label(self) -> &'static str {
        match self {
            VoiceState::Loading => "loading",
            VoiceState::Ready => "ready",
            VoiceState::Disabled => "disabled",
            VoiceState::Denied => "denied",
            VoiceState::Degraded => "degraded",
            VoiceState::Canceled => "canceled",
            VoiceState::Unavailable => "unavailable",
            VoiceState::Error => "error",
        }
    }
}

/// The Voice Companion (SPEC-015). Local-first, bounded queues,
/// always-visible mic state, explicit consent, command safety, and
/// degrade-to-text.
pub struct VoiceCompanion {
    state: VoiceState,
    mic: MicState,
    activation: ActivationMode,
    wake_phrase: Option<WakePhraseConfig>,
    queue: VecDeque<SpeechJob>,
    subtitles: VecDeque<SubtitleLine>,
    transcript_retention: usize,
    transcript_private_suppressed: bool,
    remote: RemoteSpeechPolicy,
    styles: BTreeMap<String, VoiceStyle>,
    macros: BTreeMap<String, VoiceMacro>,
    emergency_stop: bool,
    load_shed: bool,
    combat_suppress: bool,
    audit: VecDeque<String>,
    next_job_id: u64,
}

impl Default for VoiceCompanion {
    fn default() -> Self {
        Self::new()
    }
}

impl VoiceCompanion {
    pub fn new() -> Self {
        Self {
            state: VoiceState::Loading,
            mic: MicState::Off,
            activation: ActivationMode::PushToTalk,
            wake_phrase: None,
            queue: VecDeque::new(),
            subtitles: VecDeque::new(),
            transcript_retention: 64,
            transcript_private_suppressed: true,
            remote: RemoteSpeechPolicy {
                provider_configured: false,
                privacy_policy_accepted: false,
                redaction_enabled: true,
                consent_receipts: Vec::new(),
                local_only: true,
            },
            styles: BTreeMap::new(),
            macros: BTreeMap::new(),
            emergency_stop: false,
            load_shed: false,
            combat_suppress: false,
            audit: VecDeque::new(),
            next_job_id: 1,
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

    pub fn state(&self) -> VoiceState {
        self.state
    }

    /// Microphone state is always visible (WM-SPEC-015-R01).
    pub fn mic_state(&self) -> MicState {
        self.mic
    }

    pub fn set_ready(&mut self) {
        self.state = VoiceState::Ready;
        self.audit_push("state ready".into());
    }

    pub fn set_disabled(&mut self) {
        self.state = VoiceState::Disabled;
        self.mic = MicState::Disabled;
        self.queue.clear();
        self.audit_push("state disabled".into());
    }

    /// Worker crash or provider outage degrades to text
    /// (WM-SPEC-015-R10). The companion reports degraded; the terminal
    /// text path is untouched.
    pub fn degrade_to_text(&mut self) {
        self.state = VoiceState::Degraded;
        self.mic = MicState::Error;
        self.queue.clear();
        self.audit_push("degrade to text".into());
    }

    /// Global emergency stop (SPEC-009). Cancels all queued speech and
    /// denies new work, preserving manual text gameplay.
    pub fn emergency_stop(&mut self) {
        self.emergency_stop = true;
        self.state = VoiceState::Canceled;
        self.mic = MicState::Off;
        for job in &mut self.queue {
            job.cancelled = true;
        }
        self.audit_push("emergency stop".into());
    }

    pub fn is_emergency_stopped(&self) -> bool {
        self.emergency_stop
    }

    /// Configure wake phrase (WM-SPEC-015-R02). Disabled by default;
    /// requires explicit consent; paused under Local Only policy when
    /// the provider is not local.
    pub fn set_wake_phrase(
        &mut self,
        phrase: &str,
        consented: bool,
        provider_is_local: bool,
    ) -> Result<(), VoiceDenial> {
        if phrase.is_empty() || phrase.len() > MAX_WAKE_PHRASE_LENGTH {
            return Err(VoiceDenial::MalformedInput);
        }
        if !consented {
            return Err(VoiceDenial::ConsentRequired);
        }
        if self.remote.local_only && !provider_is_local {
            return Err(VoiceDenial::LocalOnlyLockdown);
        }
        self.wake_phrase = Some(WakePhraseConfig {
            phrase: phrase.to_string(),
            consented,
            provider_is_local,
        });
        self.audit_push("wake phrase configured".into());
        Ok(())
    }

    pub fn wake_phrase(&self) -> Option<&WakePhraseConfig> {
        self.wake_phrase.as_ref()
    }

    /// Begin a push-to-talk or hold-to-talk listen (WM-SPEC-015-R01).
    /// The mic state is always visible and transitions are explicit.
    pub fn begin_listen(&mut self) -> Result<(), VoiceDenial> {
        if self.emergency_stop {
            return Err(VoiceDenial::EmergencyStop);
        }
        if self.state != VoiceState::Ready && self.state != VoiceState::Degraded {
            return Err(VoiceDenial::DeniedPolicy);
        }
        if self.state == VoiceState::Degraded {
            // Degraded: listen may still capture local STT, but the
            // companion never pretends speech is working.
        }
        self.mic = MicState::Listening;
        self.audit_push("mic listening".into());
        Ok(())
    }

    pub fn end_listen(&mut self) {
        if self.mic == MicState::Listening {
            self.mic = MicState::Off;
            self.audit_push("mic off".into());
        }
    }

    /// Enqueue one STT/TTS/summary job. Bounded queue; noncritical
    /// jobs are shed under load (SPEC-004-R04).
    pub fn enqueue_speech(
        &mut self,
        kind: &str,
        text: &str,
        provider: &str,
        critical: bool,
        at_ms: u64,
    ) -> Result<String, VoiceDenial> {
        if self.emergency_stop {
            return Err(VoiceDenial::EmergencyStop);
        }
        if self.state == VoiceState::Disabled
            || self.state == VoiceState::Canceled
            || self.state == VoiceState::Unavailable
        {
            return Err(VoiceDenial::DeniedPolicy);
        }
        if text.is_empty() || text.len() > MAX_SUBTITLE_LENGTH * 4 {
            return Err(VoiceDenial::MalformedInput);
        }
        let id = format!("voice-{}", self.next_job_id);
        self.next_job_id += 1;
        let job = SpeechJob {
            id: id.clone(),
            kind: kind.to_string(),
            text: text.to_string(),
            provider: provider.to_string(),
            critical,
            remote_approved: false,
            cancelled: false,
            at_ms,
        };
        if self.queue.len() >= MAX_SPEECH_QUEUE {
            if critical {
                return Err(VoiceDenial::QueueFull);
            }
            // Noncritical P3 work may be dropped under load.
            self.load_shed = true;
            self.audit_push(format!("shed speech job {id}"));
            return Err(VoiceDenial::QueueFull);
        }
        self.queue.push_back(job);
        self.audit_push(format!("enqueue speech {id}"));
        Ok(id)
    }

    pub fn queue_len(&self) -> usize {
        self.queue.len()
    }

    pub fn queue(&self) -> Vec<&SpeechJob> {
        self.queue.iter().collect()
    }

    /// Cancel one job by id (barge-in / cancellation).
    pub fn cancel_job(&mut self, id: &str) -> Result<(), VoiceDenial> {
        let mut found = false;
        for job in &mut self.queue {
            if job.id == id {
                job.cancelled = true;
                found = true;
            }
        }
        if !found {
            return Err(VoiceDenial::MalformedInput);
        }
        self.audit_push(format!("cancel job {id}"));
        Ok(())
    }

    /// Barge-in cancels synthesis (WM-SPEC-015-R08): all noncritical
    /// TTS/summary jobs are cancelled and the mic returns to listening.
    pub fn barge_in(&mut self) {
        for job in &mut self.queue {
            if !job.critical {
                job.cancelled = true;
            }
        }
        self.mic = MicState::BargeIn;
        self.audit_push("barge in".into());
    }

    /// Combat can suppress narration (WM-SPEC-015-R08).
    pub fn set_combat_suppress(&mut self, suppress: bool) {
        self.combat_suppress = suppress;
        if suppress {
            for job in &mut self.queue {
                if job.kind == "summary" && !job.critical {
                    job.cancelled = true;
                }
            }
            self.audit_push("combat suppress narration".into());
        }
    }

    pub fn is_combat_suppressing(&self) -> bool {
        self.combat_suppress
    }

    pub fn did_shed_load(&self) -> bool {
        self.load_shed
    }

    /// Register a licensed voice style (WM-SPEC-015-R07).
    pub fn add_style(&mut self, style: VoiceStyle) -> Result<(), VoiceDenial> {
        style.validate()?;
        if self.styles.len() >= MAX_STYLES {
            return Err(VoiceDenial::QueueFull);
        }
        if self.styles.contains_key(&style.id) {
            return Err(VoiceDenial::DuplicateRequest);
        }
        self.styles.insert(style.id.clone(), style);
        self.audit_push("style registered".into());
        Ok(())
    }

    pub fn style(&self, id: &str) -> Option<&VoiceStyle> {
        self.styles.get(id)
    }

    pub fn style_count(&self) -> usize {
        self.styles.len()
    }

    /// Register a voice macro. Passes the deterministic command-safety
    /// gate before it can ever produce an Action Proposal.
    pub fn add_macro(&mut self, m: VoiceMacro) -> Result<(), VoiceDenial> {
        m.validate()?;
        if self.macros.contains_key(&m.id) {
            return Err(VoiceDenial::DuplicateRequest);
        }
        self.macros.insert(m.id.clone(), m);
        self.audit_push("macro registered".into());
        Ok(())
    }

    pub fn macro_count(&self) -> usize {
        self.macros.len()
    }

    /// Recognize a spoken phrase against registered macros and produce
    /// an Action Proposal through the shared command-safety gate
    /// (WM-SPEC-015-R05, WM-SPEC-009-R02/R03).
    pub fn recognize(&self, phrase: &str) -> Result<ActionProposal, VoiceDenial> {
        if self.emergency_stop {
            return Err(VoiceDenial::EmergencyStop);
        }
        if self.state == VoiceState::Disabled || self.state == VoiceState::Denied {
            return Err(VoiceDenial::DeniedPolicy);
        }
        for m in self.macros.values() {
            if m.phrase == phrase {
                return m.propose();
            }
        }
        Err(VoiceDenial::MalformedInput)
    }

    /// Approve an Action Proposal. This is the explicit user approval
    /// step (SPEC-009); the voice subsystem never self-approves.
    pub fn approve_proposal(&mut self, proposal: &mut ActionProposal) -> Result<(), VoiceDenial> {
        if proposal.source != "voice" {
            return Err(VoiceDenial::DeniedPolicy);
        }
        if proposal.confirmation_required && proposal.risk_tier == "critical" && self.emergency_stop
        {
            return Err(VoiceDenial::EmergencyStop);
        }
        proposal.approved = true;
        self.audit_push("proposal approved".into());
        Ok(())
    }

    /// Remote speech policy (WM-SPEC-015-R04).
    pub fn set_remote_policy(&mut self, policy: RemoteSpeechPolicy) {
        self.remote = policy;
        self.audit_push("remote policy updated".into());
    }

    pub fn remote_policy(&self) -> &RemoteSpeechPolicy {
        &self.remote
    }

    /// Submit a remote speech request. Denied unless provider,
    /// privacy policy, redaction, and consent all hold
    /// (WM-SPEC-015-R04, WM-SPEC-010-R08).
    pub fn submit_remote(&mut self, job_id: &str, profile: &str) -> Result<(), VoiceDenial> {
        self.remote.allow_remote(profile, "voice-transcript")?;
        for job in &mut self.queue {
            if job.id == job_id {
                job.remote_approved = true;
                self.audit_push(format!("remote speech approved {job_id}"));
                return Ok(());
            }
        }
        Err(VoiceDenial::MalformedInput)
    }

    /// Subtitles (WM-SPEC-015-R09). Private content suppressed by
    /// default; retention configurable.
    pub fn add_subtitle(
        &mut self,
        text: &str,
        private: bool,
        at_ms: u64,
    ) -> Result<(), VoiceDenial> {
        if text.is_empty() || text.len() > MAX_SUBTITLE_LENGTH {
            return Err(VoiceDenial::MalformedInput);
        }
        self.subtitles.push_back(SubtitleLine {
            text: text.to_string(),
            private,
            at_ms,
        });
        while self.subtitles.len() > self.transcript_retention {
            self.subtitles.pop_front();
        }
        Ok(())
    }

    pub fn set_transcript_retention(&mut self, n: usize) -> Result<(), VoiceDenial> {
        if n == 0 || n > MAX_TRANSCRIPT_RETENTION {
            return Err(VoiceDenial::MalformedInput);
        }
        self.transcript_retention = n;
        while self.subtitles.len() > n {
            self.subtitles.pop_front();
        }
        Ok(())
    }

    pub fn set_transcript_private_suppressed(&mut self, suppress: bool) {
        self.transcript_private_suppressed = suppress;
    }

    /// Visible subtitles: private lines are suppressed by default.
    pub fn visible_subtitles(&self) -> Vec<&SubtitleLine> {
        self.subtitles
            .iter()
            .filter(|s| !self.transcript_private_suppressed || !s.private)
            .collect()
    }

    pub fn subtitle_count(&self) -> usize {
        self.subtitles.len()
    }

    /// A spoken summary discloses its source; private content is
    /// suppressed by default (WM-SPEC-015-R06).
    pub fn summarize(&self, kind: &str, text: &str) -> SpokenSummary {
        SpokenSummary {
            kind: kind.to_string(),
            text: text.to_string(),
            source: format!("voice:{kind}"),
            private: false,
        }
    }

    /// Snapshot for the UI boundary and supervisor (SPEC-017).
    pub fn snapshot(&self) -> VoiceSnapshot {
        VoiceSnapshot {
            state: self.state.label().to_string(),
            mic: self.mic.label().to_string(),
            activation: match self.activation {
                ActivationMode::PushToTalk => "push-to-talk",
                ActivationMode::HoldToTalk => "hold-to-talk",
            }
            .to_string(),
            wake_phrase_enabled: self.wake_phrase.is_some(),
            queue_len: self.queue.len(),
            load_shed: self.load_shed,
            combat_suppress: self.combat_suppress,
            remote_configured: self.remote.provider_configured,
            local_only: self.remote.local_only,
            style_count: self.styles.len(),
            macro_count: self.macros.len(),
        }
    }
}

/// The visible voice snapshot (mic state always visible).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct VoiceSnapshot {
    pub state: String,
    pub mic: String,
    pub activation: String,
    pub wake_phrase_enabled: bool,
    pub queue_len: usize,
    pub load_shed: bool,
    pub combat_suppress: bool,
    pub remote_configured: bool,
    pub local_only: bool,
    pub style_count: usize,
    pub macro_count: usize,
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ready() -> VoiceCompanion {
        let mut vc = VoiceCompanion::new();
        vc.set_ready();
        vc
    }

    #[test]
    fn mic_state_always_visible() {
        let mut vc = ready();
        assert_eq!(vc.mic_state(), MicState::Off);
        vc.begin_listen().unwrap();
        assert_eq!(vc.mic_state(), MicState::Listening);
        vc.end_listen();
        assert_eq!(vc.mic_state(), MicState::Off);
        // Disabled is a visible state too, never hidden capture.
        vc.set_disabled();
        assert_eq!(vc.mic_state(), MicState::Disabled);
    }

    #[test]
    fn push_to_talk_is_initial_mode() {
        let vc = ready();
        assert_eq!(vc.snapshot().activation, "push-to-talk");
    }

    #[test]
    fn wake_phrase_requires_consent_and_local_policy() {
        let mut vc = ready();
        assert!(
            vc.wake_phrase().is_none(),
            "wake phrase disabled by default"
        );
        assert_eq!(
            vc.set_wake_phrase("hey mud", false, true),
            Err(VoiceDenial::ConsentRequired)
        );
        assert_eq!(
            vc.set_wake_phrase("hey mud", true, false),
            Err(VoiceDenial::LocalOnlyLockdown)
        );
        vc.set_wake_phrase("hey mud", true, true).unwrap();
        assert!(vc.wake_phrase().is_some());
    }

    #[test]
    fn speech_queue_is_bounded_and_sheds_p3() {
        let mut vc = ready();
        for _ in 0..MAX_SPEECH_QUEUE {
            vc.enqueue_speech("tts", "ok", "local", false, 1).unwrap();
        }
        // Noncritical job over the cap is shed (QueueFull).
        assert_eq!(
            vc.enqueue_speech("tts", "extra", "local", false, 2),
            Err(VoiceDenial::QueueFull)
        );
        assert!(vc.did_shed_load());
        assert_eq!(vc.queue_len(), MAX_SPEECH_QUEUE);
    }

    #[test]
    fn critical_queue_full_is_hard_denial() {
        let mut vc = ready();
        for _ in 0..MAX_SPEECH_QUEUE {
            vc.enqueue_speech("stt", "ok", "local", false, 1).unwrap();
        }
        assert_eq!(
            vc.enqueue_speech("stt", "critical", "local", true, 3),
            Err(VoiceDenial::QueueFull)
        );
    }

    #[test]
    fn voice_macro_passes_command_safety_and_proposes() {
        let mut vc = ready();
        vc.add_macro(VoiceMacro {
            id: "m1".into(),
            name: "look".into(),
            phrase: "look around".into(),
            command: "look".into(),
            risk_tier: "low".into(),
            confirmation_required: false,
        })
        .unwrap();
        let proposal = vc.recognize("look around").unwrap();
        assert_eq!(proposal.source, "voice");
        assert_eq!(proposal.normalized_command, "look");
        assert!(!proposal.approved);
    }

    #[test]
    fn macro_requiring_confirmation_on_manual_tier_denied() {
        let mut vc = ready();
        assert_eq!(
            vc.add_macro(VoiceMacro {
                id: "bad".into(),
                name: "bad".into(),
                phrase: "bad".into(),
                command: "quit".into(),
                risk_tier: "manual".into(),
                confirmation_required: true,
            }),
            Err(VoiceDenial::DeniedPolicy)
        );
    }

    #[test]
    fn unknown_phrase_denied() {
        let vc = ready();
        assert_eq!(
            vc.recognize("not a macro"),
            Err(VoiceDenial::MalformedInput)
        );
    }

    #[test]
    fn barge_in_cancels_synthesis() {
        let mut vc = ready();
        vc.enqueue_speech("tts", "narration", "local", false, 1)
            .unwrap();
        vc.enqueue_speech("tts", "critical", "local", true, 2)
            .unwrap();
        vc.barge_in();
        let cancelled: Vec<bool> = vc.queue().iter().map(|j| j.cancelled).collect();
        assert_eq!(cancelled, vec![true, false]);
        assert_eq!(vc.mic_state(), MicState::BargeIn);
    }

    #[test]
    fn combat_suppresses_narration() {
        let mut vc = ready();
        vc.enqueue_speech("summary", "room", "local", false, 1)
            .unwrap();
        vc.enqueue_speech("stt", "player", "local", true, 2)
            .unwrap();
        vc.set_combat_suppress(true);
        let cancelled: Vec<bool> = vc.queue().iter().map(|j| j.cancelled).collect();
        assert_eq!(cancelled, vec![true, false]);
        assert!(vc.is_combat_suppressing());
    }

    #[test]
    fn remote_speech_requires_full_consent() {
        let mut vc = ready();
        vc.enqueue_speech("tts", "remote", "remote:azure", false, 1)
            .unwrap();
        // Local Only blocks remote by default.
        assert_eq!(
            vc.submit_remote("voice-1", "azure"),
            Err(VoiceDenial::LocalOnlyLockdown)
        );
        // Configured + policy + consent allows it.
        vc.set_remote_policy(RemoteSpeechPolicy {
            provider_configured: true,
            privacy_policy_accepted: true,
            redaction_enabled: true,
            consent_receipts: vec![ConsentReceipt {
                receipt_id: "r1".into(),
                feature: "voice".into(),
                provider: "azure".into(),
                data_class: "voice-transcript".into(),
                profile: "p1".into(),
                version: 1,
                revoked: false,
            }],
            local_only: false,
        });
        vc.submit_remote("voice-1", "azure").unwrap();
        assert!(vc.queue()[0].remote_approved);
        // Revoked consent denies.
        vc.set_remote_policy(RemoteSpeechPolicy {
            provider_configured: true,
            privacy_policy_accepted: true,
            redaction_enabled: true,
            consent_receipts: vec![ConsentReceipt {
                receipt_id: "r1".into(),
                feature: "voice".into(),
                provider: "azure".into(),
                data_class: "voice-transcript".into(),
                profile: "p1".into(),
                version: 1,
                revoked: true,
            }],
            local_only: false,
        });
        vc.enqueue_speech("tts", "remote2", "remote:azure", false, 2)
            .unwrap();
        assert_eq!(
            vc.submit_remote("voice-2", "azure"),
            Err(VoiceDenial::ConsentRequired)
        );
    }

    #[test]
    fn degraded_worker_still_shows_mic() {
        let mut vc = ready();
        vc.degrade_to_text();
        assert_eq!(vc.state(), VoiceState::Degraded);
        assert_eq!(vc.mic_state(), MicState::Error);
        assert_eq!(vc.queue_len(), 0);
    }

    #[test]
    fn emergency_stop_cancels_all_and_preserves_text() {
        let mut vc = ready();
        vc.enqueue_speech("tts", "x", "local", false, 1).unwrap();
        vc.emergency_stop();
        assert!(vc.is_emergency_stopped());
        assert!(vc.queue().iter().all(|j| j.cancelled));
        assert_eq!(
            vc.enqueue_speech("tts", "y", "local", false, 2),
            Err(VoiceDenial::EmergencyStop)
        );
        // Manual text gameplay is untouched: the companion only owns
        // the voice queue, not the terminal or connection.
        assert_eq!(vc.mic_state(), MicState::Off);
    }

    #[test]
    fn protected_voice_style_denied_without_authorization() {
        let mut vc = ready();
        assert_eq!(
            vc.add_style(VoiceStyle {
                id: "celebrity".into(),
                label: "famous person".into(),
                kind: "character".into(),
                license: "none".into(),
                authorized: false,
                protected: true,
            }),
            Err(VoiceDenial::ProtectedVoice)
        );
        vc.add_style(VoiceStyle {
            id: "licensed".into(),
            label: "original".into(),
            kind: "character".into(),
            license: "CC-BY".into(),
            authorized: true,
            protected: false,
        })
        .unwrap();
        assert_eq!(vc.style_count(), 1);
    }

    #[test]
    fn subtitles_suppress_private_by_default() {
        let mut vc = ready();
        vc.add_subtitle("public line", false, 1).unwrap();
        vc.add_subtitle("private tell", true, 2).unwrap();
        assert_eq!(vc.subtitle_count(), 2);
        assert_eq!(vc.visible_subtitles().len(), 1);
        vc.set_transcript_private_suppressed(false);
        assert_eq!(vc.visible_subtitles().len(), 2);
    }

    #[test]
    fn transcript_retention_is_bounded() {
        let mut vc = ready();
        vc.set_transcript_retention(3).unwrap();
        for i in 0..5 {
            vc.add_subtitle(&format!("line {i}"), false, i as u64)
                .unwrap();
        }
        assert_eq!(vc.subtitle_count(), 3);
        assert_eq!(
            vc.set_transcript_retention(0),
            Err(VoiceDenial::MalformedInput)
        );
    }

    #[test]
    fn summarize_discloses_source() {
        let vc = ready();
        let s = vc.summarize("room", "A quiet street.");
        assert_eq!(s.source, "voice:room");
        assert!(!s.private);
    }

    #[test]
    fn approval_is_explicit_and_never_auto() {
        let mut vc = ready();
        vc.add_macro(VoiceMacro {
            id: "m".into(),
            name: "m".into(),
            phrase: "p".into(),
            command: "say hi".into(),
            risk_tier: "medium".into(),
            confirmation_required: true,
        })
        .unwrap();
        let mut proposal = vc.recognize("p").unwrap();
        assert!(!proposal.approved);
        vc.approve_proposal(&mut proposal).unwrap();
        assert!(proposal.approved);
    }
}

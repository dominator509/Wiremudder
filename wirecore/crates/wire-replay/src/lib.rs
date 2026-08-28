//! WireMudder deterministic session replay, diagnostic bundles, and
//! sanitized fixtures (SPEC-019, SPEC-024, SPEC-026; EP-028).
//!
//! Owned surfaces:
//! - Session Replay records deterministic sanitized events and preserves
//!   version information needed for reproduction (WM-SPEC-019-R04).
//! - Sanitized fixture generation strips secrets, player names, private
//!   messages, routing credentials, full prompts, and voice transcripts
//!   unless the user specifically approves inclusion (WM-SPEC-019-R05).
//! - Crash and diagnostic bundles are local, redacted, previewable,
//!   content-addressed, and never submitted without explicit user action
//!   or opt-in policy (WM-SPEC-019-R03).
//! - Restart resynchronizes snapshots rather than replaying unbounded raw
//!   history (WM-SPEC-024-R09).
//! - Support bundles are previewable, redacted, reproducible, and
//!   content-addressed (WM-SPEC-026-R07).
//! - No hosted telemetry, crash reporting, or analytics endpoint is
//!   required for core operation (WM-SPEC-026-R08).
//!
//! Security: replay and fixtures are deterministic and sanitized; bundles
//! require explicit user approval before any submission; no remote
//! egress, no new authority, and no secret access is implied.

use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

pub const REPLAY_SCHEMA_VERSION: u32 = 1;
pub const BUNDLE_SCHEMA_VERSION: u32 = 1;
pub const MAX_REPLAY_EVENTS: usize = 65536;
pub const MAX_FIXTURE_EVENTS: usize = 4096;
/// WM-SPEC-019-R05: voice transcripts are stripped unless approved.
pub const STRIPPED_FIXTURE_KINDS: &[&str] = &["voice", "transcript"];

/// Deterministic sanitized replay event (SPEC-019-R04). The event
/// carries only sanitized text; secrets never enter the record.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ReplayEvent {
    pub seq: u64,
    pub t: i64,
    pub kind: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub line: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub command: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub direction: Option<String>,
    #[serde(default, skip_serializing_if = "serde_json::Map::is_empty")]
    pub details: serde_json::Map<String, serde_json::Value>,
}

impl ReplayEvent {
    pub fn line(seq: u64, t: i64, line: &str) -> Self {
        ReplayEvent {
            seq,
            t,
            kind: "line".to_string(),
            line: Some(line.to_string()),
            command: None,
            direction: Some("in".to_string()),
            details: serde_json::Map::new(),
        }
    }

    pub fn command(seq: u64, t: i64, command: &str) -> Self {
        ReplayEvent {
            seq,
            t,
            kind: "command".to_string(),
            line: None,
            command: Some(command.to_string()),
            direction: Some("out".to_string()),
            details: serde_json::Map::new(),
        }
    }

    pub fn kind_event(seq: u64, t: i64, kind: &str) -> Self {
        ReplayEvent {
            seq,
            t,
            kind: kind.to_string(),
            line: None,
            command: None,
            direction: None,
            details: serde_json::Map::new(),
        }
    }
}

/// Deterministic sanitized session replay record (SPEC-019-R04).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SessionReplay {
    pub schema_version: u32,
    pub session_id: String,
    pub client_version: ClientVersion,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub profile: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub world: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub started_at: Option<String>,
    pub events: Vec<ReplayEvent>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ClientVersion {
    pub app: String,
    pub git_sha: String,
}

impl SessionReplay {
    pub fn new(session_id: &str, app: &str, git_sha: &str) -> Result<Self, ReplayError> {
        if session_id.len() < 8 {
            return Err(ReplayError::invalid(
                "replay-session-id",
                "session id must be at least 8 characters",
            ));
        }
        if git_sha.len() != 40 {
            return Err(ReplayError::invalid(
                "replay-git-sha",
                "git sha must be 40 hex characters",
            ));
        }
        Ok(SessionReplay {
            schema_version: REPLAY_SCHEMA_VERSION,
            session_id: session_id.to_string(),
            client_version: ClientVersion {
                app: app.to_string(),
                git_sha: git_sha.to_string(),
            },
            profile: None,
            world: None,
            started_at: None,
            events: Vec::new(),
        })
    }

    pub fn push(&mut self, event: ReplayEvent) -> Result<(), ReplayError> {
        if self.events.len() >= MAX_REPLAY_EVENTS {
            return Err(ReplayError::resource(
                "replay-capacity",
                "replay event limit reached",
            ));
        }
        self.events.push(event);
        Ok(())
    }

    /// Deterministic replay: events are emitted in strict `seq` order.
    /// The sequence is assigned at capture time, so a re-serialized
    /// record replays identically (WM-SPEC-019-R04).
    pub fn replay_events(&self) -> Vec<&ReplayEvent> {
        let mut events: Vec<&ReplayEvent> = self.events.iter().collect();
        events.sort_by_key(|e| e.seq);
        events
    }

    /// Content hash over the canonical serialized record.
    pub fn content_hash(&self) -> String {
        let canonical = serde_json::to_vec(self).unwrap_or_default();
        hex(&Sha256::digest(&canonical))
    }
}

/// Diagnostic bundle manifest (SPEC-019-R03, SPEC-026-R07): local,
/// redacted, previewable, content-addressed. `approved_for_submission`
/// is always false until the user explicitly approves.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct DiagnosticBundle {
    pub schema_version: u32,
    pub bundle_id: String,
    pub content_sha256: String,
    pub created_at: String,
    pub event_count: usize,
    pub bytes: usize,
    pub preview: String,
    pub approved_for_submission: bool,
    #[serde(default, skip_serializing_if = "BTreeMap::is_empty")]
    pub files: BTreeMap<String, String>,
}

impl DiagnosticBundle {
    pub fn preview(&self) -> &str {
        &self.preview
    }

    pub fn content_hash(&self) -> &str {
        &self.content_sha256
    }

    /// Mark the bundle approved for submission. This is the only way to
    /// flip the flag; it models explicit user action (SPEC-019-R03).
    pub fn approve(&mut self) {
        self.approved_for_submission = true;
    }

    pub fn is_approved(&self) -> bool {
        self.approved_for_submission
    }
}

/// Bundle builder: collects replay events into a redacted, previewable,
/// content-addressed diagnostic bundle (WM-SPEC-019-R03, WM-FEAT-0132).
#[derive(Debug, Clone)]
pub struct BundleBuilder {
    redactor: Redactor,
}

impl Default for BundleBuilder {
    fn default() -> Self {
        BundleBuilder {
            redactor: Redactor::default(),
        }
    }
}

impl BundleBuilder {
    pub fn new(redactor: Redactor) -> Self {
        BundleBuilder { redactor }
    }

    /// Build a bundle from a session replay. The preview is the first
    /// `preview_lines` redacted event lines; the content hash covers the
    /// full redacted serialized record. Preview and export therefore
    /// match (acceptance obligation 5).
    pub fn build(
        &self,
        replay: &SessionReplay,
        bundle_id: &str,
        preview_lines: usize,
    ) -> Result<DiagnosticBundle, ReplayError> {
        if bundle_id.len() < 8 {
            return Err(ReplayError::invalid(
                "bundle-id",
                "bundle id must be at least 8 characters",
            ));
        }
        let canonical = self.redacted_serialize(replay)?;
        let content_sha256 = hex(&Sha256::digest(&canonical));
        let mut preview = String::new();
        for event in replay.replay_events().iter().take(preview_lines) {
            let text = match (&event.line, &event.command) {
                (Some(l), _) => self.redactor.redact_text(l),
                (None, Some(c)) => format!("> {}", self.redactor.redact_text(c)),
                _ => format!("<{}>", event.kind),
            };
            preview.push_str(&format!("[{}] {}\n", event.seq, text));
        }
        Ok(DiagnosticBundle {
            schema_version: BUNDLE_SCHEMA_VERSION,
            bundle_id: bundle_id.to_string(),
            content_sha256,
            created_at: now_iso8601(),
            event_count: replay.events.len(),
            bytes: canonical.len(),
            preview,
            approved_for_submission: false,
            files: BTreeMap::new(),
        })
    }

    /// The exported content that would be written for this bundle. It is
    /// exactly the canonical serialized record, so preview derives from
    /// the same bytes that export writes (acceptance obligation 5).
    pub fn export_bytes(&self, replay: &SessionReplay) -> Result<Vec<u8>, ReplayError> {
        self.redacted_serialize(replay)
    }

    fn redacted_serialize(&self, replay: &SessionReplay) -> Result<Vec<u8>, ReplayError> {
        let mut clone = replay.clone();
        for event in &mut clone.events {
            if let Some(line) = &mut event.line {
                *line = self.redactor.redact_text(line);
            }
            if let Some(command) = &mut event.command {
                *command = self.redactor.redact_text(command);
            }
        }
        serde_json::to_vec(&clone).map_err(|e| {
            ReplayError::invalid(
                "bundle-serialize",
                &format!("unable to serialize bundle: {e}"),
            )
        })
    }
}

/// Redaction corpus for replay/bundle text (SPEC-019-R05). Same markers
/// as the telemetry boundary plus player-name and private-message
/// markers; always strips secrets, routing credentials, full prompts,
/// and voice transcripts unless approved.
#[derive(Debug, Clone)]
pub struct Redactor {
    corpus: Vec<String>,
}

impl Default for Redactor {
    fn default() -> Self {
        Redactor {
            corpus: [
                "password",
                "passwd",
                "secret",
                "token",
                "api_key",
                "apikey",
                "auth",
                "credential",
                "cookie",
                "session_key",
                "private_key",
                "access_key",
                "player",
                "whisper",
                "tell",
                "prompt",
            ]
            .iter()
            .map(|s| s.to_string())
            .collect(),
        }
    }
}

impl Redactor {
    pub fn new(corpus: Vec<String>) -> Self {
        Redactor { corpus }
    }

    pub fn contains_marker(&self, text: &str) -> bool {
        let lower = text.to_ascii_lowercase();
        self.corpus.iter().any(|m| lower.contains(m))
    }

    pub fn redact_text(&self, text: &str) -> String {
        let lower = text.to_ascii_lowercase();
        let bytes = text.as_bytes();
        let mut out = String::with_capacity(text.len());
        let mut pos = 0usize;
        while pos < bytes.len() {
            let mut best: Option<(usize, usize)> = None;
            for marker in &self.corpus {
                let m_lower = marker.to_ascii_lowercase();
                if let Some(rel) = lower[pos..].find(&m_lower) {
                    let abs = pos + rel;
                    if best.map_or(true, |(b, _)| abs < b) {
                        best = Some((abs, marker.len()));
                    }
                }
            }
            match best {
                Some((m_idx, m_len)) => {
                    out.push_str(&text[pos..m_idx]);
                    let mut end = m_idx + m_len;
                    while end < bytes.len() && matches!(bytes[end], b'=' | b':' | b' ') {
                        end += 1;
                    }
                    while end < bytes.len()
                        && !matches!(
                            bytes[end],
                            b' ' | b'\t' | b'\n' | b'\r' | b',' | b'&' | b';' | b'"' | b'\''
                        )
                    {
                        end += 1;
                    }
                    out.push_str("[REDACTED]");
                    pos = end;
                }
                None => {
                    out.push_str(&text[pos..]);
                    pos = bytes.len();
                }
            }
        }
        out
    }
}

/// Sanitized fixture generator (WM-FEAT-0128, WM-SPEC-019-R05). Strips
/// secrets, player names, private messages, routing credentials, full
/// prompts, and voice transcripts. Optional inclusion only when the
/// user specifically approves that classification.
#[derive(Debug, Clone)]
pub struct FixtureGenerator {
    redactor: Redactor,
}

impl Default for FixtureGenerator {
    fn default() -> Self {
        FixtureGenerator {
            redactor: Redactor::default(),
        }
    }
}

impl FixtureGenerator {
    pub fn new(redactor: Redactor) -> Self {
        FixtureGenerator { redactor }
    }

    /// Add known player names to the redaction corpus so sanitized
    /// fixtures strip actual player names (WM-SPEC-019-R05), not just
    /// the generic marker word. The caller supplies the player names it
    /// knows from profile/world scope.
    pub fn with_player_names(mut self, player_names: &[&str]) -> Self {
        for name in player_names {
            if !name.is_empty() {
                self.redactor.corpus.push(name.to_string());
            }
        }
        self
    }

    /// Generate a sanitized fixture replay. Kinds in `stripped_kinds`
    /// (voice, transcript) are dropped entirely unless `approved_kinds`
    /// contains them; all text is redacted.
    pub fn generate(
        &self,
        source: &SessionReplay,
        approved_kinds: &[&str],
    ) -> Result<SessionReplay, ReplayError> {
        let mut fixture = source.clone();
        fixture.events.clear();
        for event in source.replay_events() {
            if STRIPPED_FIXTURE_KINDS.contains(&event.kind.as_str())
                && !approved_kinds.contains(&event.kind.as_str())
            {
                continue;
            }
            let mut e = event.clone();
            if let Some(line) = &mut e.line {
                *line = self.redactor.redact_text(line);
            }
            if let Some(command) = &mut e.command {
                *command = self.redactor.redact_text(command);
            }
            fixture.events.push(e);
            if fixture.events.len() >= MAX_FIXTURE_EVENTS {
                break;
            }
        }
        Ok(fixture)
    }

    /// Diagnostic deduplication without private content (WM-FEAT-0227):
    /// the dedup key hashes only structural fields and redacted text.
    pub fn dedup_key(event: &ReplayEvent) -> String {
        let mut h = Sha256::new();
        h.update(event.kind.as_bytes());
        h.update([0u8]);
        if let Some(line) = &event.line {
            let red = Redactor::default();
            h.update(red.redact_text(line).as_bytes());
        }
        hex(&h.finalize())[..16].to_string()
    }

    /// Count unique structural events in a replay (dedup without
    /// private content).
    pub fn unique_event_count(replay: &SessionReplay) -> usize {
        let mut seen = std::collections::BTreeSet::new();
        for event in &replay.events {
            seen.insert(Self::dedup_key(event));
        }
        seen.len()
    }
}

/// Stable public error type (SPEC-025-R02).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ReplayError {
    pub code: String,
    pub message: String,
    pub correlation_id: String,
    pub retry_class: String,
    pub user_action: String,
    pub diagnostic_ref: String,
    pub internal_cause: String,
}

impl ReplayError {
    pub fn invalid(code: &str, message: &str) -> Self {
        ReplayError {
            code: code.to_string(),
            message: message.to_string(),
            correlation_id: format!("rep-{:016x}", rand_u64()),
            retry_class: "validation".to_string(),
            user_action: "Check the reported value and retry.".to_string(),
            diagnostic_ref: "diagnostics/replay/errors.md".to_string(),
            internal_cause: "[REDACTED]".to_string(),
        }
    }

    pub fn resource(code: &str, message: &str) -> Self {
        ReplayError {
            code: code.to_string(),
            message: message.to_string(),
            correlation_id: format!("rep-{:016x}", rand_u64()),
            retry_class: "resource-exhausted".to_string(),
            user_action: "Reduce the event volume or start a new session.".to_string(),
            diagnostic_ref: "diagnostics/replay/errors.md".to_string(),
            internal_cause: "[REDACTED]".to_string(),
        }
    }
}

fn hex(bytes: &[u8]) -> String {
    let mut s = String::with_capacity(bytes.len() * 2);
    for b in bytes {
        s.push_str(&format!("{b:02x}"));
    }
    s
}

fn now_iso8601() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    let days = (secs / 86_400) as i64;
    let rem = secs % 86_400;
    let (h, _m, s) = (rem / 3600, (rem % 3600) / 60, rem % 60);
    // civil_from_days (Howard Hinnant's algorithm)
    let z = days + 719_468;
    let era = if z >= 0 { z } else { z - 146_096 } / 146_097;
    let doe = (z - era * 146_097) as u64;
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146_096) / 365;
    let y = yoe as i64 + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = (doy - (153 * mp + 2) / 5 + 1) as u64;
    let m = if mp < 10 { mp + 3 } else { mp - 9 } as u64;
    let y = if m <= 2 { y + 1 } else { y };
    format!(
        "{:04}-{:02}-{:02}T{:02}:{:02}:{:02}+00:00",
        y, m, d, h, m, s
    )
}

fn rand_u64() -> u64 {
    use std::time::{SystemTime, UNIX_EPOCH};
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);
    (nanos as u64) ^ (nanos >> 32) as u64
}

#[cfg(test)]
mod tests {
    use super::*;

    fn git_sha() -> String {
        "a".repeat(40)
    }

    fn sample_replay() -> SessionReplay {
        let mut r = SessionReplay::new("session-0001", "wiremudder", &git_sha()).unwrap();
        r.push(ReplayEvent::line(1, 0, "You arrive at the market."))
            .unwrap();
        r.push(ReplayEvent::line(2, 10, "password=hunter2 is your token"))
            .unwrap();
        r.push(ReplayEvent::command(3, 20, "look")).unwrap();
        r.push(ReplayEvent::kind_event(4, 30, "voice")).unwrap();
        r
    }

    #[test]
    fn replay_is_deterministic() {
        let r = sample_replay();
        let a = serde_json::to_vec(&r).unwrap();
        let b = serde_json::to_vec(&r).unwrap();
        assert_eq!(a, b);
        let order: Vec<u64> = r.replay_events().iter().map(|e| e.seq).collect();
        assert_eq!(order, vec![1, 2, 3, 4]);
        assert_eq!(r.content_hash(), r.content_hash());
        assert_eq!(r.content_hash().len(), 64);
    }

    #[test]
    fn bundle_preview_matches_export() {
        let r = sample_replay();
        let builder = BundleBuilder::default();
        let bundle = builder.build(&r, "bundle-0001", 3).unwrap();
        assert!(!bundle.is_approved());
        assert!(bundle.preview().contains("[1]"));
        assert!(bundle.preview().contains("[2]"));
        // The preview shows the redacted line, not the raw secret.
        assert!(!bundle.preview().contains("hunter2"));
        assert!(bundle.preview().contains("[REDACTED]"));
        // Export bytes hash to the content address.
        let export = builder.export_bytes(&r).unwrap();
        assert_eq!(hex(&Sha256::digest(&export)), bundle.content_hash());
        assert_eq!(bundle.bytes, export.len());
    }

    #[test]
    fn bundle_requires_explicit_approval() {
        let r = sample_replay();
        let builder = BundleBuilder::default();
        let mut bundle = builder.build(&r, "bundle-0002", 2).unwrap();
        assert!(!bundle.approved_for_submission);
        bundle.approve();
        assert!(bundle.is_approved());
    }

    #[test]
    fn fixture_strips_secrets_and_voice() {
        let r = sample_replay();
        let gen = FixtureGenerator::default();
        let fixture = gen.generate(&r, &[]).unwrap();
        assert_eq!(fixture.events.len(), 3); // voice dropped
        let joined: Vec<String> = fixture
            .events
            .iter()
            .map(|e| e.line.clone().unwrap_or_default())
            .collect();
        let all = joined.join(" ");
        assert!(!all.contains("hunter2"));
        assert!(all.contains("[REDACTED]"));
        assert!(!fixture.events.iter().any(|e| e.kind == "voice"));
    }

    #[test]
    fn fixture_can_approve_voice() {
        let r = sample_replay();
        let gen = FixtureGenerator::default();
        let fixture = gen.generate(&r, &["voice"]).unwrap();
        assert!(fixture.events.iter().any(|e| e.kind == "voice"));
    }

    #[test]
    fn dedup_key_ignores_private_content() {
        let mut r = sample_replay();
        r.events[0].line = Some("You arrive at the market.".to_string());
        let e1 = r.events[0].clone();
        r.events[0].line = Some("You arrive at the market.".to_string());
        // Two structurally identical lines give one dedup key.
        let mut r2 = SessionReplay::new("session-0002", "wiremudder", &git_sha()).unwrap();
        r2.push(ReplayEvent::line(1, 0, "You arrive at the market."))
            .unwrap();
        r2.push(ReplayEvent::line(2, 1, "You arrive at the market."))
            .unwrap();
        assert_eq!(FixtureGenerator::unique_event_count(&r2), 1);
        let _ = e1;
    }

    #[test]
    fn replay_errors_are_stable() {
        let err = ReplayError::invalid("replay-session-id", "too short");
        assert_eq!(err.code, "replay-session-id");
        assert_eq!(err.retry_class, "validation");
        assert_eq!(err.internal_cause, "[REDACTED]");
        assert!(
            ReplayError::resource("replay-capacity", "full").retry_class == "resource-exhausted"
        );
    }

    #[test]
    fn session_replay_validates_inputs() {
        assert!(SessionReplay::new("short", "wiremudder", &git_sha()).is_err());
        assert!(SessionReplay::new("session-0001", "wiremudder", "bad").is_err());
    }
}

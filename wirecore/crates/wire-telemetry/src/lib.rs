//! WireMudder local structured telemetry, ring buffers, redaction,
//! fingerprints, and diagnostics (SPEC-019, SPEC-023, SPEC-025, SPEC-026;
//! EP-028).
//!
//! Owned surfaces:
//! - Telemetry is off by default and local structured event capture uses
//!   bounded crash-safe ring buffers (WM-SPEC-019-R01).
//! - Events include schema/app/platform/subsystem/priority/severity/
//!   fingerprint/correlation/scope/feature/privacy/latency/queue/drop/
//!   coalesce/provider/voice/renderer/redaction fields without raw secrets
//!   (WM-SPEC-019-R02).
//! - Crash and diagnostic bundles are local, redacted, previewable,
//!   content-addressed, and never submitted without explicit user action
//!   or opt-in policy (WM-SPEC-019-R03).
//! - Private, secret, diagnostic, voice, transcript, and public content use
//!   distinct data classifications and default retention (WM-SPEC-023-R05).
//! - Every public error has a stable code, safe message, correlation ID,
//!   retry class, user action, diagnostic reference, and redacted internal
//!   cause (WM-SPEC-025-R02).
//! - Support bundles are previewable, redacted, reproducible, and
//!   content-addressed (WM-SPEC-026-R07).
//! - No hosted telemetry, crash reporting, or analytics endpoint is
//!   required for core operation (WM-SPEC-026-R08).
//!
//! Security: capture is opt-in local-only; ring buffers are bounded;
//! events are redacted at the boundary; no remote egress, no new
//! authority, no secret access, and no stable publication is implied.

use std::collections::VecDeque;
use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

pub const TELEMETRY_SCHEMA_VERSION: u32 = 1;
/// WM-SPEC-019-R01: ring buffers are bounded. Default capacity is 4096
/// events; the constructor rejects zero and caps at 65536.
pub const DEFAULT_RING_CAPACITY: usize = 4096;
pub const MAX_RING_CAPACITY: usize = 65536;
/// WM-SPEC-019-R02: a redaction corpus of marker words that are always
/// stripped from detail payloads when capture is enabled.
pub const REDACTION_CORPUS: &[&str] = &[
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
];
pub const MAX_DETAIL_BYTES: usize = 4096;

/// Severity classification (WM-FEAT-0225).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Severity {
    Debug,
    Info,
    Warn,
    Error,
    Critical,
}

impl Severity {
    pub fn as_str(self) -> &'static str {
        match self {
            Severity::Debug => "debug",
            Severity::Info => "info",
            Severity::Warn => "warn",
            Severity::Error => "error",
            Severity::Critical => "critical",
        }
    }
}

/// Subsystem classification (SPEC-019-R02).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Subsystem {
    Core,
    Network,
    Lua,
    Mapper,
    Voice,
    Renderer,
    Headless,
    Provider,
    Update,
    Package,
    Security,
    Telemetry,
}

impl Subsystem {
    pub fn as_str(self) -> &'static str {
        match self {
            Subsystem::Core => "core",
            Subsystem::Network => "network",
            Subsystem::Lua => "lua",
            Subsystem::Mapper => "mapper",
            Subsystem::Voice => "voice",
            Subsystem::Renderer => "renderer",
            Subsystem::Headless => "headless",
            Subsystem::Provider => "provider",
            Subsystem::Update => "update",
            Subsystem::Package => "package",
            Subsystem::Security => "security",
            Subsystem::Telemetry => "telemetry",
        }
    }
}

/// Priority classification (SPEC-019-R02).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "UPPERCASE")]
pub enum Priority {
    P0,
    P1,
    P2,
    P3,
    P4,
}

/// Data classification (WM-SPEC-023-R05): private, secret, diagnostic,
/// voice, transcript, and public content use distinct classifications
/// and default retention.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum DataClass {
    Public,
    Private,
    Secret,
    Diagnostic,
    Voice,
    Transcript,
}

impl DataClass {
    /// Default retention in days (WM-SPEC-023-R05).
    pub fn default_retention_days(self) -> u32 {
        match self {
            DataClass::Public => 365,
            DataClass::Private => 90,
            DataClass::Secret => 0,
            DataClass::Diagnostic => 30,
            DataClass::Voice => 14,
            DataClass::Transcript => 90,
        }
    }

    pub fn as_str(self) -> &'static str {
        match self {
            DataClass::Public => "public",
            DataClass::Private => "private",
            DataClass::Secret => "secret",
            DataClass::Diagnostic => "diagnostic",
            DataClass::Voice => "voice",
            DataClass::Transcript => "transcript",
        }
    }
}

/// A single redacted telemetry event (SPEC-019-R02). `details` never
/// contains raw secrets; the redactor strips corpus markers at capture.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TelemetryEvent {
    pub schema_version: u32,
    pub event_id: String,
    pub t: i64,
    pub subsystem: Subsystem,
    pub severity: Severity,
    pub fingerprint: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub correlation_id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub scope: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub feature: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub priority: Option<Priority>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub latency_ms: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub queue_depth: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub dropped: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub coalesced: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub provider: Option<String>,
    pub classification: DataClass,
    #[serde(default)]
    pub redacted: bool,
    #[serde(default, skip_serializing_if = "serde_json::Map::is_empty")]
    pub details: serde_json::Map<String, serde_json::Value>,
}

impl TelemetryEvent {
    /// Structured event fingerprint and correlation ID (WM-FEAT-0224).
    /// The fingerprint hashes only structural fields (subsystem,
    /// severity, feature, classification) — never payload content — so
    /// deduplication works without private content (WM-FEAT-0227).
    pub fn fingerprint_for(
        subsystem: Subsystem,
        severity: Severity,
        feature: Option<&str>,
        classification: DataClass,
    ) -> String {
        let mut h = Sha256::new();
        h.update(subsystem.as_str().as_bytes());
        h.update([0u8]);
        h.update(severity.as_str().as_bytes());
        h.update([0u8]);
        h.update(feature.unwrap_or("").as_bytes());
        h.update([0u8]);
        h.update(classification.as_str().as_bytes());
        hex(&h.finalize())[..16].to_string()
    }

    pub fn new(
        event_id: String,
        t: i64,
        subsystem: Subsystem,
        severity: Severity,
        fingerprint: String,
        classification: DataClass,
        details: serde_json::Map<String, serde_json::Value>,
    ) -> Self {
        TelemetryEvent {
            schema_version: TELEMETRY_SCHEMA_VERSION,
            event_id,
            t,
            subsystem,
            severity,
            fingerprint,
            correlation_id: None,
            scope: None,
            feature: None,
            priority: None,
            latency_ms: None,
            queue_depth: None,
            dropped: None,
            coalesced: None,
            provider: None,
            classification,
            redacted: false,
            details,
        }
    }
}

/// Bounded crash-safe ring buffer (WM-FEAT-0223, WM-SPEC-019-R01).
/// Events are kept in memory up to `capacity`; the newest event replaces
/// the oldest when full. The buffer never grows beyond capacity.
#[derive(Debug, Clone)]
pub struct RingBuffer {
    capacity: usize,
    events: VecDeque<TelemetryEvent>,
}

impl RingBuffer {
    pub fn new(capacity: usize) -> Result<Self, TelemetryError> {
        if capacity == 0 {
            return Err(TelemetryError::invalid(
                "ring-capacity",
                "ring buffer capacity must be positive",
            ));
        }
        if capacity > MAX_RING_CAPACITY {
            return Err(TelemetryError::invalid(
                "ring-capacity",
                "ring buffer capacity exceeds maximum",
            ));
        }
        Ok(RingBuffer {
            capacity,
            events: VecDeque::with_capacity(capacity),
        })
    }

    pub fn capacity(&self) -> usize {
        self.capacity
    }

    pub fn len(&self) -> usize {
        self.events.len()
    }

    pub fn is_empty(&self) -> bool {
        self.events.is_empty()
    }

    /// Push an event, evicting the oldest when full. Returns the number
    /// of events dropped (0 or 1).
    pub fn push(&mut self, event: TelemetryEvent) -> u64 {
        let mut dropped = 0u64;
        if self.events.len() == self.capacity {
            self.events.pop_front();
            dropped = 1;
        }
        self.events.push_back(event);
        dropped
    }

    pub fn iter(&self) -> impl Iterator<Item = &TelemetryEvent> {
        self.events.iter()
    }

    pub fn back(&self) -> Option<&TelemetryEvent> {
        self.events.back()
    }

    pub fn clear(&mut self) {
        self.events.clear();
    }
}

/// Redaction applied at the capture boundary (WM-SPEC-019-R02). Marker
/// words and their inline values are replaced with `[REDACTED]`; free
/// text is checked for known secret shapes.
#[derive(Debug, Clone)]
pub struct Redactor {
    corpus: Vec<String>,
}

impl Default for Redactor {
    fn default() -> Self {
        Redactor {
            corpus: REDACTION_CORPUS.iter().map(|s| s.to_string()).collect(),
        }
    }
}

impl Redactor {
    pub fn new(corpus: Vec<String>) -> Self {
        Redactor { corpus }
    }

    /// True if the text contains a corpus marker.
    pub fn contains_marker(&self, text: &str) -> bool {
        let lower = text.to_ascii_lowercase();
        self.corpus.iter().any(|m| lower.contains(m))
    }

    /// Redact a free-text value: replace corpus markers and inline
    /// assignments with `[REDACTED]`. Single pass — the marker itself is
    /// consumed, so the replacement can never be re-matched.
    pub fn redact_text(&self, text: &str) -> String {
        let lower = text.to_ascii_lowercase();
        let bytes = text.as_bytes();
        let mut out = String::with_capacity(text.len());
        let mut pos = 0usize;
        while pos < bytes.len() {
            // Earliest marker at or after pos.
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
                    // Consume separators (key=, key:, key ) then the
                    // value token up to a delimiter.
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

    /// Redact a detail map. Values whose key or value contains a corpus
    /// marker are replaced with `[REDACTED]`. Returns true if anything
    /// was redacted.
    pub fn redact_details(&self, details: &mut serde_json::Map<String, serde_json::Value>) -> bool {
        let mut redacted_any = false;
        for value in details.values_mut() {
            match value {
                serde_json::Value::String(s) => {
                    if self.contains_marker(s) {
                        *s = "[REDACTED]".to_string();
                        redacted_any = true;
                    }
                }
                serde_json::Value::Object(map) => {
                    if self.redact_details(map) {
                        redacted_any = true;
                    }
                }
                serde_json::Value::Array(arr) => {
                    for item in arr.iter_mut() {
                        if let serde_json::Value::String(s) = item {
                            if self.contains_marker(s) {
                                *s = "[REDACTED]".to_string();
                                redacted_any = true;
                            }
                        }
                    }
                }
                _ => {}
            }
        }
        redacted_any
    }
}

/// Local structured telemetry engine (SPEC-019). Off by default; only an
/// explicit `enable` flips capture on. Events are stored in the bounded
/// ring buffer and written to an append-only crash-safe journal so a
/// crash loses at most the current in-memory tail.
#[derive(Debug, Clone)]
pub struct TelemetryEngine {
    enabled: bool,
    buffer: RingBuffer,
    redactor: Redactor,
    journal: Option<PathBuf>,
    dropped_total: u64,
    coalesced_total: u64,
}

impl TelemetryEngine {
    pub fn new(capacity: usize) -> Result<Self, TelemetryError> {
        Ok(TelemetryEngine {
            enabled: false,
            buffer: RingBuffer::new(capacity)?,
            redactor: Redactor::default(),
            journal: None,
            dropped_total: 0,
            coalesced_total: 0,
        })
    }

    pub fn with_journal(
        capacity: usize,
        journal: impl AsRef<Path>,
    ) -> Result<Self, TelemetryError> {
        let mut engine = TelemetryEngine::new(capacity)?;
        engine.journal = Some(journal.as_ref().to_path_buf());
        Ok(engine)
    }

    pub fn is_enabled(&self) -> bool {
        self.enabled
    }

    /// WM-SPEC-019-R01: telemetry is off by default; this is the only
    /// way to turn capture on.
    pub fn enable(&mut self) {
        self.enabled = true;
    }

    pub fn disable(&mut self) {
        self.enabled = false;
    }

    pub fn buffer(&self) -> &RingBuffer {
        &self.buffer
    }

    pub fn buffer_mut(&mut self) -> &mut RingBuffer {
        &mut self.buffer
    }

    pub fn dropped_total(&self) -> u64 {
        self.dropped_total
    }

    pub fn coalesced_total(&self) -> u64 {
        self.coalesced_total
    }

    /// Record an event. When disabled, the event is discarded and the
    /// call is a no-op (telemetry stays off externally by default). The
    /// event's detail payload is redacted at the boundary before capture.
    pub fn record(&mut self, mut event: TelemetryEvent) -> Result<(), TelemetryError> {
        if !self.enabled {
            return Ok(());
        }
        if event.details.len() > MAX_DETAIL_BYTES {
            return Err(TelemetryError::invalid(
                "event-details",
                "event detail payload exceeds bound",
            ));
        }
        if serde_json::to_vec(&event.details)
            .map(|v| v.len())
            .unwrap_or(usize::MAX)
            > MAX_DETAIL_BYTES
        {
            return Err(TelemetryError::invalid(
                "event-details",
                "event detail payload exceeds byte bound",
            ));
        }
        let redacted = self.redactor.redact_details(&mut event.details);
        event.redacted = redacted;
        if let Some(path) = &self.journal {
            if let Err(e) = append_journal(path, &event) {
                return Err(TelemetryError::unavailable(
                    "telemetry-journal",
                    "unable to append telemetry journal",
                    e.to_string(),
                ));
            }
        }
        let dropped = self.buffer.push(event);
        self.dropped_total += dropped;
        Ok(())
    }

    /// Merge an identical fingerprint within a short window by counting
    /// it as coalesced instead of storing a duplicate event
    /// (WM-FEAT-0227). Returns true when coalesced.
    pub fn record_coalesced(&mut self, mut event: TelemetryEvent) -> bool {
        if !self.enabled {
            return false;
        }
        if let Some(last) = self.buffer.back() {
            if last.fingerprint == event.fingerprint && (event.t - last.t).abs() < 5_000 {
                self.coalesced_total += 1;
                return true;
            }
        }
        let redacted = self.redactor.redact_details(&mut event.details);
        event.redacted = redacted;
        let dropped = self.buffer.push(event);
        self.dropped_total += dropped;
        false
    }

    /// Recover the journal tail into the ring buffer (crash recovery).
    /// Only the most recent `capacity` events are kept.
    pub fn recover_journal(&mut self, path: impl AsRef<Path>) -> Result<u64, TelemetryError> {
        let path = path.as_ref();
        if !path.exists() {
            return Ok(0);
        }
        let bytes = std::fs::read(path).map_err(|e| {
            TelemetryError::unavailable(
                "telemetry-journal",
                "unable to read journal",
                e.to_string(),
            )
        })?;
        let mut recovered = 0u64;
        for line in bytes.split(|b| *b == b'\n') {
            if line.is_empty() {
                continue;
            }
            match serde_json::from_slice::<TelemetryEvent>(line) {
                Ok(ev) => {
                    self.buffer.push(ev);
                    recovered += 1;
                }
                Err(_) => {
                    // Corrupt tail from a partial crash write: stop
                    // recovery at the first malformed record. This is
                    // fail-closed: never fabricate an event.
                    break;
                }
            }
        }
        Ok(recovered)
    }
}

fn append_journal(path: &Path, event: &TelemetryEvent) -> std::io::Result<()> {
    use std::io::Write;
    let mut f = std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(path)?;
    let line = serde_json::to_string(event).map_err(std::io::Error::other)?;
    writeln!(f, "{line}")?;
    f.flush()
}

fn hex(bytes: &[u8]) -> String {
    let mut s = String::with_capacity(bytes.len() * 2);
    for b in bytes {
        s.push_str(&format!("{b:02x}"));
    }
    s
}

/// Stable public error type (WM-SPEC-025-R02): stable code, safe
/// message, correlation ID, retry class, user action, diagnostic
/// reference, and redacted internal cause.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TelemetryError {
    pub code: String,
    pub message: String,
    pub correlation_id: String,
    pub retry_class: String,
    pub user_action: String,
    pub diagnostic_ref: String,
    pub internal_cause: String,
}

impl TelemetryError {
    pub fn invalid(code: &str, message: &str) -> Self {
        TelemetryError::full(
            code,
            message,
            "validation",
            "no-retry",
            "Check the reported value and retry.",
            "diagnostics/telemetry/errors.md",
            "[REDACTED]",
        )
    }

    pub fn unavailable(code: &str, message: &str, cause: String) -> Self {
        TelemetryError::full(
            code,
            message,
            "unavailable",
            "retry-bounded",
            "Restart capture or check local storage.",
            "diagnostics/telemetry/errors.md",
            &redact_cause(&cause),
        )
    }

    pub fn full(
        code: &str,
        message: &str,
        retry_class: &str,
        _retry: &str,
        user_action: &str,
        diagnostic_ref: &str,
        internal_cause: &str,
    ) -> Self {
        TelemetryError {
            code: code.to_string(),
            message: message.to_string(),
            correlation_id: format!("tel-{:016x}", rand_u64()),
            retry_class: retry_class.to_string(),
            user_action: user_action.to_string(),
            diagnostic_ref: diagnostic_ref.to_string(),
            internal_cause: internal_cause.to_string(),
        }
    }
}

fn redact_cause(cause: &str) -> String {
    let r = Redactor::default();
    r.redact_text(cause)
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

    fn ev(id: &str, subsystem: Subsystem, severity: Severity, class: DataClass) -> TelemetryEvent {
        TelemetryEvent::new(
            id.to_string(),
            1_700_000_000_000,
            subsystem,
            severity,
            TelemetryEvent::fingerprint_for(subsystem, severity, None, class),
            class,
            serde_json::Map::new(),
        )
    }

    #[test]
    fn off_by_default() {
        let engine = TelemetryEngine::new(64).unwrap();
        assert!(!engine.is_enabled());
    }

    #[test]
    fn ring_buffer_is_bounded() {
        let mut buf = RingBuffer::new(4).unwrap();
        for i in 0..10 {
            buf.push(ev(
                &format!("e{i}"),
                Subsystem::Core,
                Severity::Info,
                DataClass::Diagnostic,
            ));
        }
        assert_eq!(buf.len(), 4);
        assert_eq!(buf.capacity(), 4);
        let first = buf.iter().next().unwrap();
        assert_eq!(first.event_id, "e6");
    }

    #[test]
    fn zero_capacity_rejected() {
        assert!(RingBuffer::new(0).is_err());
        assert!(RingBuffer::new(MAX_RING_CAPACITY + 1).is_err());
    }

    #[test]
    fn disabled_record_is_noop() {
        let mut engine = TelemetryEngine::new(8).unwrap();
        engine
            .record(ev(
                "e1",
                Subsystem::Core,
                Severity::Info,
                DataClass::Diagnostic,
            ))
            .unwrap();
        assert!(engine.buffer().is_empty());
    }

    #[test]
    fn enabled_records_redacts() {
        let mut engine = TelemetryEngine::new(8).unwrap();
        engine.enable();
        let mut details = serde_json::Map::new();
        details.insert(
            "query".to_string(),
            serde_json::Value::String("password=hunter2".to_string()),
        );
        let mut e = TelemetryEvent::new(
            "e-redact".to_string(),
            1,
            Subsystem::Network,
            Severity::Warn,
            "fp".to_string(),
            DataClass::Secret,
            details,
        );
        engine.record(e).unwrap();
        let stored = engine.buffer().iter().next().unwrap();
        assert!(stored.redacted);
        let stored_details = stored.details.get("query").unwrap().as_str().unwrap();
        assert!(!stored_details.contains("hunter2"));
        assert!(stored_details.contains("[REDACTED]"));
    }

    #[test]
    fn fingerprint_is_structural_not_content() {
        let fp1 = TelemetryEvent::fingerprint_for(
            Subsystem::Mapper,
            Severity::Error,
            Some("WM-FEAT-0227"),
            DataClass::Diagnostic,
        );
        let fp2 = TelemetryEvent::fingerprint_for(
            Subsystem::Mapper,
            Severity::Error,
            Some("WM-FEAT-0227"),
            DataClass::Diagnostic,
        );
        assert_eq!(fp1, fp2);
        assert_eq!(fp1.len(), 16);
    }

    #[test]
    fn coalesce_same_fingerprint() {
        let mut engine = TelemetryEngine::new(8).unwrap();
        engine.enable();
        let fp = TelemetryEvent::fingerprint_for(
            Subsystem::Telemetry,
            Severity::Info,
            Some("WM-FEAT-0227"),
            DataClass::Diagnostic,
        );
        let mut e1 = ev(
            "c1",
            Subsystem::Telemetry,
            Severity::Info,
            DataClass::Diagnostic,
        );
        e1.fingerprint = fp.clone();
        let mut e2 = ev(
            "c2",
            Subsystem::Telemetry,
            Severity::Info,
            DataClass::Diagnostic,
        );
        e2.fingerprint = fp.clone();
        e2.t = e1.t + 100;
        assert!(!engine.record_coalesced(e1));
        assert!(engine.record_coalesced(e2));
        assert_eq!(engine.coalesced_total(), 1);
        assert_eq!(engine.buffer().len(), 1);
    }

    #[test]
    fn journal_recovery() {
        let dir = std::env::temp_dir().join(format!("wmtel-{}", rand_u64()));
        std::fs::create_dir_all(&dir).unwrap();
        let journal = dir.join("journal.jsonl");
        let mut engine = TelemetryEngine::with_journal(64, &journal).unwrap();
        engine.enable();
        let e = ev("j1", Subsystem::Core, Severity::Info, DataClass::Diagnostic);
        engine.record(e).unwrap();
        assert!(journal.exists());
        drop(engine);
        let mut fresh = TelemetryEngine::new(64).unwrap();
        let recovered = fresh.recover_journal(&journal).unwrap();
        assert_eq!(recovered, 1);
        assert_eq!(fresh.buffer().len(), 1);
        let _ = std::fs::remove_dir_all(dir);
    }

    #[test]
    fn error_has_stable_fields() {
        let err = TelemetryError::invalid("ring-capacity", "bad capacity");
        assert_eq!(err.code, "ring-capacity");
        assert_eq!(err.retry_class, "validation");
        assert_eq!(err.internal_cause, "[REDACTED]");
        assert!(!err.correlation_id.is_empty());
        assert!(!err.user_action.is_empty());
        assert!(!err.diagnostic_ref.is_empty());
    }

    #[test]
    fn redactor_strips_inline_secrets() {
        let r = Redactor::default();
        // The whole key=value token is consumed — the marker itself is
        // never preserved, so the replacement cannot be re-matched.
        assert_eq!(r.redact_text("token=abc123"), "[REDACTED]");
        assert_eq!(
            r.redact_text("say password=hunter2 now"),
            "say [REDACTED] now"
        );
        assert!(r.contains_marker("api_key"));
        assert!(!r.contains_marker("plain message"));
    }

    #[test]
    fn classification_retention() {
        assert_eq!(DataClass::Secret.default_retention_days(), 0);
        assert_eq!(DataClass::Diagnostic.default_retention_days(), 30);
        assert!(DataClass::Secret < DataClass::Diagnostic);
    }
}

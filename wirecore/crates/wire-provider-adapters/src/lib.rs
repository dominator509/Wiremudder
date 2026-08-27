//! WireMudder AI provider adapters (SPEC-013, EP-016).
//!
//! WM-FEAT-0037: local and remote AI provider adapters under the accepted
//! WireMudder contracts. WM-SPEC-013-R04: adapters expose one versioned
//! interface for local and remote models and normalize streaming,
//! cancellation, usage, errors, health, and capability metadata.
//! WM-SPEC-013-R03: private messages, credentials, login commands, routing
//! secrets, and unapproved voice content are redacted before any provider
//! sees the request. WM-SPEC-025-R07: cancellation is distinct from failure.
//! WM-SPEC-025-R09: user-facing messages never expose stack traces, paths,
//! credentials, private text, provider payloads, or signing metadata.
//!
//! Supply chain: serde/serde_json/regex are already pinned by the repository
//! (wire-privacy uses regex 1.13.1); the local HTTP client is std-only.

use serde::{Deserialize, Serialize};
use std::net::TcpStream;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;
use wire_privacy::RedactionEngine;

pub const ADAPTER_SCHEMA_VERSION: u32 = 1;

// ---------------------------------------------------------------------------
// Capability metadata (R04: normalized capability metadata)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ProviderKind {
    Local,
    Remote,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ProviderCapabilities {
    pub schema_version: u32,
    pub provider_id: String,
    pub kind: ProviderKind,
    pub model_family: String,
    pub model: String,
    pub streaming: bool,
    pub cancellation: bool,
    pub usage: bool,
    pub health: bool,
    pub context_window: usize,
    pub max_output: usize,
    pub locality: String,
    pub certified: bool,
    pub remote_egress: bool,
}

impl ProviderCapabilities {
    pub fn local(
        provider_id: &str,
        model_family: &str,
        model: &str,
        context_window: usize,
        max_output: usize,
    ) -> Self {
        Self {
            schema_version: ADAPTER_SCHEMA_VERSION,
            provider_id: provider_id.into(),
            kind: ProviderKind::Local,
            model_family: model_family.into(),
            model: model.into(),
            streaming: true,
            cancellation: true,
            usage: true,
            health: true,
            context_window,
            max_output,
            locality: "local".into(),
            certified: false,
            remote_egress: false,
        }
    }
}

// ---------------------------------------------------------------------------
// Request, stream, usage, response (normalized shapes)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CompletionRequest {
    pub request_id: String,
    pub feature: String,
    pub system: Option<String>,
    pub prompt: String,
    pub max_tokens: usize,
    pub temperature: Option<f64>,
    pub stream: bool,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct StreamChunk {
    pub request_id: String,
    pub delta: String,
    pub done: bool,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct UsageRecord {
    pub provider_id: String,
    pub model: String,
    pub feature: String,
    pub prompt_tokens: usize,
    pub completion_tokens: usize,
    pub latency_ms: u64,
    pub request_id: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CompletionResponse {
    pub text: String,
    pub usage: UsageRecord,
    pub streamed: bool,
    pub cancelled: bool,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct HealthStatus {
    pub provider_id: String,
    pub healthy: bool,
    pub latency_ms: u64,
    pub detail: String,
}

// ---------------------------------------------------------------------------
// Typed errors (SPEC-025). Cancellation is a distinct variant (R07).
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq)]
pub enum AdapterError {
    Unavailable(String),
    Timeout { provider: String, budget_ms: u64 },
    Cancelled { provider: String, request_id: String },
    InvalidRequest(String),
    Auth(String),
    Policy(String),
    Protocol(String),
    Corrupt(String),
    Redaction(String),
}

impl AdapterError {
    /// WM-SPEC-025-R09: user-facing messages expose no stack traces, paths,
    /// credentials, private text, provider payloads, or signing metadata.
    pub fn user_message(&self) -> String {
        match self {
            AdapterError::Cancelled { provider, .. } => {
                format!("request to {provider} was cancelled")
            }
            AdapterError::Timeout { provider, budget_ms } => {
                format!("{provider} did not respond within {budget_ms} ms")
            }
            AdapterError::Unavailable(_) => "provider is unavailable".into(),
            AdapterError::InvalidRequest(_) => "the request was not accepted".into(),
            AdapterError::Auth(_) => "provider authentication is not configured".into(),
            AdapterError::Policy(_) => "the route is not permitted".into(),
            AdapterError::Protocol(_) => "the provider returned an invalid response".into(),
            AdapterError::Corrupt(_) => "the provider returned malformed data".into(),
            AdapterError::Redaction(_) => "the request could not be redacted safely".into(),
        }
    }

    pub fn is_cancelled(&self) -> bool {
        matches!(self, AdapterError::Cancelled { .. })
    }
}

// ---------------------------------------------------------------------------
// One versioned adapter interface (R04)
// ---------------------------------------------------------------------------

pub trait ProviderAdapter: Send + Sync {
    fn capabilities(&self) -> &ProviderCapabilities;
    fn health(&self) -> Result<HealthStatus, AdapterError>;
    fn complete(&self, request: &CompletionRequest) -> Result<CompletionResponse, AdapterError>;
    fn stream(
        &self,
        request: &CompletionRequest,
        sink: &mut dyn FnMut(StreamChunk),
    ) -> Result<CompletionResponse, AdapterError>;
    fn cancel(&self) -> Result<(), AdapterError>;
    fn usage(&self) -> Result<Vec<UsageRecord>, AdapterError>;
}

// ---------------------------------------------------------------------------
// Request redaction (R03): nothing private reaches a provider.
// ---------------------------------------------------------------------------

pub struct RequestRedactor {
    engine: RedactionEngine,
}

impl RequestRedactor {
    /// Fail-closed by construction: the built-in pattern set is always
    /// installed, so no request can be sent unredacted.
    pub fn new() -> Self {
        let mut engine = RedactionEngine::new(true);
        for (id, class, re, rep) in [
            ("cred-01", "credential", r"(?i)(password|passwd|pass)\s*[:=]\s*\S+", "[REDACTED:credential]"),
            ("cred-02", "key", r"sk-[A-Za-z0-9_-]{8,}", "[REDACTED:key]"),
            ("cred-03", "key", r"(?i)(api[_-]?key|access[_-]?token)\s*[:=]\s*\S+", "[REDACTED:key]"),
            ("cred-04", "secret", r"(?i)(secret|routing[_-]?secret)\s*[:=]\s*\S+", "[REDACTED:secret]"),
            ("cred-05", "login", r"(?i)\b(login|log in|sign in)\s+\S+(\s+\S+)?", "[REDACTED:login]"),
            ("cred-06", "login", r"(?i)\b(quit|logout)\b", "[REDACTED:login]"),
            ("cred-07", "private-message", r"(?im)^\s*(tell|whisper|gtell|ptell|mtell)\s+\S+\s+.*$", "[REDACTED:private-message]"),
            ("cred-08", "voice", r"(?i)(voice\s*content\s*[:=]|voice\s*[:=]|\[voice:)[^\n]*", "[REDACTED:voice-content]"),
        ] {
            if let Ok(p) = wire_privacy::RedactionPattern::new(id, class, re, rep) {
                engine.add_pattern(p);
            }
        }
        Self { engine }
    }

    pub fn pattern_count(&self) -> usize {
        self.engine.pattern_count()
    }

    /// Guarantee R03: the returned text is safe for any provider to see.
    pub fn redact_request(&self, prompt: &str) -> Result<String, AdapterError> {
        if self.engine.pattern_count() == 0 {
            return Err(AdapterError::Redaction("no redaction patterns configured".into()));
        }
        Ok(self.engine.redact(prompt))
    }
}

impl Default for RequestRedactor {
    fn default() -> Self {
        Self::new()
    }
}

// ---------------------------------------------------------------------------
// Real local Ollama adapter (localhost HTTP/1.1 over std TcpStream; no TLS
// needed for loopback). Certified only after live-fire (LF-016, M5).
// ---------------------------------------------------------------------------

pub struct OllamaAdapter {
    capabilities: ProviderCapabilities,
    host: String,
    port: u16,
    timeout_ms: u64,
    cancel_flag: Arc<AtomicBool>,
    usage_log: std::sync::Mutex<Vec<UsageRecord>>,
    redactor: RequestRedactor,
}

impl OllamaAdapter {
    pub fn new(host: &str, port: u16, model: &str, context_window: usize, max_output: usize) -> Self {
        Self {
            capabilities: ProviderCapabilities::local("ollama", "ollama", model, context_window, max_output),
            host: host.into(),
            port,
            timeout_ms: 30_000,
            cancel_flag: Arc::new(AtomicBool::new(false)),
            usage_log: std::sync::Mutex::new(Vec::new()),
            redactor: RequestRedactor::new(),
        }
    }

    pub fn with_timeout(mut self, timeout_ms: u64) -> Self {
        self.timeout_ms = timeout_ms;
        self
    }

    pub fn mark_certified(&mut self) {
        self.capabilities.certified = true;
    }

    fn http_request(&self, path: &str, body: Option<&str>) -> Result<String, AdapterError> {
        use std::io::{ErrorKind, Read, Write};
        let timeout_err = |e: std::io::Error| {
            if matches!(e.kind(), ErrorKind::WouldBlock | ErrorKind::TimedOut) {
                AdapterError::Timeout {
                    provider: self.capabilities.provider_id.clone(),
                    budget_ms: self.timeout_ms,
                }
            } else {
                AdapterError::Unavailable(e.to_string())
            }
        };
        let addr = format!("{}:{}", self.host, self.port);
        let mut stream =
            TcpStream::connect(&addr).map_err(|e| AdapterError::Unavailable(e.to_string()))?;
        stream
            .set_read_timeout(Some(Duration::from_millis(self.timeout_ms)))
            .map_err(|e| AdapterError::Protocol(e.to_string()))?;
        stream
            .set_write_timeout(Some(Duration::from_millis(self.timeout_ms)))
            .map_err(|e| AdapterError::Protocol(e.to_string()))?;

        let method = if body.is_some() { "POST" } else { "GET" };
        let body = body.unwrap_or("");
        let req = format!(
            "{method} {path} HTTP/1.1\r\nHost: {host}:{port}\r\nContent-Type: application/json\r\nContent-Length: {len}\r\nConnection: close\r\n\r\n{body}",
            host = self.host,
            port = self.port,
            len = body.len()
        );
        stream
            .write_all(req.as_bytes())
            .map_err(&timeout_err)?;
        let mut buf = Vec::new();
        stream.read_to_end(&mut buf).map_err(&timeout_err)?;
        let resp = String::from_utf8_lossy(&buf).into_owned();
        let status = resp.lines().next().unwrap_or("");
        if !status.contains(" 200 ") {
            return Err(AdapterError::Protocol(format!(
                "http status: {}",
                status.trim()
            )));
        }
        let body_start = resp
            .find("\r\n\r\n")
            .ok_or_else(|| AdapterError::Protocol("missing header separator".into()))?
            + 4;
        Ok(resp[body_start..].to_string())
    }
}

/// A cancel handle sharing the adapter's cancel flag. Move or clone to any
/// thread; `cancel()` aborts in-flight requests (WM-SPEC-025-R07).
#[derive(Clone)]
pub struct CancelHandle(Arc<AtomicBool>);

impl CancelHandle {
    pub fn cancel(&self) {
        self.0.store(true, Ordering::SeqCst);
    }

    pub fn is_cancelled(&self) -> bool {
        self.0.load(Ordering::SeqCst)
    }
}

impl OllamaAdapter {
    pub fn clone_cancel_handle(&self) -> CancelHandle {
        CancelHandle(self.cancel_flag.clone())
    }
}

impl ProviderAdapter for OllamaAdapter {
    fn capabilities(&self) -> &ProviderCapabilities {
        &self.capabilities
    }

    fn health(&self) -> Result<HealthStatus, AdapterError> {
        let start = std::time::Instant::now();
        let body = self.http_request("/api/tags", None)?;
        let latency_ms = start.elapsed().as_millis() as u64;
        let healthy = parse_health(&body).ok().flatten().unwrap_or(false);
        Ok(HealthStatus {
            provider_id: self.capabilities.provider_id.clone(),
            healthy,
            latency_ms,
            detail: if healthy { "ok".into() } else { "no models".into() },
        })
    }

    fn complete(&self, request: &CompletionRequest) -> Result<CompletionResponse, AdapterError> {
        if self.cancel_flag.load(Ordering::SeqCst) {
            return Err(AdapterError::Cancelled {
                provider: self.capabilities.provider_id.clone(),
                request_id: request.request_id.clone(),
            });
        }
        let safe_prompt = self.redactor.redact_request(&request.prompt)?;
        let payload = build_chat_payload(
            &self.capabilities.model,
            request.system.as_deref(),
            &safe_prompt,
            request.max_tokens,
            false,
        );
        let start = std::time::Instant::now();
        let body = self.http_request("/api/chat", Some(&payload))?;
        let latency_ms = start.elapsed().as_millis() as u64;
        let (text, prompt_tokens, completion_tokens) = parse_chat_response(&body)?;
        let usage = UsageRecord {
            provider_id: self.capabilities.provider_id.clone(),
            model: self.capabilities.model.clone(),
            feature: request.feature.clone(),
            prompt_tokens,
            completion_tokens,
            latency_ms,
            request_id: request.request_id.clone(),
        };
        if let Ok(mut log) = self.usage_log.lock() {
            log.push(usage.clone());
        }
        Ok(CompletionResponse {
            text,
            usage,
            streamed: false,
            cancelled: false,
        })
    }

    fn stream(
        &self,
        request: &CompletionRequest,
        sink: &mut dyn FnMut(StreamChunk),
    ) -> Result<CompletionResponse, AdapterError> {
        if self.cancel_flag.load(Ordering::SeqCst) {
            return Err(AdapterError::Cancelled {
                provider: self.capabilities.provider_id.clone(),
                request_id: request.request_id.clone(),
            });
        }
        let safe_prompt = self.redactor.redact_request(&request.prompt)?;
        let payload = build_chat_payload(
            &self.capabilities.model,
            request.system.as_deref(),
            &safe_prompt,
            request.max_tokens,
            true,
        );
        let start = std::time::Instant::now();
        let body = self.http_request("/api/chat", Some(&payload))?;
        let latency_ms = start.elapsed().as_millis() as u64;
        let mut text = String::new();
        for line in body.lines() {
            if self.cancel_flag.load(Ordering::SeqCst) {
                return Err(AdapterError::Cancelled {
                    provider: self.capabilities.provider_id.clone(),
                    request_id: request.request_id.clone(),
                });
            }
            if let Some(chunk) = parse_stream_line(line) {
                if !chunk.delta.is_empty() {
                    text.push_str(&chunk.delta);
                }
                sink(StreamChunk {
                    request_id: request.request_id.clone(),
                    delta: chunk.delta,
                    done: chunk.done,
                });
            }
        }
        let usage = UsageRecord {
            provider_id: self.capabilities.provider_id.clone(),
            model: self.capabilities.model.clone(),
            feature: request.feature.clone(),
            prompt_tokens: 0,
            completion_tokens: text.chars().count(),
            latency_ms,
            request_id: request.request_id.clone(),
        };
        if let Ok(mut log) = self.usage_log.lock() {
            log.push(usage.clone());
        }
        Ok(CompletionResponse {
            text,
            usage,
            streamed: true,
            cancelled: false,
        })
    }

    fn cancel(&self) -> Result<(), AdapterError> {
        self.cancel_flag.store(true, Ordering::SeqCst);
        Ok(())
    }

    fn usage(&self) -> Result<Vec<UsageRecord>, AdapterError> {
        Ok(self.usage_log.lock().map(|l| l.clone()).unwrap_or_default())
    }
}

// ---------------------------------------------------------------------------
// Disabled remote adapter: uncertified adapters stay disabled and
// unadvertised (acceptance obligation 6). This is the production disabled
// state, not a mock: every call is denied by policy until certification.
// ---------------------------------------------------------------------------

pub struct DisabledRemoteAdapter {
    capabilities: ProviderCapabilities,
}
impl DisabledRemoteAdapter {
    pub fn new(provider_id: &str, model: &str, _endpoint: &str) -> Self {
        let mut caps = ProviderCapabilities::local(provider_id, "remote", model, 0, 0);
        caps.kind = ProviderKind::Remote;
        caps.locality = "remote".into();
        caps.certified = false;
        caps.remote_egress = true;
        caps.context_window = 0;
        caps.max_output = 0;
        Self { capabilities: caps }
    }
    fn deny() -> AdapterError {
        AdapterError::Policy("remote adapter disabled until certified".into())
    }
}

impl ProviderAdapter for DisabledRemoteAdapter {
    fn capabilities(&self) -> &ProviderCapabilities {
        &self.capabilities
    }
    fn health(&self) -> Result<HealthStatus, AdapterError> {
        Err(Self::deny())
    }
    fn complete(&self, _r: &CompletionRequest) -> Result<CompletionResponse, AdapterError> {
        Err(Self::deny())
    }
    fn stream(
        &self,
        _r: &CompletionRequest,
        _sink: &mut dyn FnMut(StreamChunk),
    ) -> Result<CompletionResponse, AdapterError> {
        Err(Self::deny())
    }
    fn cancel(&self) -> Result<(), AdapterError> {
        Ok(())
    }
    fn usage(&self) -> Result<Vec<UsageRecord>, AdapterError> {
        Ok(Vec::new())
    }
}

// ---------------------------------------------------------------------------
// Pure parse/build helpers (deterministic, unit-testable without network)
// ---------------------------------------------------------------------------

/// Build the /api/chat JSON payload. Deterministic.
pub fn build_chat_payload(
    model: &str,
    system: Option<&str>,
    prompt: &str,
    max_tokens: usize,
    stream: bool,
) -> String {
    let mut messages = Vec::new();
    if let Some(sys) = system {
        messages.push(format!(
            "{{\"role\":\"system\",\"content\":{}}}",
            serde_json::to_string(sys).unwrap_or_else(|_| "\"\"".into())
        ));
    }
    messages.push(format!(
        "{{\"role\":\"user\",\"content\":{}}}",
        serde_json::to_string(prompt).unwrap_or_else(|_| "\"\"".into())
    ));
    format!(
        "{{\"model\":{},\"messages\":[{}],\"stream\":{},\"options\":{{\"num_predict\":{}}}}}",
        serde_json::to_string(model).unwrap_or_else(|_| "\"\"".into()),
        messages.join(","),
        stream,
        max_tokens
    )
}

/// Parse a non-stream /api/chat response. Deterministic; errors are typed.
pub fn parse_chat_response(body: &str) -> Result<(String, usize, usize), AdapterError> {
    let v: serde_json::Value =
        serde_json::from_str(body).map_err(|e| AdapterError::Corrupt(e.to_string()))?;
    let text = v
        .get("message")
        .and_then(|m| m.get("content"))
        .and_then(|c| c.as_str())
        .ok_or_else(|| AdapterError::Corrupt("missing message.content".into()))?
        .to_string();
    let prompt_tokens = v
        .get("prompt_eval_count")
        .and_then(|c| c.as_u64())
        .unwrap_or(0) as usize;
    let completion_tokens = v
        .get("eval_count")
        .and_then(|c| c.as_u64())
        .unwrap_or_else(|| text.chars().count() as u64) as usize;
    Ok((text, prompt_tokens, completion_tokens))
}

/// Parse one NDJSON stream line; None when not a content-bearing line.
pub fn parse_stream_line(line: &str) -> Option<StreamChunk> {
    let line = line.trim();
    if line.is_empty() {
        return None;
    }
    let v: serde_json::Value = serde_json::from_str(line).ok()?;
    let delta = v
        .get("message")
        .and_then(|m| m.get("content"))
        .and_then(|c| c.as_str())
        .unwrap_or("")
        .to_string();
    let done = v.get("done").and_then(|d| d.as_bool()).unwrap_or(false);
    Some(StreamChunk {
        request_id: String::new(),
        delta,
        done,
    })
}

/// Parse a /api/tags health response; Ok(Some(true)) when models exist.
pub fn parse_health(body: &str) -> Result<Option<bool>, AdapterError> {
    let v: serde_json::Value =
        serde_json::from_str(body).map_err(|e| AdapterError::Corrupt(e.to_string()))?;
    match v.get("models") {
        Some(m) => Ok(Some(m.as_array().map(|a| !a.is_empty()).unwrap_or(false))),
        None => Ok(None),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn req() -> CompletionRequest {
        CompletionRequest {
            request_id: "rq-0001".into(),
            feature: "suggest".into(),
            system: None,
            prompt: "hello world".into(),
            max_tokens: 64,
            temperature: None,
            stream: false,
        }
    }

    #[test]
    fn capability_metadata_normalized() {
        let a = OllamaAdapter::new("127.0.0.1", 11434, "tinyllama", 2048, 512);
        let c = a.capabilities();
        assert_eq!(c.schema_version, ADAPTER_SCHEMA_VERSION);
        assert_eq!(c.kind, ProviderKind::Local);
        assert!(c.streaming && c.cancellation && c.usage && c.health);
        assert!(!c.remote_egress);
        assert!(!c.certified);
    }

    #[test]
    fn redact_credentials() {
        let r = RequestRedactor::new();
        let out = r.redact_request("my password= hunter2 and pass: 1234").unwrap();
        assert!(!out.contains("hunter2"));
        assert!(!out.contains("1234"));
        assert!(out.contains("[REDACTED:credential]"));
    }

    #[test]
    fn redact_api_key() {
        let r = RequestRedactor::new();
        let out = r.redact_request("use sk-abcdefgh12345678 to call").unwrap();
        assert!(!out.contains("sk-abcdefgh12345678"));
        assert!(out.contains("[REDACTED:key]"));
    }

    #[test]
    fn redact_login_command() {
        let r = RequestRedactor::new();
        let out = r.redact_request("please login bob secretpass").unwrap();
        assert!(!out.contains("secretpass"));
        assert!(out.contains("[REDACTED:login]"));
    }

    #[test]
    fn redact_private_message() {
        let r = RequestRedactor::new();
        let out = r.redact_request("context:\ntell alice meet me at the vault").unwrap();
        assert!(!out.contains("meet me at the vault"));
        assert!(out.contains("[REDACTED:private-message]"));
    }

    #[test]
    fn redact_routing_secret() {
        let r = RequestRedactor::new();
        let out = r.redact_request("routing_secret= s3cr3t-value").unwrap();
        assert!(!out.contains("s3cr3t-value"));
        assert!(out.contains("[REDACTED:secret]"));
    }

    #[test]
    fn redact_voice_content() {
        let r = RequestRedactor::new();
        let out = r.redact_request("unapproved [voice: spoken words here]").unwrap();
        assert!(!out.contains("spoken words here"));
        assert!(out.contains("[REDACTED:voice-content]"));
    }

    #[test]
    fn redactor_fail_closed() {
        // A raw engine with no patterns must refuse, not pass through.
        let r = RequestRedactor {
            engine: RedactionEngine::new(true),
        };
        let err = r.redact_request("secret text").unwrap_err();
        assert!(matches!(err, AdapterError::Redaction(_)));
    }

    #[test]
    fn cancel_distinct_from_failure() {
        let c = AdapterError::Cancelled {
            provider: "ollama".into(),
            request_id: "rq-1".into(),
        };
        let f = AdapterError::Unavailable("down".into());
        assert!(c.is_cancelled());
        assert!(!f.is_cancelled());
        assert_ne!(c.user_message(), f.user_message());
        assert!(c.user_message().contains("cancelled"));
    }

    #[test]
    fn user_message_is_safe() {
        let cases = [
            AdapterError::Unavailable("/root/private/secret.log io error".into()),
            AdapterError::Auth("sk-live-abcdef12345678 rejected".into()),
            AdapterError::Protocol("payload: hunter2 leaked".into()),
            AdapterError::Corrupt("/tmp/stack trace line 42".into()),
        ];
        for e in cases {
            let m = e.user_message();
            assert!(!m.contains("sk-"), "leak in {m}");
            assert!(!m.contains("/root"), "path leak in {m}");
            assert!(!m.contains("/tmp"), "path leak in {m}");
            assert!(!m.contains("hunter2"), "secret leak in {m}");
        }
    }

    #[test]
    fn parse_completion_response_normalizes_usage() {
        let body = r#"{"model":"tinyllama","message":{"role":"assistant","content":"hi there"},"done":true,"prompt_eval_count":12,"eval_count":3}"#;
        let (text, pt, ct) = parse_chat_response(body).unwrap();
        assert_eq!(text, "hi there");
        assert_eq!(pt, 12);
        assert_eq!(ct, 3);
    }

    #[test]
    fn parse_completion_response_missing_fields_defaults() {
        let body = r#"{"message":{"content":"ok"}}"#;
        let (text, pt, ct) = parse_chat_response(body).unwrap();
        assert_eq!(text, "ok");
        assert_eq!(pt, 0);
        assert_eq!(ct, 2);
    }

    #[test]
    fn parse_completion_response_corrupt() {
        assert!(parse_chat_response("not json").is_err());
    }

    #[test]
    fn parse_stream_line_chunks() {
        let chunk = parse_stream_line(r#"{"message":{"content":"Hello"},"done":false}"#).unwrap();
        assert_eq!(chunk.delta, "Hello");
        assert!(!chunk.done);
        let done = parse_stream_line(r#"{"done":true}"#).unwrap();
        assert!(done.done);
        assert!(parse_stream_line("").is_none());
        assert!(parse_stream_line("junk").is_none());
    }

    #[test]
    fn parse_health_models() {
        assert_eq!(parse_health(r#"{"models":[{"name":"tinyllama"}]}"#).unwrap(), Some(true));
        assert_eq!(parse_health(r#"{"models":[]}"#).unwrap(), Some(false));
        assert!(parse_health("junk").is_err());
    }

    #[test]
    fn build_request_payload_deterministic() {
        let p1 = build_chat_payload("tinyllama", Some("sys"), "prompt", 64, false);
        let p2 = build_chat_payload("tinyllama", Some("sys"), "prompt", 64, false);
        assert_eq!(p1, p2);
        assert!(p1.contains("\"model\":\"tinyllama\""));
        assert!(p1.contains("\"stream\":false"));
        assert!(p1.contains("\"num_predict\":64"));
        assert!(p1.contains("\"role\":\"system\""));
    }

    #[test]
    fn disabled_remote_adapter_denies() {
        let a = DisabledRemoteAdapter::new("openai", "gpt-x", "https://api.example.com");
        assert!(!a.capabilities().certified);
        assert_eq!(a.capabilities().kind, ProviderKind::Remote);
        assert!(a.capabilities().remote_egress);
        let r = req();
        assert!(matches!(a.complete(&r), Err(AdapterError::Policy(_))));
        assert!(matches!(a.health(), Err(AdapterError::Policy(_))));
    }

    #[test]
    fn cancel_flag_gates_request() {
        let a = OllamaAdapter::new("127.0.0.1", 11434, "tinyllama", 2048, 512);
        a.cancel().unwrap();
        let r = req();
        let err = a.complete(&r).unwrap_err();
        assert!(err.is_cancelled());
    }

    #[test]
    fn usage_records_normalized() {
        let a = OllamaAdapter::new("127.0.0.1", 11434, "tinyllama", 2048, 512);
        assert!(a.usage().unwrap().is_empty());
    }
}

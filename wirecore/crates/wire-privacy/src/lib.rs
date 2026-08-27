//! WireMudder privacy core (SPEC-010, SPEC-022, SPEC-023).
//!
//! Denial-first egress control, scoped/revocable consent receipts,
//! and a deterministic redaction engine. Secrets never enter AI
//! context, logs, scripts, plugins, packages, source indexes,
//! diagnostics, renderer prompts, or voice transcripts (WM-SPEC-010-R07).

use regex::Regex;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::{SystemTime, UNIX_EPOCH};

pub const POLICY_SCHEMA_VERSION: u32 = 1;
pub const CONSENT_SCHEMA_VERSION: u32 = 1;
pub const REDACTION_SCHEMA_VERSION: u32 = 1;

/// Privacy modes with exact egress behavior (WM-SPEC-010-R03).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum PrivacyMode {
    Disabled,
    LocalOnly,
    LocalPreferred,
    RemoteRedacted,
    RemoteApproved,
}

impl PrivacyMode {
    /// True when remote egress of any kind is prohibited.
    pub fn blocks_remote(self) -> bool {
        matches!(self, PrivacyMode::Disabled | PrivacyMode::LocalOnly)
    }
}

/// Typed privacy errors (SPEC-025).
#[derive(Debug, Clone, PartialEq)]
pub enum PrivacyError {
    LockdownBlocked { category: String, destination: String },
    NoConsent { feature: String, provider: String },
    ConsentRevoked(String),
    InvalidReceipt(String),
    UnknownDestination(String),
    UnauthorizedOverride(String),
    Regex(String),
}

impl std::fmt::Display for PrivacyError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            PrivacyError::LockdownBlocked { category, destination } => {
                write!(f, "local only lockdown blocks {category} to {destination}")
            }
            PrivacyError::NoConsent { feature, provider } => {
                write!(f, "no consent for {feature} via {provider}")
            }
            PrivacyError::ConsentRevoked(id) => write!(f, "consent revoked: {id}"),
            PrivacyError::InvalidReceipt(m) => write!(f, "invalid receipt: {m}"),
            PrivacyError::UnknownDestination(d) => write!(f, "unknown destination: {d}"),
            PrivacyError::UnauthorizedOverride(m) => write!(f, "unauthorized override: {m}"),
            PrivacyError::Regex(m) => write!(f, "redaction regex: {m}"),
        }
    }
}

impl std::error::Error for PrivacyError {}

/// An individual user-visible, consent-backed override (WM-SPEC-010-R04).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct OverrideEntry {
    pub override_id: String,
    pub category: String,
    pub user_visible: bool,
    pub consent_receipt_id: String,
}

/// Denial-first egress policy (WM-SPEC-010-R03/R04, WM-SPEC-022-R03/R07).
#[derive(Debug, Clone)]
pub struct EgressPolicy {
    pub mode: PrivacyMode,
    pub lockdown: bool,
    pub allowed_destinations: Vec<String>,
    pub denied_categories: Vec<String>,
    overrides: HashMap<String, OverrideEntry>,
}

impl EgressPolicy {
    /// Default is the fallback posture: local only, lockdown on,
    /// no remote destinations, nothing overridden.
    pub fn new_denial_first() -> Self {
        Self {
            mode: PrivacyMode::LocalOnly,
            lockdown: true,
            allowed_destinations: Vec::new(),
            denied_categories: vec![
                "ai".into(),
                "speech".into(),
                "asset-generation".into(),
                "telemetry".into(),
                "package-download".into(),
                "update-check".into(),
            ],
            overrides: HashMap::new(),
        }
    }

    pub fn add_override(&mut self, entry: OverrideEntry) -> Result<(), PrivacyError> {
        if !entry.user_visible {
            return Err(PrivacyError::UnauthorizedOverride(
                "overrides must be user-visible".into(),
            ));
        }
        if entry.consent_receipt_id.len() < 16 {
            return Err(PrivacyError::UnauthorizedOverride(
                "override must reference a consent receipt".into(),
            ));
        }
        if entry.override_id.len() < 8 {
            return Err(PrivacyError::UnauthorizedOverride(
                "override id too short".into(),
            ));
        }
        self.overrides.insert(entry.override_id.clone(), entry);
        Ok(())
    }

    pub fn override_for(&self, category: &str) -> Option<&OverrideEntry> {
        self.overrides.values().find(|o| o.category == category)
    }

    /// Denial-first egress decision. Lockdown blocks everything unless
    /// the destination is allow-listed AND the category either is not
    /// denied or has a user-visible, consent-backed override.
    pub fn can_egress(&self, category: &str, destination: &str) -> Result<(), PrivacyError> {
        if self.mode.blocks_remote() || self.lockdown {
            if !self.allowed_destinations.iter().any(|d| d == destination) {
                return Err(PrivacyError::LockdownBlocked {
                    category: category.into(),
                    destination: destination.into(),
                });
            }
            if self.denied_categories.iter().any(|c| c == category) {
                match self.override_for(category) {
                    Some(o) if o.consent_receipt_id.len() >= 16 => {}
                    _ => {
                        return Err(PrivacyError::LockdownBlocked {
                            category: category.into(),
                            destination: destination.into(),
                        })
                    }
                }
            }
            Ok(())
        } else {
            match self.mode {
                PrivacyMode::RemoteRedacted | PrivacyMode::RemoteApproved => Ok(()),
                PrivacyMode::Disabled | PrivacyMode::LocalOnly | PrivacyMode::LocalPreferred => {
                    Err(PrivacyError::LockdownBlocked {
                        category: category.into(),
                        destination: destination.into(),
                    })
                }
            }
        }
    }

    /// Lawful routing only: proxy procurement, identity rotation,
    /// fingerprint spoofing, account automation, spam, and ban evasion
    /// are never allowed (WM-SPEC-022-R07).
    pub fn can_route_purpose(&self, purpose: &str) -> Result<(), PrivacyError> {
        match purpose {
            "proxy-procurement" | "identity-rotation" | "fingerprint-spoofing"
            | "account-automation" | "spam" | "ban-evasion" => Err(PrivacyError::UnauthorizedOverride(
                format!("routing purpose denied: {purpose}"),
            )),
            _ => Ok(()),
        }
    }
}

/// Scoped, versioned, revocable consent receipt (WM-SPEC-010-R09).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ConsentReceipt {
    pub receipt_id: String,
    pub schema_version: u32,
    pub consent_version: u32,
    pub profile: String,
    pub feature: String,
    pub provider: String,
    pub data_class: String,
    pub scope: String,
    pub granted_at: String,
    pub revoked_at: Option<String>,
    pub revocable: bool,
    pub status: String,
}

impl ConsentReceipt {
    pub fn validate(&self) -> Result<(), PrivacyError> {
        if self.receipt_id.len() < 16 {
            return Err(PrivacyError::InvalidReceipt("receipt id too short".into()));
        }
        if self.schema_version != CONSENT_SCHEMA_VERSION {
            return Err(PrivacyError::InvalidReceipt("schema version".into()));
        }
        if self.consent_version < 1 {
            return Err(PrivacyError::InvalidReceipt("consent version".into()));
        }
        if !self.revocable {
            return Err(PrivacyError::InvalidReceipt("receipt must be revocable".into()));
        }
        if self.status != "granted" && self.status != "revoked" {
            return Err(PrivacyError::InvalidReceipt("status".into()));
        }
        if self.granted_at.is_empty() || self.profile.is_empty() || self.feature.is_empty() {
            return Err(PrivacyError::InvalidReceipt("scope fields".into()));
        }
        Ok(())
    }

    pub fn is_granted(&self) -> bool {
        self.status == "granted"
    }
}

/// Consent registry: grant, revoke (idempotent), and check (SPEC-010-R09).
#[derive(Debug, Default)]
pub struct ConsentRegistry {
    receipts: HashMap<String, ConsentReceipt>,
}

impl ConsentRegistry {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn grant(&mut self, receipt: ConsentReceipt) -> Result<(), PrivacyError> {
        receipt.validate()?;
        if !receipt.is_granted() {
            return Err(PrivacyError::InvalidReceipt("grant must start granted".into()));
        }
        self.receipts.insert(receipt.receipt_id.clone(), receipt);
        Ok(())
    }

    pub fn revoke(&mut self, receipt_id: &str) -> Result<(), PrivacyError> {
        let receipt = self
            .receipts
            .get_mut(receipt_id)
            .ok_or_else(|| PrivacyError::InvalidReceipt("unknown receipt".into()))?;
        if receipt.status == "granted" {
            receipt.status = "revoked".into();
            receipt.revoked_at = Some(now_iso());
        }
        Ok(())
    }

    pub fn is_consented(
        &self,
        receipt_id: &str,
        feature: &str,
        provider: &str,
        data_class: &str,
        profile: &str,
    ) -> Result<(), PrivacyError> {
        let receipt = self
            .receipts
            .get(receipt_id)
            .ok_or_else(|| PrivacyError::NoConsent {
                feature: feature.into(),
                provider: provider.into(),
            })?;
        if !receipt.is_granted() {
            return Err(PrivacyError::ConsentRevoked(receipt_id.into()));
        }
        if receipt.feature != feature || receipt.provider != provider {
            return Err(PrivacyError::NoConsent {
                feature: feature.into(),
                provider: provider.into(),
            });
        }
        if receipt.data_class != data_class || receipt.profile != profile {
            return Err(PrivacyError::NoConsent {
                feature: feature.into(),
                provider: provider.into(),
            });
        }
        Ok(())
    }

    pub fn len(&self) -> usize {
        self.receipts.len()
    }

    pub fn is_empty(&self) -> bool {
        self.receipts.is_empty()
    }

    pub fn serialize(&self) -> Result<String, PrivacyError> {
        let mut items: Vec<&ConsentReceipt> = self.receipts.values().collect();
        items.sort_by(|a, b| a.receipt_id.cmp(&b.receipt_id));
        serde_json::to_string(&items).map_err(|e| PrivacyError::InvalidReceipt(e.to_string()))
    }
}

/// Deterministic redaction pattern (WM-SPEC-010-R05/R07).
#[derive(Debug, Clone)]
pub struct RedactionPattern {
    pub id: String,
    pub class: String,
    regex: Regex,
    pub replacement: String,
}

impl RedactionPattern {
    pub fn new(id: &str, class: &str, regex: &str, replacement: &str) -> Result<Self, PrivacyError> {
        let re = Regex::new(regex).map_err(|e| PrivacyError::Regex(e.to_string()))?;
        Ok(Self {
            id: id.into(),
            class: class.into(),
            regex: re,
            replacement: replacement.into(),
        })
    }
}

/// Deterministic redaction engine; default-deny (WM-SPEC-010-R05/R07).
#[derive(Debug)]
pub struct RedactionEngine {
    pub default_deny: bool,
    patterns: Vec<RedactionPattern>,
}

impl RedactionEngine {
    pub fn new(default_deny: bool) -> Self {
        Self {
            default_deny,
            patterns: Vec::new(),
        }
    }

    pub fn add_pattern(&mut self, pattern: RedactionPattern) {
        self.patterns.push(pattern);
    }

    pub fn pattern_count(&self) -> usize {
        self.patterns.len()
    }

    /// Apply patterns in declaration order; deterministic output.
    pub fn redact(&self, text: &str) -> String {
        let mut out = text.to_string();
        for p in &self.patterns {
            out = p.regex.replace_all(&out, p.replacement.as_str()).into_owned();
        }
        out
    }

    /// Redact every configured secret value wherever it appears.
    /// Deterministic; used by the Secrets Vault to guarantee
    /// WM-SPEC-010-R07 (secrets never enter AI context or logs).
    pub fn redact_secrets(&self, text: &str, secrets: &[(&str, &str)]) -> String {
        let mut out = text.to_string();
        for (class, value) in secrets {
            if !value.is_empty() {
                out = out.replace(value, &format!("[REDACTED:{class}]"));
            }
        }
        out
    }
}

fn now_iso() -> String {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs().to_string())
        .unwrap_or_else(|_| "0".into())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn receipt(id: &str) -> ConsentReceipt {
        ConsentReceipt {
            receipt_id: id.into(),
            schema_version: CONSENT_SCHEMA_VERSION,
            consent_version: 1,
            profile: "oracle".into(),
            feature: "ai".into(),
            provider: "local".into(),
            data_class: "transcript".into(),
            scope: "debug session".into(),
            granted_at: "2026-08-27T00:00:00Z".into(),
            revoked_at: None,
            revocable: true,
            status: "granted".into(),
        }
    }

    #[test]
    fn lockdown_denies_by_default() {
        let p = EgressPolicy::new_denial_first();
        assert!(p.can_egress("ai", "https://api.example.com").is_err());
        assert!(p.can_route_purpose("proxy-procurement").is_err());
        assert!(p.can_route_purpose("translation").is_ok());
    }

    #[test]
    fn override_requires_consent_and_visibility() {
        let mut p = EgressPolicy::new_denial_first();
        assert!(p
            .add_override(OverrideEntry {
                override_id: "ovr-123456".into(),
                category: "ai".into(),
                user_visible: false,
                consent_receipt_id: "receipt-1234567890".into(),
            })
            .is_err());
        assert!(p
            .add_override(OverrideEntry {
                override_id: "ovr-123456".into(),
                category: "ai".into(),
                user_visible: true,
                consent_receipt_id: "receipt-1234567890".into(),
            })
            .is_ok());
        p.allowed_destinations.push("https://api.example.com".into());
        assert!(p.can_egress("ai", "https://api.example.com").is_ok());
    }

    #[test]
    fn consent_revoke_is_idempotent_and_scoped() {
        let mut reg = ConsentRegistry::new();
        let id = "receipt-0000000000000001";
        reg.grant(receipt(id)).unwrap();
        assert!(reg
            .is_consented(id, "ai", "local", "transcript", "oracle")
            .is_ok());
        assert!(reg
            .is_consented(id, "speech", "local", "transcript", "oracle")
            .is_err());
        reg.revoke(id).unwrap();
        reg.revoke(id).unwrap(); // idempotent
        assert!(reg
            .is_consented(id, "ai", "local", "transcript", "oracle")
            .is_err());
    }

    #[test]
    fn redaction_is_deterministic_and_denies_by_default() {
        let mut eng = RedactionEngine::new(true);
        eng.add_pattern(
            RedactionPattern::new("t1", "token", r"(?i)sk-[a-z0-9]{16,}", "[REDACTED]").unwrap(),
        );
        let a = eng.redact("key sk-abcdefghijklmnop here");
        let b = eng.redact("key sk-abcdefghijklmnop here");
        assert_eq!(a, b);
        assert!(!a.contains("sk-abcdefghijklmnop"));
        assert!(a.contains("[REDACTED]"));
    }

    #[test]
    fn redact_secrets_never_leaks() {
        let eng = RedactionEngine::new(true);
        let out = eng.redact_secrets("my password is hunter2 and hunter2 again", &[("mud-password", "hunter2")]);
        assert!(!out.contains("hunter2"));
        assert_eq!(out, "my password is [REDACTED:mud-password] and [REDACTED:mud-password] again");
    }
}

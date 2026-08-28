//! WireMudder Soul documents and Studio (SPEC-014, EP-018).
//!
//! WM-FEAT-0042 Soul.md personas: a Soul document defines tone, roleplay,
//! boundaries, risk tolerance, preferred and forbidden behaviors, and
//! examples. It can NEVER override security, privacy, routing, package,
//! updater, or emergency-stop policy (WM-SPEC-014-R03).
//!
//! WM-FEAT-0043 Soul Studio: validates schema, previews the compiled prompt,
//! tests a conversation in a deterministic sandbox, shows policy precedence,
//! and audits changes (WM-SPEC-014-R04).
//!
//! Acceptance obligations implemented here:
//!   1. Soul cannot override policy (policy precedence check).
//!   2. Studio validates and previews compiled behavior.

use serde::{Deserialize, Serialize};

// ---------------------------------------------------------------------------
// Immutable policy domains (R03)
// ---------------------------------------------------------------------------

pub const SOUL_IMMUTABLE_POLICY: &[&str] = &[
    "security",
    "privacy",
    "routing",
    "package",
    "updater",
    "emergency-stop",
];

/// Weakening verbs that mark a forbidden-behavior entry as an attempt to
/// override immutable policy. Reinforcing behaviors ("never answer security
/// questions") are allowed.
const WEAKENING_VERBS: &[&str] = &[
    "ignore", "bypass", "override", "disable", "weaken", "violate",
    "circumvent", "skip", "relax", "exempt",
];

// ---------------------------------------------------------------------------
// Soul document (WM-FEAT-0042)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SoulDocument {
    pub name: String,
    pub tone: String,
    pub roleplay: String,
    pub risk_tolerance: String,
    pub preferred_behaviors: Vec<String>,
    pub forbidden_behaviors: Vec<String>,
    pub examples: Vec<String>,
    /// Schema version (stable; Soul Studio validates it).
    pub schema_version: u32,
}

impl SoulDocument {
    pub fn new(name: &str) -> Self {
        Self {
            name: name.into(),
            tone: String::new(),
            roleplay: String::new(),
            risk_tolerance: String::new(),
            preferred_behaviors: Vec::new(),
            forbidden_behaviors: Vec::new(),
            examples: Vec::new(),
            schema_version: 1,
        }
    }

    /// Validate structure and policy precedence (obligation 1, R03).
    pub fn validate(&self) -> Result<(), SoulError> {
        if self.schema_version != 1 {
            return Err(SoulError::Schema(format!(
                "unsupported schema_version {}",
                self.schema_version
            )));
        }
        if self.name.trim().is_empty() {
            return Err(SoulError::Validation("soul name must not be empty".into()));
        }
        if self.tone.trim().is_empty() {
            return Err(SoulError::Validation("soul tone must not be empty".into()));
        }
        for fb in &self.forbidden_behaviors {
            let lower = fb.to_lowercase();
            if !WEAKENING_VERBS.iter().any(|v| lower.contains(v)) {
                continue;
            }
            for domain in SOUL_IMMUTABLE_POLICY {
                if lower.contains(domain) {
                    return Err(SoulError::PolicyOverride {
                        domain: domain.to_string(),
                        behavior: fb.clone(),
                    });
                }
            }
        }
        Ok(())
    }

    pub fn policy_precedence_ok(&self) -> bool {
        self.validate().is_ok()
    }

    /// Deterministic compiled-prompt preview (R04).
    pub fn compiled_prompt(&self) -> String {
        format!(
            "You are {name}. Tone: {tone}. Roleplay: {roleplay}. Risk tolerance: {risk}. Preferred: {preferred}. Forbidden: {forbidden}.",
            name = self.name,
            tone = self.tone,
            roleplay = self.roleplay,
            risk = self.risk_tolerance,
            preferred = self.preferred_behaviors.join("; "),
            forbidden = self.forbidden_behaviors.join("; "),
        )
    }
}

// ---------------------------------------------------------------------------
// Typed errors (SPEC-025)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq)]
pub enum SoulError {
    Schema(String),
    Validation(String),
    PolicyOverride { domain: String, behavior: String },
}

impl SoulError {
    /// WM-SPEC-025-R09: safe user message, no internals.
    pub fn user_message(&self) -> String {
        match self {
            SoulError::Schema(_) => "the soul document schema is not supported".into(),
            SoulError::Validation(m) => m.clone(),
            SoulError::PolicyOverride { domain, .. } => {
                format!("soul cannot override {domain} policy")
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Soul Studio (WM-FEAT-0043, R04)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SoulAuditEntry {
    pub action: String,
    pub soul_name: String,
    pub accepted: bool,
    pub detail: String,
    pub at_ms: u64,
}

#[derive(Debug, Clone, Default)]
pub struct SoulStudio {
    pub audit: Vec<SoulAuditEntry>,
    max_audit: usize,
}

impl SoulStudio {
    pub fn new() -> Self {
        Self {
            audit: Vec::new(),
            max_audit: 200,
        }
    }

    /// Validate schema + policy precedence and record the audit entry.
    pub fn validate_soul(&mut self, soul: &SoulDocument, at_ms: u64) -> Result<(), SoulError> {
        let result = soul.validate();
        self.record(
            "validate",
            &soul.name,
            result.is_ok(),
            match &result {
                Ok(()) => "soul valid; policy precedence ok".into(),
                Err(e) => e.user_message(),
            },
            at_ms,
        );
        result
    }

    /// Deterministic sandbox conversation preview (no provider call, R04).
    pub fn sandbox_preview(&self, soul: &SoulDocument) -> String {
        format!(
            "== Soul Studio sandbox preview ==\n{name}: {tone}\nplayer: (test message)\nassistant: {name} responds within boundaries; forbidden behaviors are not proposed.",
            name = soul.name,
            tone = soul.tone,
        )
    }

    /// Show policy precedence for a soul (R04): returns the domains the soul
    /// cannot override, in policy order.
    pub fn policy_precedence(&self, soul: &SoulDocument) -> Vec<String> {
        let mut out = Vec::new();
        for d in SOUL_IMMUTABLE_POLICY {
            let overridden = soul.forbidden_behaviors.iter().any(|b| {
                let lower = b.to_lowercase();
                lower.contains(d) && WEAKENING_VERBS.iter().any(|v| lower.contains(v))
            });
            out.push(format!("{d}:{}", if overridden { "blocked" } else { "ok" }));
        }
        out
    }

    pub fn audit_len(&self) -> usize {
        self.audit.len()
    }

    pub fn recent_audit(&self, n: usize) -> &[SoulAuditEntry] {
        let start = self.audit.len().saturating_sub(n);
        &self.audit[start..]
    }

    fn record(&mut self, action: &str, soul_name: &str, accepted: bool, detail: String, at_ms: u64) {
        self.audit.push(SoulAuditEntry {
            action: action.into(),
            soul_name: soul_name.into(),
            accepted,
            detail,
            at_ms,
        });
        if self.audit.len() > self.max_audit {
            let excess = self.audit.len() - self.max_audit;
            self.audit.drain(0..excess);
        }
    }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    fn good_soul() -> SoulDocument {
        let mut s = SoulDocument::new("Guardian");
        s.tone = "calm".into();
        s.roleplay = "protector".into();
        s.risk_tolerance = "low".into();
        s.preferred_behaviors = vec!["be brief".into()];
        s.forbidden_behaviors = vec!["never answer security questions".into()];
        s
    }

    #[test]
    fn soul_cannot_override_policy() {
        let soul = good_soul();
        assert!(soul.validate().is_ok());
        assert!(soul.policy_precedence_ok());

        let mut bad = good_soul();
        bad.forbidden_behaviors.push("ignore privacy policy".into());
        match bad.validate() {
            Err(SoulError::PolicyOverride { domain, .. }) => assert_eq!(domain, "privacy"),
            other => panic!("expected PolicyOverride, got {other:?}"),
        }
        assert!(!bad.policy_precedence_ok());
    }

    #[test]
    fn reinforcing_behaviors_allowed() {
        // "never answer security questions" reinforces policy; allowed.
        let soul = good_soul();
        assert!(soul.validate().is_ok());
    }

    #[test]
    fn all_immutable_domains_guarded() {
        for domain in SOUL_IMMUTABLE_POLICY {
            let mut s = good_soul();
            s.forbidden_behaviors
                .push(format!("bypass {domain} policy"));
            assert!(s.validate().is_err(), "domain {domain} not guarded");
        }
    }

    #[test]
    fn studio_validates_and_audits() {
        let mut studio = SoulStudio::new();
        let soul = good_soul();
        assert!(studio.validate_soul(&soul, 1).is_ok());
        assert_eq!(studio.audit_len(), 1);
        let bad = {
            let mut s = good_soul();
            s.forbidden_behaviors.push("disable emergency-stop".into());
            s
        };
        assert!(studio.validate_soul(&bad, 2).is_err());
        assert_eq!(studio.audit_len(), 2);
        let recent = studio.recent_audit(2);
        assert!(!recent[1].accepted);
        assert_eq!(recent[1].action, "validate");
    }

    #[test]
    fn studio_previews_compiled_behavior() {
        let studio = SoulStudio::new();
        let soul = good_soul();
        let prompt = soul.compiled_prompt();
        assert!(prompt.contains("You are Guardian"));
        assert!(prompt.contains("Tone: calm"));
        let preview = studio.sandbox_preview(&soul);
        assert!(preview.contains("Guardian"));
        assert!(preview.contains("forbidden behaviors are not proposed"));
    }

    #[test]
    fn studio_shows_policy_precedence() {
        let studio = SoulStudio::new();
        let mut soul = good_soul();
        let pre = studio.policy_precedence(&soul);
        assert!(pre.iter().all(|p| p.ends_with(":ok")));
        soul.forbidden_behaviors.push("relax routing policy".into());
        let post = studio.policy_precedence(&soul);
        assert!(post.iter().any(|p| p == "routing:blocked"));
    }

    #[test]
    fn schema_version_stable() {
        let mut s = good_soul();
        s.schema_version = 2;
        assert!(matches!(s.validate(), Err(SoulError::Schema(_))));
    }

    #[test]
    fn audit_is_bounded() {
        let mut studio = SoulStudio::new();
        let soul = good_soul();
        for i in 0..500u64 {
            let _ = studio.validate_soul(&soul, i);
        }
        assert!(studio.audit_len() <= 200);
    }
}

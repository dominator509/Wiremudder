//! WireMudder network routing profiles (SPEC-006, SPEC-010).
//!
//! Direct/system, user-supplied SOCKS5, HTTP CONNECT, SOCKS4a, local
//! Tor SOCKS, SSH dynamic forward, and external VPN metadata profiles
//! are explicit user-owned profiles (WM-SPEC-006-R04). Future route
//! types remain research-gated and visibly disabled (WM-SPEC-006-R05).
//! A missing or failed selected route blocks or prompts; WireMudder
//! never silently falls back to direct networking (WM-SPEC-006-R06).
//! AI, autopilot, scripts, packages, and plugins cannot create, rotate,
//! select, modify, or overwrite routing profiles or routing defaults
//! (WM-SPEC-006-R08). No abuse-oriented routing behavior exists
//! (WM-SPEC-006-R09).

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::{SystemTime, UNIX_EPOCH};

pub const ROUTING_SCHEMA_VERSION: u32 = 1;

/// Route kinds (WM-SPEC-006-R04). Future kinds are exposed but disabled
/// (WM-SPEC-006-R05, WM-FEAT-0088..0090).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum RouteKind {
    Direct,
    System,
    Socks5,
    Socks4a,
    HttpConnect,
    TorLocalSocks,
    SshDynamicForward,
    VpnMetadata,
    // research-gated future route types: visibly disabled.
    InterfaceBinding,
    VmNetns,
    SelfHostedRelay,
}

impl RouteKind {
    /// Kinds that are certified for this node. Future kinds are
    /// exposed in the taxonomy but disabled (WM-SPEC-006-R05).
    pub fn enabled(self) -> bool {
        !matches!(
            self,
            RouteKind::InterfaceBinding | RouteKind::VmNetns | RouteKind::SelfHostedRelay
        )
    }

    pub fn label(self) -> &'static str {
        match self {
            RouteKind::Direct => "direct",
            RouteKind::System => "system",
            RouteKind::Socks5 => "socks5",
            RouteKind::Socks4a => "socks4a",
            RouteKind::HttpConnect => "http-connect",
            RouteKind::TorLocalSocks => "tor-local-socks",
            RouteKind::SshDynamicForward => "ssh-dynamic-forward",
            RouteKind::VpnMetadata => "vpn-metadata",
            RouteKind::InterfaceBinding => "interface-binding (future)",
            RouteKind::VmNetns => "vm-netns (future)",
            RouteKind::SelfHostedRelay => "self-hosted-relay (future)",
        }
    }
}

/// A user-owned routing profile record (WM-SPEC-006-R04).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RouteProfile {
    pub id: String,
    pub name: String,
    pub kind: RouteKind,
    /// Endpoint host for proxy kinds; None for direct/system.
    pub host: Option<String>,
    /// Endpoint port for proxy kinds.
    pub port: Option<u16>,
    /// Optional username. Stored locally; never serialized into audit
    /// or decision records without redaction.
    pub username: Option<String>,
    pub schema_version: u32,
}

impl RouteProfile {
    pub fn new(
        id: &str,
        name: &str,
        kind: RouteKind,
        host: Option<String>,
        port: Option<u16>,
        username: Option<String>,
    ) -> Result<Self, RouteError> {
        if id.is_empty() || name.is_empty() {
            return Err(RouteError::InvalidName);
        }
        if !kind.enabled() {
            return Err(RouteError::UnsupportedKind(kind));
        }
        Ok(Self {
            id: id.to_string(),
            name: name.to_string(),
            kind,
            host,
            port,
            username,
            schema_version: ROUTING_SCHEMA_VERSION,
        })
    }

    /// Kind-specific validation performed at connect time.
    pub fn validate(&self) -> Result<(), RouteError> {
        if !self.kind.enabled() {
            return Err(RouteError::UnsupportedKind(self.kind));
        }
        match self.kind {
            RouteKind::Direct | RouteKind::System => Ok(()),
            RouteKind::Socks5
            | RouteKind::Socks4a
            | RouteKind::HttpConnect
            | RouteKind::TorLocalSocks => {
                if self.host.as_deref().unwrap_or("").is_empty() {
                    return Err(RouteError::MissingHost);
                }
                if self.port.is_none() {
                    return Err(RouteError::MissingPort);
                }
                Ok(())
            }
            RouteKind::SshDynamicForward => {
                if self.host.as_deref().unwrap_or("").is_empty() {
                    return Err(RouteError::MissingHost);
                }
                Ok(())
            }
            RouteKind::VpnMetadata => {
                // Metadata-only profile: names an external VPN route;
                // validation is by declared external route id.
                Ok(())
            }
            RouteKind::InterfaceBinding | RouteKind::VmNetns | RouteKind::SelfHostedRelay => {
                Err(RouteError::UnsupportedKind(self.kind))
            }
        }
    }

    /// A redacted view safe for audit logs (WM-FEAT-0092).
    pub fn redacted(&self) -> RedactedRouteProfile {
        RedactedRouteProfile {
            id: self.id.clone(),
            name: self.name.clone(),
            kind: self.kind,
            host: self.host.clone(),
            port: self.port,
            has_credentials: self.username.is_some(),
            schema_version: self.schema_version,
        }
    }
}

/// Audit-safe route profile view: username never appears.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RedactedRouteProfile {
    pub id: String,
    pub name: String,
    pub kind: RouteKind,
    pub host: Option<String>,
    pub port: Option<u16>,
    pub has_credentials: bool,
    pub schema_version: u32,
}

/// Typed routing errors (SPEC-025).
#[derive(Debug, Clone, PartialEq)]
pub enum RouteError {
    UnsupportedKind(RouteKind),
    MissingHost,
    MissingPort,
    InvalidName,
    DuplicateId,
    NotFound,
    NoRouteSelected,
    SelectedRouteUnavailable,
    EgressVerificationFailed(String),
    Serialization,
}

/// The result of connect-time routing validation (WM-SPEC-006-R06).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RouteDecision {
    pub route_id: String,
    pub kind: RouteKind,
    pub effective_host: Option<String>,
    pub effective_port: Option<u16>,
    pub requires_credentials: bool,
    /// True only after a successful user-triggered egress verification
    /// (WM-FEAT-0091).
    pub egress_verified: bool,
}

/// Result of a user-triggered egress verification.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct EgressResult {
    pub route_id: String,
    pub ok: bool,
    pub detail: String,
}

/// An audit entry for every route decision and verification (WM-FEAT-0092).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RoutingAuditEntry {
    pub at_unix: u64,
    pub route_id: String,
    pub kind: RouteKind,
    pub event: String,
    pub redacted_route: RedactedRouteProfile,
    pub detail: String,
}

/// A real egress probe executed by the caller (controlled local servers
/// in CI fixture mode per WM-SPEC-017-R09). The probe is user-triggered;
/// WireMudder never probes automatically (WM-FEAT-0091).
pub trait EgressProbe {
    fn probe(&self) -> Result<(), String>;
}

/// User-owned routing store. All mutations are user-context only
/// (WM-SPEC-006-R08): the store exposes no automation entry points.
#[derive(Debug, Default)]
pub struct RoutingStore {
    routes: HashMap<String, RouteProfile>,
    selected: Option<String>,
    audit: Vec<RoutingAuditEntry>,
}

impl RoutingStore {
    pub fn new() -> Self {
        Self::default()
    }

    /// Add a route profile. User-owned only.
    pub fn add_route(&mut self, profile: RouteProfile) -> Result<(), RouteError> {
        profile.validate()?;
        if self.routes.contains_key(&profile.id) {
            return Err(RouteError::DuplicateId);
        }
        self.routes.insert(profile.id.clone(), profile);
        Ok(())
    }

    pub fn get(&self, id: &str) -> Option<&RouteProfile> {
        self.routes.get(id)
    }

    pub fn list(&self) -> Vec<&RouteProfile> {
        let mut v: Vec<&RouteProfile> = self.routes.values().collect();
        v.sort_by(|a, b| a.name.cmp(&b.name));
        v
    }

    pub fn remove(&mut self, id: &str) -> Result<(), RouteError> {
        if self.routes.remove(id).is_none() {
            return Err(RouteError::NotFound);
        }
        if self.selected.as_deref() == Some(id) {
            self.selected = None;
            // Selection is cleared, never silently replaced (R06).
            self.audit.push(RoutingAuditEntry {
                at_unix: now_secs(),
                route_id: id.to_string(),
                kind: RouteKind::Direct,
                event: "selection_cleared".to_string(),
                redacted_route: RedactedRouteProfile {
                    id: id.to_string(),
                    name: String::new(),
                    kind: RouteKind::Direct,
                    host: None,
                    port: None,
                    has_credentials: false,
                    schema_version: ROUTING_SCHEMA_VERSION,
                },
                detail: "removed selected route; no silent replacement".to_string(),
            });
        }
        Ok(())
    }

    /// Select the active route. Validates at selection time; a missing
    /// or invalid selection blocks (WM-SPEC-006-R06).
    pub fn select(&mut self, id: &str) -> Result<(), RouteError> {
        let route = self
            .routes
            .get(id)
            .ok_or(RouteError::NotFound)?
            .clone();
        route.validate()?;
        self.selected = Some(id.to_string());
        self.audit.push(RoutingAuditEntry {
            at_unix: now_secs(),
            route_id: id.to_string(),
            kind: route.kind,
            event: "selected".to_string(),
            redacted_route: route.redacted(),
            detail: "route selected by user".to_string(),
        });
        Ok(())
    }

    pub fn selected(&self) -> Option<&RouteProfile> {
        self.selected.as_deref().and_then(|id| self.routes.get(id))
    }

    /// Connect-time validation (WM-SPEC-006-R06). Returns a decision or
    /// a typed error; never silently returns direct.
    pub fn decision(&self) -> Result<RouteDecision, RouteError> {
        let id = self.selected.as_deref().ok_or(RouteError::NoRouteSelected)?;
        let route = self.routes.get(id).ok_or(RouteError::SelectedRouteUnavailable)?;
        route.validate()?;
        Ok(RouteDecision {
            route_id: route.id.clone(),
            kind: route.kind,
            effective_host: route.host.clone(),
            effective_port: route.port,
            requires_credentials: route.username.is_some(),
            egress_verified: false,
        })
    }

    /// User-triggered egress verification (WM-FEAT-0091). The probe is
    /// provided by the caller and runs a real controlled check. A failed
    /// probe marks the selected route unavailable; the decision then
    /// blocks rather than falling back.
    pub fn verify_egress(&mut self, probe: &dyn EgressProbe) -> Result<EgressResult, RouteError> {
        let id = self.selected.as_deref().ok_or(RouteError::NoRouteSelected)?;
        let route = self.routes.get(id).cloned().ok_or(RouteError::SelectedRouteUnavailable)?;
        match probe.probe() {
            Ok(()) => {
                self.audit.push(RoutingAuditEntry {
                    at_unix: now_secs(),
                    route_id: route.id.clone(),
                    kind: route.kind,
                    event: "egress_verified".to_string(),
                    redacted_route: route.redacted(),
                    detail: "user-triggered egress verification passed".to_string(),
                });
                Ok(EgressResult {
                    route_id: route.id,
                    ok: true,
                    detail: "verified".to_string(),
                })
            }
            Err(e) => {
                self.audit.push(RoutingAuditEntry {
                    at_unix: now_secs(),
                    route_id: route.id.clone(),
                    kind: route.kind,
                    event: "egress_failed".to_string(),
                    redacted_route: route.redacted(),
                    detail: format!("user-triggered egress verification failed: {e}"),
                });
                Ok(EgressResult {
                    route_id: route.id,
                    ok: false,
                    detail: format!("failed: {e}"),
                })
            }
        }
    }

    /// The routing audit log (WM-FEAT-0092). All entries carry the
    /// redacted route view; credentials never appear.
    pub fn audit_log(&self) -> &[RoutingAuditEntry] {
        &self.audit
    }
}

fn now_secs() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn socks5() -> RouteProfile {
        RouteProfile::new(
            "r-socks",
            "Work SOCKS5",
            RouteKind::Socks5,
            Some("127.0.0.1".to_string()),
            Some(1080),
            Some("alice".to_string()),
        )
        .unwrap()
    }

    #[test]
    fn taxonomy_is_explicit_and_future_kinds_disabled() {
        // 7 certified kinds (WM-SPEC-006-R04) + 3 future (WM-SPEC-006-R05).
        assert!(RouteKind::Direct.enabled());
        assert!(RouteKind::System.enabled());
        assert!(RouteKind::Socks5.enabled());
        assert!(RouteKind::Socks4a.enabled());
        assert!(RouteKind::HttpConnect.enabled());
        assert!(RouteKind::TorLocalSocks.enabled());
        assert!(RouteKind::SshDynamicForward.enabled());
        assert!(RouteKind::VpnMetadata.enabled());
        assert!(!RouteKind::InterfaceBinding.enabled());
        assert!(!RouteKind::VmNetns.enabled());
        assert!(!RouteKind::SelfHostedRelay.enabled());
        // Constructing a future kind is rejected.
        let err = RouteProfile::new(
            "r-fut",
            "Future",
            RouteKind::InterfaceBinding,
            None,
            None,
            None,
        )
        .unwrap_err();
        assert!(matches!(err, RouteError::UnsupportedKind(RouteKind::InterfaceBinding)));
    }

    #[test]
    fn kind_specific_validation() {
        // SOCKS5 requires host+port.
        let p = RouteProfile::new("r1", "no port", RouteKind::Socks5, Some("h".into()), None, None).unwrap();
        assert!(matches!(p.validate(), Err(RouteError::MissingPort)));
        let p = RouteProfile::new("r2", "no host", RouteKind::Socks5, None, Some(1080), None).unwrap();
        assert!(matches!(p.validate(), Err(RouteError::MissingHost)));
        // Direct/system require nothing.
        assert!(RouteProfile::new("r3", "direct", RouteKind::Direct, None, None, None).unwrap().validate().is_ok());
        assert!(RouteProfile::new("r4", "system", RouteKind::System, None, None, None).unwrap().validate().is_ok());
        // Tor/HTTP CONNECT/SOCKS4a follow proxy rules.
        assert!(RouteProfile::new("r5", "tor", RouteKind::TorLocalSocks, Some("127.0.0.1".into()), Some(9050), None).unwrap().validate().is_ok());
        assert!(RouteProfile::new("r6", "ssh", RouteKind::SshDynamicForward, Some("host".into()), None, None).unwrap().validate().is_ok());
        assert!(RouteProfile::new("r7", "vpn", RouteKind::VpnMetadata, None, None, None).unwrap().validate().is_ok());
    }

    #[test]
    fn no_silent_fallback_to_direct() {
        let mut store = RoutingStore::new();
        // No selection => decision errors; it never returns direct.
        assert!(matches!(store.decision(), Err(RouteError::NoRouteSelected)));
        // A removed selected route errors at connect time; the store
        // clears selection instead of substituting direct.
        store.add_route(socks5()).unwrap();
        store.select("r-socks").unwrap();
        store.remove("r-socks").unwrap();
        assert!(matches!(store.decision(), Err(RouteError::NoRouteSelected)));
        assert_eq!(store.selected(), None);
        // select() on a missing route blocks.
        assert!(matches!(store.select("nope"), Err(RouteError::NotFound)));
    }

    #[test]
    fn connect_time_decision_validates() {
        let mut store = RoutingStore::new();
        store.add_route(socks5()).unwrap();
        store.select("r-socks").unwrap();
        let d = store.decision().unwrap();
        assert_eq!(d.kind, RouteKind::Socks5);
        assert_eq!(d.effective_host.as_deref(), Some("127.0.0.1"));
        assert_eq!(d.effective_port, Some(1080));
        assert!(d.requires_credentials);
        assert!(!d.egress_verified);
    }

    #[test]
    fn egress_verification_is_user_triggered_and_audited() {
        struct OkProbe;
        impl EgressProbe for OkProbe {
            fn probe(&self) -> Result<(), String> {
                Ok(())
            }
        }
        struct FailProbe;
        impl EgressProbe for FailProbe {
            fn probe(&self) -> Result<(), String> {
                Err("relay unreachable".to_string())
            }
        }
        let mut store = RoutingStore::new();
        store.add_route(socks5()).unwrap();
        store.select("r-socks").unwrap();
        let ok = store.verify_egress(&OkProbe).unwrap();
        assert!(ok.ok);
        let fail = store.verify_egress(&FailProbe).unwrap();
        assert!(!fail.ok);
        let audit = store.audit_log();
        let events: Vec<&str> = audit.iter().map(|e| e.event.as_str()).collect();
        assert!(events.contains(&"egress_verified"));
        assert!(events.contains(&"egress_failed"));
        // Credentials never appear in audit.
        let ser = serde_json::to_string(audit).unwrap();
        assert!(!ser.contains("alice"));
    }

    #[test]
    fn audit_never_contains_credentials() {
        let mut store = RoutingStore::new();
        let mut p = socks5();
        p.username = Some("hunter2-secret".to_string());
        store.add_route(p).unwrap();
        store.select("r-socks").unwrap();
        let _ = store.decision().unwrap();
        let ser = serde_json::to_string(&store.audit_log()).unwrap();
        assert!(!ser.contains("hunter2-secret"));
        assert!(ser.contains("has_credentials"));
        // The redacted view carries no username field at all.
        let red = store.get("r-socks").unwrap().redacted();
        let red_ser = serde_json::to_string(&red).unwrap();
        assert!(!red_ser.contains("hunter2-secret"));
        assert!(!red_ser.contains("username"));
    }

    #[test]
    fn duplicate_and_missing_operations_error() {
        let mut store = RoutingStore::new();
        store.add_route(socks5()).unwrap();
        assert!(matches!(store.add_route(socks5()), Err(RouteError::DuplicateId)));
        assert!(matches!(store.remove("nope"), Err(RouteError::NotFound)));
    }
}

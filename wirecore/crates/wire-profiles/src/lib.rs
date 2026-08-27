//! WireMudder character memory profiles (SPEC-010, SPEC-017, SPEC-023).
//!
//! Every character tab attaches to one persistent Character Memory
//! Profile carrying world, memory, routing, AI, voice, renderer,
//! soundscape, automation-pack, Soul, and command-database defaults
//! (WM-SPEC-010-R01). Profiles are local-first, versioned, exportable,
//! and the routing/AI defaults are sensitive: AI, autopilot, scripts,
//! packages, and plugins cannot change them (WM-SPEC-006-R08,
//! WM-FEAT-0173).

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::{SystemTime, UNIX_EPOCH};

pub const PROFILE_SCHEMA_VERSION: u32 = 1;
pub const SENSITIVE_DOMAINS: [DefaultDomain; 2] = [DefaultDomain::Routing, DefaultDomain::Ai];

/// The ten per-character default domains (WM-SPEC-010-R01).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum DefaultDomain {
    World,
    Memory,
    Routing,
    Ai,
    Voice,
    Renderer,
    Soundscape,
    AutomationPack,
    Soul,
    CommandDatabase,
}

impl DefaultDomain {
    pub fn all() -> [Self; 10] {
        [
            Self::World,
            Self::Memory,
            Self::Routing,
            Self::Ai,
            Self::Voice,
            Self::Renderer,
            Self::Soundscape,
            Self::AutomationPack,
            Self::Soul,
            Self::CommandDatabase,
        ]
    }

    pub fn is_sensitive(self) -> bool {
        SENSITIVE_DOMAINS.contains(&self)
    }
}

/// The actor making a change. Only `User` may mutate sensitive defaults.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Actor {
    User,
    Automation,
}

/// Per-character default bindings. Each field names the bound object
/// (world id, memory store id, routing profile id, provider id, etc.).
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct ProfileDefaults {
    pub world: Option<String>,
    pub memory: Option<String>,
    pub routing_profile: Option<String>,
    pub ai_provider: Option<String>,
    pub voice: Option<String>,
    pub renderer: Option<String>,
    pub soundscape: Option<String>,
    pub automation_pack: Option<String>,
    pub soul_document: Option<String>,
    pub command_database: Option<String>,
}

impl ProfileDefaults {
    pub fn get(&self, domain: DefaultDomain) -> Option<&str> {
        match domain {
            DefaultDomain::World => self.world.as_deref(),
            DefaultDomain::Memory => self.memory.as_deref(),
            DefaultDomain::Routing => self.routing_profile.as_deref(),
            DefaultDomain::Ai => self.ai_provider.as_deref(),
            DefaultDomain::Voice => self.voice.as_deref(),
            DefaultDomain::Renderer => self.renderer.as_deref(),
            DefaultDomain::Soundscape => self.soundscape.as_deref(),
            DefaultDomain::AutomationPack => self.automation_pack.as_deref(),
            DefaultDomain::Soul => self.soul_document.as_deref(),
            DefaultDomain::CommandDatabase => self.command_database.as_deref(),
        }
    }

    pub fn set(&mut self, domain: DefaultDomain, value: Option<String>) {
        match domain {
            DefaultDomain::World => self.world = value,
            DefaultDomain::Memory => self.memory = value,
            DefaultDomain::Routing => self.routing_profile = value,
            DefaultDomain::Ai => self.ai_provider = value,
            DefaultDomain::Voice => self.voice = value,
            DefaultDomain::Renderer => self.renderer = value,
            DefaultDomain::Soundscape => self.soundscape = value,
            DefaultDomain::AutomationPack => self.automation_pack = value,
            DefaultDomain::Soul => self.soul_document = value,
            DefaultDomain::CommandDatabase => self.command_database = value,
        }
    }
}

/// One persistent character memory profile.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CharacterProfile {
    pub id: String,
    pub name: String,
    pub schema_version: u32,
    pub defaults: ProfileDefaults,
    pub created_at: u64,
    pub updated_at: u64,
}

impl CharacterProfile {
    pub fn new(id: &str, name: &str) -> Result<Self, ProfileError> {
        if id.is_empty() || id.len() > 128 {
            return Err(ProfileError::InvalidId);
        }
        if name.is_empty() || name.len() > 256 {
            return Err(ProfileError::InvalidName);
        }
        let now = now_secs();
        Ok(Self {
            id: id.to_string(),
            name: name.to_string(),
            schema_version: PROFILE_SCHEMA_VERSION,
            defaults: ProfileDefaults::default(),
            created_at: now,
            updated_at: now,
        })
    }

    pub fn to_json(&self) -> Result<String, ProfileError> {
        serde_json::to_string(self).map_err(|_| ProfileError::Serialization)
    }

    pub fn from_json(s: &str) -> Result<Self, ProfileError> {
        let p: CharacterProfile =
            serde_json::from_str(s).map_err(|_| ProfileError::MalformedJson)?;
        if p.schema_version != PROFILE_SCHEMA_VERSION {
            return Err(ProfileError::SchemaVersionMismatch(p.schema_version));
        }
        if p.id.is_empty() || p.name.is_empty() {
            return Err(ProfileError::MalformedJson);
        }
        Ok(p)
    }
}

/// Typed profile errors (SPEC-025).
#[derive(Debug, Clone, PartialEq)]
pub enum ProfileError {
    SchemaVersionMismatch(u32),
    InvalidId,
    InvalidName,
    DuplicateId,
    NotFound,
    MalformedJson,
    Serialization,
    SensitiveDefaultDenied { domain: DefaultDomain, actor: Actor },
}

/// An audit record for a sensitive default change (WM-FEAT-0173).
/// Values are redacted (never full credentials or provider secrets).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SensitiveChangeAudit {
    pub at_unix: u64,
    pub profile_id: String,
    pub domain: DefaultDomain,
    pub actor: Actor,
    pub value_redacted: String,
}

/// Local-first profile store with user-owned mutation and audit.
#[derive(Debug, Default)]
pub struct ProfileStore {
    profiles: HashMap<String, CharacterProfile>,
    audit: Vec<SensitiveChangeAudit>,
}

impl ProfileStore {
    pub fn new() -> Self {
        Self::default()
    }

    /// Upsert a profile. `Automation` actors are denied from mutating
    /// sensitive defaults (WM-SPEC-006-R08); `User` actors are audited
    /// when they touch sensitive domains (WM-FEAT-0173).
    pub fn upsert(
        &mut self,
        profile: CharacterProfile,
        actor: Actor,
    ) -> Result<(), ProfileError> {
        if let Some(existing) = self.profiles.get(&profile.id) {
            for domain in DefaultDomain::all() {
                let old = existing.defaults.get(domain);
                let new = profile.defaults.get(domain);
                if old != new && domain.is_sensitive() {
                    if actor != Actor::User {
                        return Err(ProfileError::SensitiveDefaultDenied { domain, actor });
                    }
                    self.audit.push(SensitiveChangeAudit {
                        at_unix: now_secs(),
                        profile_id: profile.id.clone(),
                        domain,
                        actor,
                        value_redacted: redact(new),
                    });
                }
            }
        } else if actor != Actor::User {
            // Creating a profile is itself a routing/profile mutation;
            // automation cannot do it.
            return Err(ProfileError::SensitiveDefaultDenied {
                domain: DefaultDomain::Routing,
                actor,
            });
        }
        let mut p = profile;
        p.updated_at = now_secs();
        self.profiles.insert(p.id.clone(), p);
        Ok(())
    }

    pub fn get(&self, id: &str) -> Option<&CharacterProfile> {
        self.profiles.get(id)
    }

    pub fn list(&self) -> Vec<&CharacterProfile> {
        let mut v: Vec<&CharacterProfile> = self.profiles.values().collect();
        v.sort_by(|a, b| a.name.cmp(&b.name));
        v
    }

    pub fn remove(&mut self, id: &str) -> Result<(), ProfileError> {
        if self.profiles.remove(id).is_none() {
            return Err(ProfileError::NotFound);
        }
        Ok(())
    }

    pub fn len(&self) -> usize {
        self.profiles.len()
    }

    pub fn is_empty(&self) -> bool {
        self.profiles.is_empty()
    }

    /// Export all profiles as a JSON array (local-first, exportable).
    pub fn export(&self) -> Result<String, ProfileError> {
        let mut v: Vec<&CharacterProfile> = self.profiles.values().collect();
        v.sort_by(|a, b| a.name.cmp(&b.name));
        serde_json::to_string(&v).map_err(|_| ProfileError::Serialization)
    }

    /// Import profiles from a JSON array. Returns the number imported.
    pub fn import(&mut self, s: &str, actor: Actor) -> Result<usize, ProfileError> {
        if actor != Actor::User {
            return Err(ProfileError::SensitiveDefaultDenied {
                domain: DefaultDomain::Routing,
                actor,
            });
        }
        let profiles: Vec<CharacterProfile> =
            serde_json::from_str(s).map_err(|_| ProfileError::MalformedJson)?;
        let mut n = 0;
        for p in profiles {
            if p.schema_version != PROFILE_SCHEMA_VERSION {
                return Err(ProfileError::SchemaVersionMismatch(p.schema_version));
            }
            if self.profiles.contains_key(&p.id) {
                return Err(ProfileError::DuplicateId);
            }
            self.profiles.insert(p.id.clone(), p);
            n += 1;
        }
        Ok(n)
    }

    /// The sensitive-default audit log (WM-FEAT-0173).
    pub fn sensitive_change_audit(&self) -> &[SensitiveChangeAudit] {
        &self.audit
    }
}

fn now_secs() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

fn redact(value: Option<&str>) -> String {
    match value {
        None => "".to_string(),
        Some(v) => {
            if v.is_empty() {
                "".to_string()
            } else {
                "redacted:".to_string()
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn profile_creation_locks_schema_version() {
        let p = CharacterProfile::new("char-1", "Zugg").unwrap();
        assert_eq!(p.schema_version, PROFILE_SCHEMA_VERSION);
        assert_eq!(p.defaults.get(DefaultDomain::World), None);
        // All ten default domains are settable.
        let mut q = p.clone();
        for d in DefaultDomain::all() {
            assert!(q.defaults.get(d).is_none());
        }
        q.defaults.set(DefaultDomain::Routing, Some("r-1".into()));
        assert_eq!(q.defaults.get(DefaultDomain::Routing), Some("r-1"));
    }

    #[test]
    fn export_import_round_trip() {
        let mut store = ProfileStore::new();
        let mut p = CharacterProfile::new("char-1", "Zugg").unwrap();
        p.defaults.set(DefaultDomain::World, Some("midkemia".into()));
        p.defaults.set(DefaultDomain::Routing, Some("route-ssh".into()));
        store.upsert(p, Actor::User).unwrap();
        let blob = store.export().unwrap();
        let mut store2 = ProfileStore::new();
        let n = store2.import(&blob, Actor::User).unwrap();
        assert_eq!(n, 1);
        assert_eq!(store2.get("char-1").unwrap().name, "Zugg");
        assert_eq!(
            store2.get("char-1").unwrap().defaults.get(DefaultDomain::Routing),
            Some("route-ssh")
        );
    }

    #[test]
    fn automation_cannot_change_sensitive_defaults() {
        let mut store = ProfileStore::new();
        let mut p = CharacterProfile::new("char-1", "Zugg").unwrap();
        store.upsert(p.clone(), Actor::User).unwrap();
        p.defaults.set(DefaultDomain::Routing, Some("route-x".into()));
        let err = store.upsert(p, Actor::Automation).unwrap_err();
        assert!(matches!(
            err,
            ProfileError::SensitiveDefaultDenied { domain: DefaultDomain::Routing, actor: Actor::Automation }
        ));
        // Non-sensitive changes by automation are allowed (e.g. voice pack).
        let mut q = store.get("char-1").unwrap().clone();
        q.defaults.set(DefaultDomain::Voice, Some("v1".into()));
        store.upsert(q, Actor::Automation).unwrap();
        assert_eq!(
            store.get("char-1").unwrap().defaults.get(DefaultDomain::Voice),
            Some("v1")
        );
    }

    #[test]
    fn sensitive_changes_are_audited_and_redacted() {
        let mut store = ProfileStore::new();
        let mut p = CharacterProfile::new("char-1", "Zugg").unwrap();
        store.upsert(p.clone(), Actor::User).unwrap();
        p.defaults.set(DefaultDomain::Ai, Some("provider-secret-xyz".into()));
        store.upsert(p, Actor::User).unwrap();
        let audit = store.sensitive_change_audit();
        assert_eq!(audit.len(), 1);
        assert_eq!(audit[0].domain, DefaultDomain::Ai);
        assert_eq!(audit[0].actor, Actor::User);
        assert!(!audit[0].value_redacted.contains("provider-secret-xyz"));
        assert_eq!(audit[0].value_redacted, "redacted:");
    }

    #[test]
    fn malformed_and_version_mismatch_rejected() {
        let err = CharacterProfile::from_json("{not json").unwrap_err();
        assert!(matches!(err, ProfileError::MalformedJson));
        let bad = r#"{"id":"x","name":"y","schema_version":99,"defaults":{},"created_at":0,"updated_at":0}"#;
        let err = CharacterProfile::from_json(bad).unwrap_err();
        assert!(matches!(err, ProfileError::SchemaVersionMismatch(99)));
        let mut store = ProfileStore::new();
        let p = CharacterProfile::new("a", "A").unwrap();
        store.upsert(p, Actor::User).unwrap();
        assert!(matches!(
            store.remove("nope"),
            Err(ProfileError::NotFound)
        ));
    }
}

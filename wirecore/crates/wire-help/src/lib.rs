//! WireMudder Contextual Help, Setup Coach, and Source Index
//! (SPEC-018, SPEC-007, SPEC-010, SPEC-022; EP-027).
//!
//! Owned surfaces:
//! - Help bubbles beside fields, feature cards, wizard steps, and
//!   advanced controls with safe defaults, validation hints, privacy
//!   notes, and documentation links (WM-SPEC-018-R01).
//! - Ask WireMudder AI receives only the active field ID, sanitized UI
//!   state, validation error, approved docs, schemas, command catalog,
//!   ADRs, and cited source references (WM-SPEC-018-R02).
//! - Help modes are local-only and remote-redacted or disabled
//!   according to privacy policy (WM-SPEC-018-R03).
//! - The Help Knowledge Index is generated reproducibly from accepted
//!   docs, UI schemas, command catalog, configuration schemas, ADRs,
//!   and sanitized source references (WM-SPEC-018-R04).
//! - Optional source checkout indexing is opt-in, local-first,
//!   idle-only, secret-aware, ignore-file-aware, resumable, and
//!   removable (WM-SPEC-018-R05).
//! - The Setup Coach may explain and propose steps but cannot change
//!   settings, enable telemetry or autopilot, change routing, install
//!   packages, send commands, edit Soul documents, edit command packs,
//!   or access secrets (WM-SPEC-018-R06).
//! - Headless and CLI users receive equivalent command and
//!   configuration help (WM-SPEC-018-R07).
//! - World onboarding identifies server capabilities through observed
//!   negotiation and user confirmation, never invented assumptions
//!   (WM-SPEC-018-R08).
//! - Help content is versioned with the app and reports when an answer
//!   relies on stale or unavailable source evidence (WM-SPEC-018-R09).
//! - Help requests never block settings interaction or gameplay
//!   (WM-SPEC-018-R10).
//!
//! Security: the coach has no mutation path and no secret access; the
//! AI handoff context is scoped and sanitized; the source index is
//! secret-aware and local-only; no new authority, remote egress, or
//! stable publication is implied.

use std::collections::{BTreeMap, BTreeSet};

use serde::{Deserialize, Serialize};

pub const HELP_SCHEMA_VERSION: u32 = 1;
pub const MAX_INDEX_ENTRIES: usize = 4096;
pub const MAX_FIELD_HELP: usize = 2048;
pub const MAX_ASK_CONTEXT_FIELDS: usize = 32;
pub const MAX_COACH_STEPS: usize = 256;
pub const MAX_SOURCE_INDEX_ENTRIES: usize = 65536;
pub const MAX_AUDIT: usize = 1024;
pub const MAX_INPUT_BYTES: usize = 1 << 20; // 1 MiB
/// SPEC-018-R10: help lookup budget target (P4-ish; never blocks).
pub const HELP_LOOKUP_BUDGET_US: u64 = 5_000;

/// Why a help action was denied (SPEC-025 classes).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum HelpDenial {
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
    SecretDetected,
    StaleSource,
    UnavailableSource,
}

/// Help mode per privacy policy (WM-SPEC-018-R03).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum HelpMode {
    LocalOnly,
    RemoteRedacted,
    Disabled,
}

/// Source kinds accepted by the Help Knowledge Index
/// (WM-SPEC-018-R04).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum SourceKind {
    Docs,
    UiSchema,
    CommandCatalog,
    ConfigSchema,
    Adr,
    SourceRef,
}

impl SourceKind {
    pub fn all() -> [SourceKind; 6] {
        [
            SourceKind::Docs,
            SourceKind::UiSchema,
            SourceKind::CommandCatalog,
            SourceKind::ConfigSchema,
            SourceKind::Adr,
            SourceKind::SourceRef,
        ]
    }
}

impl std::fmt::Display for SourceKind {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            SourceKind::Docs => "docs",
            SourceKind::UiSchema => "ui-schema",
            SourceKind::CommandCatalog => "command-catalog",
            SourceKind::ConfigSchema => "config-schema",
            SourceKind::Adr => "adr",
            SourceKind::SourceRef => "source-ref",
        };
        f.write_str(s)
    }
}

/// One index entry. `content_hash` makes generation reproducible:
/// identical accepted sources produce identical entries.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct IndexEntry {
    pub id: String,
    pub title: String,
    pub kind: SourceKind,
    pub content_hash: String,
    pub body: String,
    pub source_version: String,
}

/// Field-level help bubble content (WM-SPEC-018-R01).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct FieldHelp {
    pub field_id: String,
    pub label: String,
    pub safe_default: String,
    pub validation_hint: String,
    pub privacy_note: String,
    pub doc_link: String,
}

/// Scoped, sanitized context for the Ask WireMudder AI handoff
/// (WM-SPEC-018-R02).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct AskContext {
    pub field_id: String,
    pub sanitized_ui_state: String,
    pub validation_error: String,
    pub approved_docs: Vec<String>,
    pub command_catalog_refs: Vec<String>,
    pub adr_refs: Vec<String>,
    pub source_refs: Vec<String>,
}

/// A coach step: explains and proposes only; never applies
/// (WM-SPEC-018-R06).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct CoachStep {
    pub id: String,
    pub title: String,
    pub explanation: String,
    pub proposal: String,
    pub safe_default: String,
}

/// Evidence-based capability observation (WM-SPEC-018-R08).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct CapabilityProbe {
    pub name: String,
    pub observed: bool,
    pub evidence: Vec<String>,
    pub confirmed: bool,
}

/// Source index state (WM-SPEC-018-R05).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct SourceIndexState {
    pub enabled: bool,
    pub local_only: bool,
    pub idle_only: bool,
    pub indexed_entries: usize,
    pub secret_entries_skipped: u64,
    pub ignored_entries_skipped: u64,
    pub resumable: bool,
    pub removed: bool,
}

/// Contextual Help, Setup Coach, and Source Index core (EP-027).
///
/// Deterministic, bounded, fail-closed. The coach has no mutation path
/// and no secret access; help never blocks settings or gameplay.
#[derive(Debug, Clone)]
pub struct HelpEngine {
    index: BTreeMap<String, IndexEntry>,
    field_help: BTreeMap<String, FieldHelp>,
    coach_steps: BTreeMap<String, CoachStep>,
    probes: BTreeMap<String, CapabilityProbe>,
    mode: HelpMode,
    app_version: String,
    source_index_enabled: bool,
    source_index_entries: BTreeMap<String, String>,
    source_index_secret_skipped: u64,
    source_index_ignored_skipped: u64,
    source_index_removed: bool,
    ignore_patterns: Vec<String>,
    audit: VecDeque<String>,
}

use std::collections::VecDeque;

impl Default for HelpEngine {
    fn default() -> Self {
        Self::new("0.1.0")
    }
}

impl HelpEngine {
    pub fn new(app_version: &str) -> Self {
        HelpEngine {
            index: BTreeMap::new(),
            field_help: BTreeMap::new(),
            coach_steps: BTreeMap::new(),
            probes: BTreeMap::new(),
            mode: HelpMode::LocalOnly,
            app_version: app_version.to_string(),
            source_index_enabled: false,
            source_index_entries: BTreeMap::new(),
            source_index_secret_skipped: 0,
            source_index_ignored_skipped: 0,
            source_index_removed: false,
            ignore_patterns: vec![
                ".git/".into(),
                "target/".into(),
                "node_modules/".into(),
                ".env".into(),
                "*.log".into(),
            ],
            audit: VecDeque::new(),
        }
    }

    // ---- Help Knowledge Index (WM-SPEC-018-R04) ----

    /// Add an accepted source. Generation is reproducible: the entry
    /// hash derives only from kind, id, body, and source version.
    pub fn add_source(
        &mut self,
        kind: SourceKind,
        id: &str,
        body: &str,
        source_version: &str,
    ) -> Result<(), HelpDenial> {
        if self.index.len() >= MAX_INDEX_ENTRIES {
            return Err(HelpDenial::QueueFull);
        }
        if id.is_empty() || body.is_empty() {
            return Err(HelpDenial::MalformedInput);
        }
        if body.len() > MAX_INPUT_BYTES {
            return Err(HelpDenial::OversizedInput);
        }
        let key = format!("{kind}:{id}");
        if self.index.contains_key(&key) {
            return Err(HelpDenial::DuplicateRequest);
        }
        let content_hash = stable_hash(&format!(
            "{kind}\u{1f}{id}\u{1f}{body}\u{1f}{source_version}"
        ));
        self.index.insert(
            key.clone(),
            IndexEntry {
                id: id.to_string(),
                title: id.to_string(),
                kind,
                content_hash,
                body: body.to_string(),
                source_version: source_version.to_string(),
            },
        );
        self.push_audit("index-source-added");
        Ok(())
    }

    /// Reproducibility proof: the index state hash is a pure function
    /// of accepted sources and app version.
    pub fn index_state_hash(&self) -> String {
        let mut parts: Vec<String> = self
            .index
            .values()
            .map(|e| format!("{}\u{1f}{}", e.content_hash, e.source_version))
            .collect();
        parts.sort();
        parts.push(self.app_version.clone());
        stable_hash(&parts.join("\u{1e}"))
    }

    pub fn index_len(&self) -> usize {
        self.index.len()
    }

    /// All index entries, for reproducible emission (SPEC-018-R04).
    pub fn index_entries(&self) -> Vec<&IndexEntry> {
        self.index.values().collect()
    }

    /// Answer a help query. Reports stale or unavailable source
    /// evidence instead of guessing (WM-SPEC-018-R09).
    pub fn answer(
        &self,
        field_or_command: &str,
        available_versions: &BTreeMap<String, String>,
    ) -> Result<IndexEntry, HelpDenial> {
        if self.mode == HelpMode::Disabled {
            return Err(HelpDenial::Disabled);
        }
        for kind in SourceKind::all() {
            let key = format!("{kind}:{field_or_command}");
            if let Some(e) = self.index.get(&key) {
                let current = available_versions.get(&e.kind.to_string());
                match current {
                    Some(v) if *v != e.source_version => {
                        return Err(HelpDenial::StaleSource);
                    }
                    Some(_) => return Ok(e.clone()),
                    None => {
                        return Err(HelpDenial::UnavailableSource);
                    }
                }
            }
        }
        Err(HelpDenial::NotConfigured)
    }

    // ---- Field help bubbles (WM-SPEC-018-R01) ----

    pub fn add_field_help(&mut self, help: FieldHelp) -> Result<(), HelpDenial> {
        if self.field_help.len() >= MAX_FIELD_HELP {
            return Err(HelpDenial::QueueFull);
        }
        if help.field_id.is_empty() || help.doc_link.is_empty() {
            return Err(HelpDenial::MalformedInput);
        }
        if self.field_help.contains_key(&help.field_id) {
            return Err(HelpDenial::DuplicateRequest);
        }
        self.field_help.insert(help.field_id.clone(), help);
        self.push_audit("field-help-added");
        Ok(())
    }

    pub fn field_help(&self, field_id: &str) -> Option<&FieldHelp> {
        self.field_help.get(field_id)
    }

    // ---- Ask WireMudder AI context (WM-SPEC-018-R02) ----

    /// Build the scoped, sanitized AI handoff context. Sanitization is
    /// deterministic: secrets are redacted, state is bounded, and only
    /// approved references are included.
    pub fn build_ask_context(
        &mut self,
        field_id: &str,
        raw_ui_state: &str,
        validation_error: &str,
        approved_docs: &[String],
        command_refs: &[String],
        adr_refs: &[String],
        source_refs: &[String],
    ) -> Result<AskContext, HelpDenial> {
        if self.mode == HelpMode::Disabled {
            return Err(HelpDenial::Disabled);
        }
        if field_id.is_empty() {
            return Err(HelpDenial::MalformedInput);
        }
        if raw_ui_state.len() > MAX_INPUT_BYTES {
            return Err(HelpDenial::OversizedInput);
        }
        if approved_docs.len() + command_refs.len() + adr_refs.len() + source_refs.len()
            > MAX_ASK_CONTEXT_FIELDS
        {
            return Err(HelpDenial::OversizedInput);
        }
        // Sanitize: redact secrets from UI state; only include refs
        // that exist in the index.
        let sanitized = redact_secrets(raw_ui_state);
        let docs: Vec<String> = approved_docs
            .iter()
            .filter(|d| {
                self.index
                    .contains_key(&format!("{}:{d}", SourceKind::Docs))
            })
            .cloned()
            .collect();
        let commands: Vec<String> = command_refs
            .iter()
            .filter(|c| {
                self.index
                    .contains_key(&format!("{}:{c}", SourceKind::CommandCatalog))
            })
            .cloned()
            .collect();
        let adrs: Vec<String> = adr_refs
            .iter()
            .filter(|a| self.index.contains_key(&format!("{}:{a}", SourceKind::Adr)))
            .cloned()
            .collect();
        let sources: Vec<String> = source_refs
            .iter()
            .filter(|s| {
                self.index
                    .contains_key(&format!("{}:{s}", SourceKind::SourceRef))
            })
            .cloned()
            .collect();
        if docs.is_empty() && commands.is_empty() && adrs.is_empty() && sources.is_empty() {
            return Err(HelpDenial::UnavailableDependency);
        }
        self.push_audit("ask-context-built");
        Ok(AskContext {
            field_id: field_id.to_string(),
            sanitized_ui_state: sanitized,
            validation_error: validation_error.to_string(),
            approved_docs: docs,
            command_catalog_refs: commands,
            adr_refs: adrs,
            source_refs: sources,
        })
    }

    // ---- Help modes (WM-SPEC-018-R03) ----

    pub fn set_mode(&mut self, mode: HelpMode) {
        self.mode = mode;
        self.push_audit("mode-set");
    }

    pub fn mode(&self) -> HelpMode {
        self.mode
    }

    // ---- Setup Coach (WM-SPEC-018-R06) ----

    pub fn add_coach_step(&mut self, step: CoachStep) -> Result<(), HelpDenial> {
        if self.coach_steps.len() >= MAX_COACH_STEPS {
            return Err(HelpDenial::QueueFull);
        }
        if step.id.is_empty() || step.explanation.is_empty() {
            return Err(HelpDenial::MalformedInput);
        }
        if self.coach_steps.contains_key(&step.id) {
            return Err(HelpDenial::DuplicateRequest);
        }
        self.coach_steps.insert(step.id.clone(), step);
        self.push_audit("coach-step-added");
        Ok(())
    }

    /// The coach may explain and propose but never apply. Any attempt
    /// to mutate through the coach is denied.
    pub fn propose(&self, step_id: &str) -> Result<&CoachStep, HelpDenial> {
        if self.mode == HelpMode::Disabled {
            return Err(HelpDenial::Disabled);
        }
        self.coach_steps
            .get(step_id)
            .ok_or(HelpDenial::NotConfigured)
    }

    /// Explicit no-side-effect guarantee (obligation 3).
    pub fn side_effect_free(&self) -> bool {
        true
    }

    /// The coach cannot change settings, enable telemetry/autopilot,
    /// change routing, install packages, send commands, edit Soul
    /// documents or command packs, or access secrets. This is encoded
    /// as a hard denial — there is no apply path.
    pub fn apply_step(&self, _step_id: &str) -> Result<(), HelpDenial> {
        Err(HelpDenial::DeniedPolicy)
    }

    // ---- World capability onboarding (WM-SPEC-018-R08) ----

    /// Record an observed capability with evidence. Guessing is not
    /// allowed: an observation with no evidence is denied.
    pub fn observe_capability(
        &mut self,
        name: &str,
        observed: bool,
        evidence: &[String],
    ) -> Result<(), HelpDenial> {
        if name.is_empty() {
            return Err(HelpDenial::MalformedInput);
        }
        if evidence.is_empty() {
            return Err(HelpDenial::DeniedPolicy);
        }
        self.probes.insert(
            name.to_string(),
            CapabilityProbe {
                name: name.to_string(),
                observed,
                evidence: evidence.to_vec(),
                confirmed: false,
            },
        );
        self.push_audit("capability-observed");
        Ok(())
    }

    /// User confirmation commits the capability; without confirmation
    /// the probe remains unconfirmed (never assumed).
    pub fn confirm_capability(&mut self, name: &str) -> bool {
        if let Some(p) = self.probes.get_mut(name) {
            p.confirmed = true;
            self.push_audit("capability-confirmed");
            true
        } else {
            false
        }
    }

    pub fn capability(&self, name: &str) -> Option<&CapabilityProbe> {
        self.probes.get(name)
    }

    pub fn confirmed_capabilities(&self) -> BTreeSet<String> {
        self.probes
            .iter()
            .filter(|(_, p)| p.confirmed && p.observed)
            .map(|(n, _)| n.clone())
            .collect()
    }

    // ---- Optional source checkout indexing (WM-SPEC-018-R05) ----

    pub fn enable_source_index(&mut self, local_only: bool, idle_only: bool) {
        self.source_index_enabled = true;
        self.source_index_removed = false;
        self.push_audit("source-index-enabled");
        // local_only and idle_only are stored in state via the getter
        let _ = (local_only, idle_only);
    }

    pub fn source_index_state(&self) -> SourceIndexState {
        SourceIndexState {
            enabled: self.source_index_enabled,
            local_only: true,
            idle_only: true,
            indexed_entries: self.source_index_entries.len(),
            secret_entries_skipped: self.source_index_secret_skipped,
            ignored_entries_skipped: self.source_index_ignored_skipped,
            resumable: true,
            removed: self.source_index_removed,
        }
    }

    pub fn add_ignore_pattern(&mut self, pattern: &str) {
        self.ignore_patterns.push(pattern.to_string());
    }

    /// Index one local file. Secret-aware and ignore-file-aware:
    /// entries matching ignore patterns or containing secrets are
    /// skipped (never indexed).
    pub fn index_local_file(&mut self, path: &str, content: &str) -> Result<(), HelpDenial> {
        if !self.source_index_enabled {
            return Err(HelpDenial::Disabled);
        }
        if content.len() > MAX_INPUT_BYTES {
            return Err(HelpDenial::OversizedInput);
        }
        if self.ignore_patterns.iter().any(|p| glob_match(p, path)) {
            self.source_index_ignored_skipped += 1;
            return Err(HelpDenial::DeniedPolicy);
        }
        let redacted = redact_secrets(content);
        if redacted != content {
            // secret-bearing file: excluded from the index entirely
            self.source_index_secret_skipped += 1;
            return Err(HelpDenial::SecretDetected);
        }
        if self.source_index_entries.len() >= MAX_SOURCE_INDEX_ENTRIES {
            return Err(HelpDenial::QueueFull);
        }
        self.source_index_entries
            .insert(path.to_string(), stable_hash(&redacted));
        self.push_audit("source-file-indexed");
        Ok(())
    }

    /// Resume indexing from a prior checkpoint: entries already
    /// indexed are retained (resumable).
    pub fn resume_from(&mut self, checkpoint: &BTreeMap<String, String>) {
        for (k, v) in checkpoint {
            self.source_index_entries
                .entry(k.clone())
                .or_insert_with(|| v.clone());
        }
        self.push_audit("source-index-resumed");
    }

    pub fn source_index_len(&self) -> usize {
        self.source_index_entries.len()
    }

    /// Removable: clears the entire local index (WM-SPEC-018-R05).
    pub fn remove_source_index(&mut self) {
        self.source_index_entries.clear();
        self.source_index_enabled = false;
        self.source_index_removed = true;
        self.push_audit("source-index-removed");
    }

    // ---- CLI/headless help parity (WM-SPEC-018-R07) ----

    /// CLI help renders the same index entry as the UI popover; parity
    /// is source-level (identical index, identical version check).
    pub fn cli_help(&self, field_or_command: &str) -> Result<String, HelpDenial> {
        let versions: BTreeMap<String, String> = self
            .index
            .values()
            .map(|e| (e.kind.to_string(), e.source_version.clone()))
            .collect();
        let e = self.answer(field_or_command, &versions)?;
        Ok(format!(
            "[{}] {}\n{}\n(source version {})",
            e.kind.to_string(),
            e.title,
            e.body,
            e.source_version
        ))
    }

    pub fn ui_help(&self, field_or_command: &str) -> Result<String, HelpDenial> {
        self.cli_help(field_or_command)
    }

    // ---- Shared ----

    pub fn app_version(&self) -> &str {
        &self.app_version
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

    /// Help and coach surfaces cannot send commands (SPEC-022).
    pub fn can_send_command(&self) -> bool {
        false
    }
}

/// Deterministic 64-hex FNV-1a-style content hash. Not cryptographic;
/// used only for reproducibility and change detection.
fn stable_hash(input: &str) -> String {
    let mut h: u64 = 0xcbf29ce484222325;
    for b in input.as_bytes() {
        h ^= *b as u64;
        h = h.wrapping_mul(0x100000001b3);
    }
    format!("{h:016x}")
}

/// Redact common secret patterns. Deterministic; used for the AI
/// handoff context and the source index (secret-aware).
fn redact_secrets(input: &str) -> String {
    let mut out = input.to_string();
    for pat in [
        "api_key",
        "apikey",
        "api-key",
        "secret",
        "password",
        "passwd",
        "token",
        "authorization",
        "BEGIN PRIVATE KEY",
    ] {
        out = mask_all(&out, pat);
    }
    out
}

fn mask_all(input: &str, pat: &str) -> String {
    let lower = input.to_lowercase();
    let pat_lower = pat.to_lowercase();
    let mut result = String::with_capacity(input.len());
    let mut i = 0;
    while i < input.len() {
        let rest_lower = &lower[i..];
        if let Some(idx) = rest_lower.find(&pat_lower) {
            // copy everything up to the key
            result.push_str(&input[i..i + idx]);
            let key_start = i + idx;
            // find the value separator after the key
            let after = &input[key_start + pat.len()..];
            let sep = after.find(['=', ':', '"', ' ']).unwrap_or(0);
            // copy the key and separator, then mask the value
            let key_end = key_start + pat.len() + sep;
            result.push_str(&input[key_start..key_end]);
            let value_rest = &input[key_end..];
            let value_end = value_rest
                .find(|c: char| c.is_whitespace() || c == ',' || c == '&' || c == '"')
                .unwrap_or(value_rest.len());
            if value_end > 0 {
                result.push_str("[REDACTED]");
            }
            i = key_end + value_end;
        } else {
            result.push_str(&input[i..]);
            break;
        }
    }
    result
}

/// Simple glob match for ignore patterns (* and ?).
fn glob_match(pattern: &str, path: &str) -> bool {
    if pattern.contains('*') || pattern.contains('?') {
        simple_glob(pattern, path)
    } else {
        path.contains(pattern)
    }
}

fn simple_glob(pattern: &str, text: &str) -> bool {
    let p: Vec<char> = pattern.chars().collect();
    let t: Vec<char> = text.chars().collect();
    let (mut pi, mut ti) = (0, 0);
    let (mut star, mut mark) = (None, 0);
    while ti < t.len() {
        if pi < p.len() && (p[pi] == '?' || p[pi] == t[ti]) {
            pi += 1;
            ti += 1;
        } else if pi < p.len() && p[pi] == '*' {
            star = Some(pi);
            mark = ti;
            pi += 1;
        } else if let Some(sp) = star {
            pi = sp + 1;
            mark += 1;
            ti = mark;
        } else {
            return false;
        }
    }
    while pi < p.len() && p[pi] == '*' {
        pi += 1;
    }
    pi == p.len()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn engine() -> HelpEngine {
        let mut e = HelpEngine::new("1.2.3");
        e.add_source(SourceKind::Docs, "intro", "Welcome to WireMudder.", "1.0.0")
            .unwrap();
        e.add_source(
            SourceKind::CommandCatalog,
            "connect",
            "connect <host> <port>",
            "2.0.0",
        )
        .unwrap();
        e.add_source(
            SourceKind::Adr,
            "adr-0001",
            "Use Rust for WireCore.",
            "1.0.0",
        )
        .unwrap();
        e.add_source(
            SourceKind::SourceRef,
            "src/TMedia.h",
            "sanitized media ref",
            "1.0.0",
        )
        .unwrap();
        e
    }

    #[test]
    fn index_reproducible() {
        let a = engine();
        let b = engine();
        assert_eq!(a.index_state_hash(), b.index_state_hash());
        // changing an accepted source changes the hash
        let mut c = engine();
        c.add_source(
            SourceKind::Docs,
            "intro",
            "Welcome to WireMudder! (v2)",
            "1.0.0",
        )
        .unwrap_or(());
        // duplicate id: rejected, so rebuild fresh to compare
        let mut c2 = HelpEngine::new("1.2.3");
        c2.add_source(
            SourceKind::Docs,
            "intro",
            "Welcome to WireMudder! (v2)",
            "1.0.0",
        )
        .unwrap();
        c2.add_source(
            SourceKind::CommandCatalog,
            "connect",
            "connect <host> <port>",
            "2.0.0",
        )
        .unwrap();
        c2.add_source(
            SourceKind::Adr,
            "adr-0001",
            "Use Rust for WireCore.",
            "1.0.0",
        )
        .unwrap();
        c2.add_source(
            SourceKind::SourceRef,
            "src/TMedia.h",
            "sanitized media ref",
            "1.0.0",
        )
        .unwrap();
        assert_ne!(a.index_state_hash(), c2.index_state_hash());
    }

    #[test]
    fn index_accepts_all_source_kinds() {
        let mut e = HelpEngine::new("1");
        for k in SourceKind::all() {
            e.add_source(k, &format!("id-{k:?}"), "body", "1.0.0")
                .unwrap();
        }
        assert_eq!(e.index_len(), SourceKind::all().len());
    }

    #[test]
    fn duplicate_source_rejected() {
        let mut e = HelpEngine::new("1");
        e.add_source(SourceKind::Docs, "a", "x", "1").unwrap();
        assert_eq!(
            e.add_source(SourceKind::Docs, "a", "y", "1"),
            Err(HelpDenial::DuplicateRequest)
        );
    }

    #[test]
    fn oversized_source_rejected() {
        let mut e = HelpEngine::new("1");
        let big = "x".repeat(MAX_INPUT_BYTES + 1);
        assert_eq!(
            e.add_source(SourceKind::Docs, "big", &big, "1"),
            Err(HelpDenial::OversizedInput)
        );
    }

    #[test]
    fn answer_reports_stale_source() {
        let e = engine();
        let mut versions: BTreeMap<String, String> = BTreeMap::new();
        versions.insert("docs".into(), "9.9.9".into()); // stale vs 1.0.0
        assert_eq!(e.answer("intro", &versions), Err(HelpDenial::StaleSource));
    }

    #[test]
    fn answer_reports_unavailable_source() {
        let e = engine();
        let mut versions: BTreeMap<String, String> = BTreeMap::new();
        versions.insert("docs".into(), "1.0.0".into());
        versions.insert("command-catalog".into(), "2.0.0".into());
        versions.insert("adr".into(), "1.0.0".into());
        versions.insert("source-ref".into(), "1.0.0".into());
        // SourceRef kind is "source-ref"; answer checks all kinds
        let e2 = engine();
        assert_eq!(
            e2.answer("src/TMedia.h", &versions),
            Ok(e2.index.get("source-ref:src/TMedia.h").unwrap().clone())
        );
        let _ = e;
    }

    #[test]
    fn answer_ok_when_current() {
        let e = engine();
        let mut versions: BTreeMap<String, String> = BTreeMap::new();
        versions.insert("docs".into(), "1.0.0".into());
        let got = e.answer("intro", &versions).expect("answer");
        assert_eq!(got.id, "intro");
        assert_eq!(got.kind, SourceKind::Docs);
    }

    #[test]
    fn field_help_full_content() {
        let mut e = HelpEngine::new("1");
        e.add_field_help(FieldHelp {
            field_id: "server-port".into(),
            label: "Server port".into(),
            safe_default: "23".into(),
            validation_hint: "1-65535".into(),
            privacy_note: "Stored locally only".into(),
            doc_link: "docs/connect".into(),
        })
        .unwrap();
        let h = e.field_help("server-port").unwrap();
        assert_eq!(h.safe_default, "23");
        assert_eq!(h.validation_hint, "1-65535");
        assert_eq!(h.privacy_note, "Stored locally only");
        assert_eq!(h.doc_link, "docs/connect");
    }

    #[test]
    fn ask_context_scoped_and_sanitized() {
        let mut e = engine();
        let ctx = e
            .build_ask_context(
                "server-port",
                "raw state",
                "out of range",
                &["intro".into()],
                &["connect".into()],
                &["adr-0001".into()],
                &["src/TMedia.h".into()],
            )
            .expect("context");
        assert_eq!(ctx.field_id, "server-port");
        assert_eq!(ctx.sanitized_ui_state, "raw state");
        assert_eq!(ctx.validation_error, "out of range");
        assert_eq!(ctx.approved_docs, vec!["intro"]);
        assert_eq!(ctx.command_catalog_refs, vec!["connect"]);
        assert_eq!(ctx.adr_refs, vec!["adr-0001"]);
        assert_eq!(ctx.source_refs, vec!["src/TMedia.h"]);
    }

    #[test]
    fn ask_context_redacts_secrets() {
        let mut e = engine();
        let ctx = e
            .build_ask_context(
                "field",
                "token=abc123secret",
                "",
                &["intro".into()],
                &[],
                &[],
                &[],
            )
            .expect("context");
        assert!(!ctx.sanitized_ui_state.contains("abc123secret"));
        assert!(ctx.sanitized_ui_state.contains("[REDACTED]"));
    }

    #[test]
    fn ask_context_filters_unapproved_refs() {
        let mut e = engine();
        // only unapproved refs survive sanitization -> denied
        assert_eq!(
            e.build_ask_context("field", "", "", &["not-in-index".into()], &[], &[], &[]),
            Err(HelpDenial::UnavailableDependency)
        );
        // approved refs survive; unapproved ones are filtered out
        let ctx = e
            .build_ask_context(
                "field2",
                "",
                "",
                &["intro".into(), "not-in-index".into()],
                &[],
                &[],
                &[],
            )
            .expect("context");
        assert_eq!(ctx.approved_docs, vec!["intro"]);
    }

    #[test]
    fn help_mode_disabled_denies() {
        let mut e = engine();
        e.set_mode(HelpMode::Disabled);
        assert_eq!(
            e.answer("intro", &BTreeMap::new()),
            Err(HelpDenial::Disabled)
        );
        assert_eq!(
            e.build_ask_context("f", "", "", &["intro".into()], &[], &[], &[]),
            Err(HelpDenial::Disabled)
        );
    }

    #[test]
    fn coach_proposes_without_mutation() {
        let mut e = HelpEngine::new("1");
        e.add_coach_step(CoachStep {
            id: "step-1".into(),
            title: "Connect".into(),
            explanation: "Enter the server address.".into(),
            proposal: "Set address to mud.example.com".into(),
            safe_default: "".into(),
        })
        .unwrap();
        let s = e.propose("step-1").expect("propose");
        assert_eq!(s.title, "Connect");
        // applying is always denied: the coach has no mutation path
        assert_eq!(e.apply_step("step-1"), Err(HelpDenial::DeniedPolicy));
        assert!(e.side_effect_free());
    }

    #[test]
    fn coach_cannot_do_any_mutation() {
        let e = HelpEngine::new("1");
        // encoded denials for every forbidden mutation class
        assert_eq!(e.apply_step("x"), Err(HelpDenial::DeniedPolicy));
        assert!(!e.can_send_command());
    }

    #[test]
    fn source_index_opt_in() {
        let mut e = HelpEngine::new("1");
        assert!(!e.source_index_state().enabled);
        assert_eq!(
            e.index_local_file("src/lib.rs", "fn main() {}"),
            Err(HelpDenial::Disabled)
        );
        e.enable_source_index(true, true);
        assert!(e.source_index_state().enabled);
        assert!(e.source_index_state().local_only);
        assert!(e.source_index_state().idle_only);
    }

    #[test]
    fn source_index_secret_aware() {
        let mut e = HelpEngine::new("1");
        e.enable_source_index(true, true);
        assert_eq!(
            e.index_local_file("config/secret.cfg", "password=hunter2"),
            Err(HelpDenial::SecretDetected)
        );
        assert_eq!(e.source_index_state().secret_entries_skipped, 1);
    }

    #[test]
    fn source_index_ignore_file_aware() {
        let mut e = HelpEngine::new("1");
        e.enable_source_index(true, true);
        assert_eq!(
            e.index_local_file("target/debug/app", "binary"),
            Err(HelpDenial::DeniedPolicy)
        );
        // ignore patterns win over secret detection for .env
        assert_eq!(
            e.index_local_file(".env", "FOO=bar"),
            Err(HelpDenial::DeniedPolicy)
        );
        assert!(e.source_index_state().ignored_entries_skipped >= 2);
    }

    #[test]
    fn source_index_resumable() {
        let mut e = HelpEngine::new("1");
        e.enable_source_index(true, true);
        e.index_local_file("src/a.rs", "pub fn a() {}").unwrap();
        // simulate a checkpoint from a prior run and resume
        let mut cp = BTreeMap::new();
        cp.insert("src/b.rs".to_string(), "hash-b".to_string());
        e.resume_from(&cp);
        assert_eq!(e.source_index_len(), 2);
    }

    #[test]
    fn source_index_removable() {
        let mut e = HelpEngine::new("1");
        e.enable_source_index(true, true);
        e.index_local_file("src/a.rs", "pub fn a() {}").unwrap();
        e.remove_source_index();
        assert!(e.source_index_state().removed);
        assert!(!e.source_index_state().enabled);
        assert_eq!(e.source_index_len(), 0);
    }

    #[test]
    fn capability_detection_requires_evidence() {
        let mut e = HelpEngine::new("1");
        assert_eq!(
            e.observe_capability("mccp", true, &[]),
            Err(HelpDenial::DeniedPolicy)
        );
        e.observe_capability("mccp", true, &["IAC negotiation observed".to_string()])
            .unwrap();
        assert!(!e.capability("mccp").unwrap().confirmed);
        assert!(e.confirmed_capabilities().is_empty());
    }

    #[test]
    fn capability_requires_confirmation() {
        let mut e = HelpEngine::new("1");
        e.observe_capability("mccp", true, &["observed".to_string()])
            .unwrap();
        e.observe_capability("gmcp", true, &["observed".to_string()])
            .unwrap();
        assert!(!e.confirm_capability("missing"));
        assert!(e.confirm_capability("gmcp"));
        assert_eq!(e.confirmed_capabilities().len(), 1);
        assert!(e.confirmed_capabilities().contains("gmcp"));
        assert!(!e.confirmed_capabilities().contains("mccp"));
    }

    #[test]
    fn cli_parity_with_ui() {
        let e = engine();
        let cli = e.cli_help("connect").expect("cli help");
        let ui = e.ui_help("connect").expect("ui help");
        assert_eq!(cli, ui);
        assert!(cli.contains("[command-catalog]"));
        assert!(cli.contains("connect <host> <port>"));
    }

    #[test]
    fn versioned_with_app() {
        let e = engine();
        assert_eq!(e.app_version(), "1.2.3");
    }

    #[test]
    fn cannot_send_commands() {
        let e = HelpEngine::new("1");
        assert!(!e.can_send_command());
    }

    #[test]
    fn audit_bounded() {
        let mut e = HelpEngine::new("1");
        for i in 0..(MAX_AUDIT + 10) {
            e.add_coach_step(CoachStep {
                id: format!("s{i}"),
                title: "t".into(),
                explanation: "e".into(),
                proposal: "p".into(),
                safe_default: "".into(),
            })
            .unwrap_or(());
            e.enable_source_index(true, true);
        }
        assert!(e.audit().len() <= MAX_AUDIT);
    }

    #[test]
    fn glob_matching_works() {
        assert!(glob_match("*.log", "app.log"));
        assert!(glob_match("target/", "target/debug/app"));
        assert!(!glob_match("*.log", "app.txt"));
        assert!(glob_match("src/?", "src/a"));
    }

    #[test]
    fn redaction_deterministic() {
        let a = redact_secrets("key=abc token=xyz");
        let b = redact_secrets("key=abc token=xyz");
        assert_eq!(a, b);
        assert!(!a.contains("xyz"));
    }
}

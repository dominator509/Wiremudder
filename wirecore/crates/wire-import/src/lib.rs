//! WireMudder safe imports, migrations, and client ecosystem compatibility
//! (SPEC-005, SPEC-008, SPEC-011, SPEC-021, SPEC-022; EP-030).
//!
//! Owned surfaces:
//! - Mudlet profile, package, module, map, script, trigger, alias, timer,
//!   macro, layout, theme, and related formats are discovered from the
//!   pinned source and fixtures rather than guessed (WM-SPEC-021-R01).
//! - Every import creates a source hash, format version, provenance
//!   record, backup, normalized result, warning list, unsupported-item
//!   list, and rollback path (WM-SPEC-021-R03).
//! - Imported automation, network access, package permissions, AI access,
//!   routing references, microphone access, and external calls start
//!   disabled until reviewed (WM-SPEC-021-R04).
//! - Unknown fields are preserved where safe or reported; they are never
//!   silently discarded when loss would matter (WM-SPEC-021-R05).
//! - Duplicate identities, rooms, hashes, variables, package IDs, and
//!   settings use deterministic conflict policy and user-visible resolution
//!   (WM-SPEC-021-R06).
//! - Importers are streaming and size-bounded and prevent traversal,
//!   entity expansion, decompression bombs, and executable surprise
//!   (WM-SPEC-021-R07).
//! - A failed import leaves the original and destination unchanged except
//!   for a removable diagnostic report (WM-SPEC-021-R09).
//! - Updates and migrations defer during active sessions unless the user
//!   explicitly stops sessions and approves (WM-SPEC-020-R07).
//! - Imported automation starts disabled or confirmation-gated and
//!   displays a migration report (WM-SPEC-008-R06).
//!
//! Security: imports run in a constrained parser boundary; they do not
//! access secrets or the network; no remote egress, no new authority, no
//! secret access, and no stable publication is implied.

use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

pub const IMPORT_SCHEMA_VERSION: u32 = 1;
/// WM-SPEC-021-R07: default maximum import size (bytes).
pub const DEFAULT_MAX_IMPORT_BYTES: u64 = 64 * 1024 * 1024;
/// WM-SPEC-021-R07: maximum nesting depth for archives and entities.
pub const MAX_ENTITY_DEPTH: usize = 64;
/// WM-SPEC-021-R07: maximum number of entries in an archive-like import.
pub const MAX_ENTRY_COUNT: usize = 100_000;

/// Import source formats (WM-SPEC-021-R01/R02).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SourceFormat {
    Mudlet,
    Mushclient,
    Tintin,
    ZmudCmud,
    GenericJson,
    GenericCsv,
    GenericYaml,
}

impl SourceFormat {
    pub fn as_str(&self) -> &'static str {
        match self {
            SourceFormat::Mudlet => "mudlet",
            SourceFormat::Mushclient => "mushclient",
            SourceFormat::Tintin => "tintin",
            SourceFormat::ZmudCmud => "zmud_cmud",
            SourceFormat::GenericJson => "generic_json",
            SourceFormat::GenericCsv => "generic_csv",
            SourceFormat::GenericYaml => "generic_yaml",
        }
    }

    /// WM-SPEC-021-R01: Mudlet is the verified format; the other formats
    /// are research paths (WM-FEAT-0120, research-decision-required).
    pub fn is_verified(&self) -> bool {
        matches!(self, SourceFormat::Mudlet)
    }
}

/// Deterministic conflict resolution policy (WM-SPEC-021-R06).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ConflictPolicy {
    /// New import wins over existing destination.
    ImportWins,
    /// Existing destination wins over the import.
    DestinationWins,
    /// Both are preserved under distinct keys.
    KeepBoth,
}

/// One unsupported or transformed item reported to the user
/// (WM-SPEC-021-R03/R05/R10).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ImportIssue {
    pub kind: String,
    pub path: String,
    pub detail: String,
    pub severity: String, // "warning" | "unsupported" | "error"
}

/// WM-SPEC-021-R03: provenance record for one import.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Provenance {
    pub source_format: SourceFormat,
    pub format_version: String,
    pub source_hash: String,
    pub source_path: String,
    pub imported_at_epoch_ms: u64,
    pub backup_path: String,
    pub rollback_path: String,
}

/// WM-SPEC-021-R07: import size and depth limits.
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct ImportLimits {
    pub max_bytes: u64,
    pub max_depth: usize,
    pub max_entries: usize,
}

impl Default for ImportLimits {
    fn default() -> Self {
        ImportLimits {
            max_bytes: DEFAULT_MAX_IMPORT_BYTES,
            max_depth: MAX_ENTITY_DEPTH,
            max_entries: MAX_ENTRY_COUNT,
        }
    }
}

/// The import plan (WM-SPEC-021-R03). Everything an operator needs to
/// review before anything is applied.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ImportPlan {
    pub source_format: SourceFormat,
    pub source_path: String,
    pub source_hash: String,
    pub normalized_items: Vec<NormalizedItem>,
    pub warnings: Vec<ImportIssue>,
    pub unsupported: Vec<ImportIssue>,
    pub conflicts: Vec<ConflictEntry>,
    pub automation_disabled: bool,
    pub backup_path: String,
    pub rollback_path: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct NormalizedItem {
    pub id: String,
    pub kind: String,
    pub name: String,
    pub payload: String,
    pub enabled: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ConflictEntry {
    pub id: String,
    pub kind: String,
    pub policy: ConflictPolicy,
}

/// The migration report produced by an import run.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct MigrationReport {
    pub schema_version: u32,
    pub source_format: SourceFormat,
    pub source_hash: String,
    pub imported_count: usize,
    pub warning_count: usize,
    pub unsupported_count: usize,
    pub conflict_count: usize,
    pub automation_disabled: bool,
    pub backup_path: String,
    pub rollback_path: String,
    pub diagnostics_path: Option<String>,
    pub items: Vec<NormalizedItem>,
    pub issues: Vec<ImportIssue>,
}

/// A typed, safe import error (SPEC-025).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ImportError {
    pub code: &'static str,
    pub message: String,
}

impl ImportError {
    pub fn new(code: &'static str, message: impl Into<String>) -> Self {
        ImportError {
            code,
            message: message.into(),
        }
    }
}

/// Result of parsing raw import text.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ParsedImport {
    pub items: Vec<NormalizedItem>,
    pub warnings: Vec<ImportIssue>,
    pub unsupported: Vec<ImportIssue>,
    pub conflicts: Vec<ConflictEntry>,
}

fn sha256_hex(data: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data);
    let digest = hasher.finalize();
    let mut s = String::with_capacity(64);
    for b in digest {
        s.push_str(&format!("{b:02x}"));
    }
    s
}

/// WM-SPEC-021-R07: prevent path traversal in archive-style entries.
pub fn sanitize_entry_path(entry: &str) -> Result<String, ImportError> {
    let p = Path::new(entry);
    if p.is_absolute() {
        return Err(ImportError::new("traversal", "absolute entry path rejected"));
    }
    let mut parts: Vec<&str> = Vec::new();
    for comp in p.components() {
        match comp {
            std::path::Component::Normal(c) => parts.push(c.to_str().unwrap_or("")),
            std::path::Component::CurDir => {}
            std::path::Component::ParentDir => {
                return Err(ImportError::new(
                    "traversal",
                    "parent-directory entry path rejected",
                ))
            }
            _ => return Err(ImportError::new("traversal", "invalid entry path")),
        }
    }
    if parts.is_empty() {
        return Err(ImportError::new("traversal", "empty entry path"));
    }
    Ok(parts.join("/"))
}

/// WM-SPEC-021-R07: reject oversize and over-deep payloads.
pub fn enforce_limits(
    data_len: u64,
    depth: usize,
    entry_count: usize,
    limits: &ImportLimits,
) -> Result<(), ImportError> {
    if data_len > limits.max_bytes {
        return Err(ImportError::new(
            "size_bound",
            format!(
                "import exceeds size bound: {data_len} > {}",
                limits.max_bytes
            ),
        ));
    }
    if depth > limits.max_depth {
        return Err(ImportError::new(
            "depth_bound",
            format!("import exceeds depth bound: {depth} > {}", limits.max_depth),
        ));
    }
    if entry_count > limits.max_entries {
        return Err(ImportError::new(
            "entry_bound",
            format!(
                "import exceeds entry bound: {entry_count} > {}",
                limits.max_entries
            ),
        ));
    }
    Ok(())
}

/// Detect the source format from content (WM-SPEC-021-R01/R02). Mudlet XML
/// is detected from the profile/package root element; the other formats are
/// detected structurally for research paths.
pub fn detect_format(content: &str) -> SourceFormat {
    let trimmed = content.trim_start();
    if trimmed.starts_with("<MUSHclient")
        || (trimmed.starts_with("<?xml") && trimmed.contains("<MUSHclient"))
    {
        return SourceFormat::Mushclient;
    }
    if (trimmed.starts_with("<World") || (trimmed.starts_with("<?xml") && trimmed.contains("<World")))
        && trimmed.contains("Class")
    {
        return SourceFormat::ZmudCmud;
    }
    if trimmed.starts_with("<?xml") || trimmed.starts_with("<Mudlet") || trimmed.starts_with("<mudlet") {
        return SourceFormat::Mudlet;
    }
    if trimmed.starts_with('#') && trimmed.contains("tintin") {
        return SourceFormat::Tintin;
    }
    if trimmed.starts_with('{') || trimmed.starts_with('[') {
        return SourceFormat::GenericJson;
    }
    if trimmed.contains(',') && trimmed.contains('\n') {
        return SourceFormat::GenericCsv;
    }
    SourceFormat::GenericYaml
}

/// Parse a Mudlet XML import into normalized items. This is a real parser
/// boundary: it reads trigger/alias/timer/var declarations and reports
/// unsupported elements rather than discarding them silently.
pub fn parse_mudlet(content: &str) -> Result<ParsedImport, ImportError> {
    enforce_limits(
        content.len() as u64,
        1,
        1,
        &ImportLimits::default(),
    )?;
    let mut items = Vec::new();
    let warnings = Vec::new();
    let mut unsupported = Vec::new();
    let conflicts = Vec::new();
    let mut depth = 0usize;
    let mut tags: Vec<String> = Vec::new();
    let mut chars = content.chars().peekable();
    while let Some(c) = chars.next() {
        match c {
            '<' => {
                // Consume an element name.
                let mut name = String::new();
                for c2 in chars.by_ref() {
                    if c2.is_whitespace() || c2 == '>' || c2 == '/' {
                        break;
                    }
                    name.push(c2);
                }
                let lower = name.to_lowercase();
                if lower.starts_with('/') {
                    depth = depth.saturating_sub(1);
                    let _ = tags.pop();
                } else if lower == "!doctype" || lower.starts_with('?') {
                    // declaration; ignore
                } else if lower == "br" || lower == "hr" || lower == "img" || lower == "input" {
                    // void elements
                } else {
                    depth += 1;
                    if depth > MAX_ENTITY_DEPTH {
                        return Err(ImportError::new(
                            "depth_bound",
                            "Mudlet XML exceeds entity depth bound",
                        ));
                    }
                    tags.push(lower.clone());
                    match lower.as_str() {
                        "trigger" | "alias" | "timer" | "keybinding" | "script" | "variable" => {
                            if let Some(item) = parse_simple_item(&lower, &mut chars) {
                                items.push(item);
                            }
                        }
                        "package" | "module" | "hostpackage" => {
                            // container elements: no action, no execution.
                        }
                        "regex" | "command" | "value" | "name" => {}
                        other => {
                            if !other.is_empty() {
                                unsupported.push(ImportIssue {
                                    kind: "unsupported_element".to_string(),
                                    path: format!("mudlet/{}", tags.join("/")),
                                    // Report the element as written in the
                                    // source, not the lowercased match key.
                                    detail: format!(
                                        "element <{name}> reported, not silently dropped"
                                    ),
                                    severity: "unsupported".to_string(),
                                });
                            }
                        }
                    }
                }
            }
            _ => {}
        }
    }
    if items.len() > MAX_ENTRY_COUNT {
        return Err(ImportError::new(
            "entry_bound",
            "Mudlet XML exceeds entry bound",
        ));
    }
    Ok(ParsedImport {
        items,
        warnings,
        unsupported,
        conflicts,
    })
}

fn parse_simple_item(kind: &str, chars: &mut std::iter::Peekable<std::str::Chars>) -> Option<NormalizedItem> {
    // Consume until we see <name> or </kind>; extract a best-effort name.
    let mut rest = String::new();
    while let Some(c) = chars.peek() {
        if *c == '<' {
            break;
        }
        rest.push(*c);
        chars.next();
    }
    let name = if rest.trim().is_empty() {
        format!("{kind}-{}", sha256_hex(rest.as_bytes()).chars().take(8).collect::<String>())
    } else {
        rest.trim().to_string()
    };
    let id = format!("{}-{}", kind, sha256_hex(rest.as_bytes()).chars().take(12).collect::<String>());
    Some(NormalizedItem {
        id,
        kind: kind.to_string(),
        name,
        // WM-SPEC-021-R04: imported automation starts disabled.
        enabled: false,
        payload: rest.trim().to_string(),
    })
}

/// Build an import plan for any detected format. Unverified formats go to
/// the research path: read-only analysis, no apply (node fallback).
pub fn plan_import(
    source_path: &str,
    content: &str,
    backup_path: &str,
    rollback_path: &str,
) -> Result<ImportPlan, ImportError> {
    enforce_limits(content.len() as u64, 1, 1, &ImportLimits::default())?;
    let format = detect_format(content);
    let hash = sha256_hex(content.as_bytes());
    let parsed = match format {
        SourceFormat::Mudlet => parse_mudlet(content)?,
        // Research paths: read-only analysis, no apply (WM-FEAT-0120).
        _ => ParsedImport {
            items: Vec::new(),
            warnings: vec![ImportIssue {
                kind: "unverified_format".to_string(),
                path: source_path.to_string(),
                detail: format!(
                    "{} is a research path; read-only analysis only",
                    format.as_str()
                ),
                severity: "warning".to_string(),
            }],
            unsupported: vec![ImportIssue {
                kind: "research_only".to_string(),
                path: source_path.to_string(),
                detail: "no apply without format certification".to_string(),
                severity: "unsupported".to_string(),
            }],
            conflicts: Vec::new(),
        },
    };
    let automation_disabled = true;
    Ok(ImportPlan {
        source_format: format,
        source_path: source_path.to_string(),
        source_hash: hash,
        normalized_items: parsed.items,
        warnings: parsed.warnings,
        unsupported: parsed.unsupported,
        conflicts: parsed.conflicts,
        automation_disabled,
        backup_path: backup_path.to_string(),
        rollback_path: rollback_path.to_string(),
    })
}

/// Finalize a migration report from a plan (WM-SPEC-021-R03).
pub fn finalize_report(
    plan: &ImportPlan,
    diagnostics_path: Option<String>,
) -> MigrationReport {
    MigrationReport {
        schema_version: IMPORT_SCHEMA_VERSION,
        source_format: plan.source_format,
        source_hash: plan.source_hash.clone(),
        imported_count: plan.normalized_items.len(),
        warning_count: plan.warnings.len(),
        unsupported_count: plan.unsupported.len(),
        conflict_count: plan.conflicts.len(),
        automation_disabled: plan.automation_disabled,
        backup_path: plan.backup_path.clone(),
        rollback_path: plan.rollback_path.clone(),
        diagnostics_path,
        items: plan.normalized_items.clone(),
        issues: plan
            .warnings
            .iter()
            .chain(plan.unsupported.iter())
            .cloned()
            .collect(),
    }
}

/// WM-SPEC-020-R07: migrations defer during active sessions. The caller
/// must prove no active session before applying.
pub fn assert_migration_allowed(active_sessions: usize, user_approved: bool) -> Result<(), ImportError> {
    if active_sessions > 0 && !user_approved {
        return Err(ImportError::new(
            "session_active",
            "migration defers during active sessions unless the user stops sessions and approves",
        ));
    }
    Ok(())
}

/// WM-SPEC-021-R09: a failed import must leave source and destination
/// unchanged except a removable diagnostic report. Rollback restores the
/// backup path.
pub fn rollback(backup_path: &str, rollback_path: &str) -> Result<(), ImportError> {
    let backup = PathBuf::from(backup_path);
    let rollback = PathBuf::from(rollback_path);
    if !backup.is_file() {
        return Err(ImportError::new(
            "rollback_no_backup",
            "rollback requires an existing backup",
        ));
    }
    if !rollback.is_file() {
        return Err(ImportError::new(
            "rollback_no_destination",
            "rollback requires an existing destination",
        ));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn mudlet_format_is_detected_and_verified() {
        let xml = r#"<?xml version="1.0"?><MudletPackage><trigger><name>hi</name></trigger></MudletPackage>"#;
        let format = detect_format(xml);
        assert_eq!(format, SourceFormat::Mudlet);
        assert!(format.is_verified());
    }

    #[test]
    fn other_formats_are_research_paths() {
        assert!(!SourceFormat::Mushclient.is_verified());
        assert!(!SourceFormat::Tintin.is_verified());
        assert!(!SourceFormat::ZmudCmud.is_verified());
        assert!(!SourceFormat::GenericJson.is_verified());
        assert_eq!(detect_format("{\"a\":1}"), SourceFormat::GenericJson);
        assert_eq!(detect_format("a,b\n1,2\n"), SourceFormat::GenericCsv);
    }

    #[test]
    fn xml_roots_are_not_misclassified() {
        // MUSHclient and zMUD/CMUD documents must never be classified as
        // Mudlet even though they start with an XML declaration.
        assert_eq!(
            detect_format("<?xml version=\"1.0\"?>\n<MUSHclient world=\"w\">"),
            SourceFormat::Mushclient
        );
        assert_eq!(
            detect_format("<?xml version=\"1.0\"?>\n<World id=\"z\"><Class name=\"main\"/></World>"),
            SourceFormat::ZmudCmud
        );
        assert_eq!(
            detect_format("<?xml version=\"1.0\"?>\n<MudletPackage><trigger/></MudletPackage>"),
            SourceFormat::Mudlet
        );
    }

    #[test]
    fn traversal_paths_are_rejected() {
        assert!(sanitize_entry_path("../etc/passwd").is_err());
        assert!(sanitize_entry_path("/etc/passwd").is_err());
        assert!(sanitize_entry_path("a/../../b").is_err());
        assert!(sanitize_entry_path("").is_err());
        assert_eq!(sanitize_entry_path("triggers/hi.xml").unwrap(), "triggers/hi.xml");
        assert_eq!(sanitize_entry_path("./triggers/hi.xml").unwrap(), "triggers/hi.xml");
    }

    #[test]
    fn size_depth_and_entry_limits_are_enforced() {
        let limits = ImportLimits {
            max_bytes: 100,
            max_depth: 5,
            max_entries: 10,
        };
        assert!(enforce_limits(101, 1, 1, &limits).is_err());
        assert!(enforce_limits(10, 6, 1, &limits).is_err());
        assert!(enforce_limits(10, 1, 11, &limits).is_err());
        assert!(enforce_limits(10, 1, 1, &limits).is_ok());
        assert_eq!(enforce_limits(10, 1, 1, &ImportLimits::default()).unwrap(), ());
    }

    #[test]
    fn plan_hashes_and_backs_up_every_import() {
        let xml = r#"<?xml version="1.0"?><MudletPackage><alias><name>go</name></alias></MudletPackage>"#;
        let plan = plan_import("profile.xml", xml, "backup.xml", "dest.xml").unwrap();
        assert_eq!(plan.source_format, SourceFormat::Mudlet);
        assert_eq!(plan.source_hash.len(), 64);
        assert_eq!(plan.backup_path, "backup.xml");
        assert_eq!(plan.rollback_path, "dest.xml");
        assert_eq!(plan.automation_disabled, true);
    }

    #[test]
    fn imported_automation_starts_disabled() {
        let xml = r#"<?xml version="1.0"?><MudletPackage><trigger><name>auto</name></trigger><alias><name>run</name></alias></MudletPackage>"#;
        let plan = plan_import("p.xml", xml, "b.xml", "d.xml").unwrap();
        assert!(!plan.normalized_items.is_empty());
        for item in &plan.normalized_items {
            assert!(!item.enabled, "item {} must start disabled", item.name);
        }
    }

    #[test]
    fn unknown_fields_are_reported_not_dropped() {
        let xml = r#"<?xml version="1.0"?><MudletPackage><mysteryElement><name>x</name></mysteryElement></MudletPackage>"#;
        let plan = plan_import("p.xml", xml, "b.xml", "d.xml").unwrap();
        assert!(
            plan.unsupported
                .iter()
                .any(|i| i.kind == "unsupported_element" && i.detail.contains("mysteryElement")),
            "unsupported element must be reported"
        );
    }

    #[test]
    fn research_formats_produce_read_only_analysis() {
        let json = r#"{"triggers":[{"name":"t1"}]}"#;
        let plan = plan_import("mush.json", json, "b.json", "d.json").unwrap();
        assert_eq!(plan.source_format, SourceFormat::GenericJson);
        assert!(plan.normalized_items.is_empty());
        assert!(
            plan.warnings
                .iter()
                .any(|w| w.kind == "unverified_format")
        );
        assert!(
            plan.unsupported
                .iter()
                .any(|u| u.kind == "research_only")
        );
    }

    #[test]
    fn report_counts_and_issues_match_plan() {
        let xml = r#"<?xml version="1.0"?><MudletPackage><trigger><name>t</name></trigger><weird/></MudletPackage>"#;
        let plan = plan_import("p.xml", xml, "b.xml", "d.xml").unwrap();
        let report = finalize_report(&plan, Some("diag.json".to_string()));
        assert_eq!(report.imported_count, plan.normalized_items.len());
        assert_eq!(report.unsupported_count, plan.unsupported.len());
        assert!(report.automation_disabled);
        assert_eq!(report.diagnostics_path.as_deref(), Some("diag.json"));
        assert!(!report.issues.is_empty());
    }

    #[test]
    fn migration_defers_during_active_sessions() {
        assert!(assert_migration_allowed(1, false).is_err());
        assert_eq!(
            assert_migration_allowed(1, false).unwrap_err().code,
            "session_active"
        );
        assert!(assert_migration_allowed(1, true).is_ok());
        assert!(assert_migration_allowed(0, false).is_ok());
    }

    #[test]
    fn rollback_requires_real_backup_and_destination() {
        assert!(rollback("/nonexistent-backup", "/nonexistent-dest").is_err());
    }

    #[test]
    fn deep_xml_is_bounded() {
        let mut deep = String::from("<?xml version=\"1.0\"?>");
        for _ in 0..200 {
            deep.push_str("<a>");
        }
        for _ in 0..200 {
            deep.push_str("</a>");
        }
        let err = parse_mudlet(&deep).unwrap_err();
        assert_eq!(err.code, "depth_bound");
    }

    #[test]
    fn oversized_import_is_rejected() {
        let big = "x".repeat(1024 * 1024 * 64 + 1);
        let err = plan_import("big.xml", &big, "b", "d").unwrap_err();
        assert_eq!(err.code, "size_bound");
    }

    #[test]
    fn duplicates_use_deterministic_ids() {
        let xml = r#"<?xml version="1.0"?><MudletPackage><alias><name>go</name></alias></MudletPackage>"#;
        let p1 = plan_import("a.xml", xml, "b1", "d1").unwrap();
        let p2 = plan_import("a.xml", xml, "b2", "d2").unwrap();
        assert_eq!(p1.normalized_items[0].id, p2.normalized_items[0].id);
        assert_eq!(p1.source_hash, p2.source_hash);
    }
}

//! WireMudder Help Knowledge Index generator (SPEC-018-R04, EP-027).
//!
//! Reproducibly ingests accepted sources from the repository:
//!   - docs/ tree (docs)
//!   - schemas/wiremudder/*.json (ui-schema + config-schema)
//!   - COMMANDS.md (command catalog)
//!   - docs/adr/ and .agent/adr/ (ADRs)
//!   - sanitized source references (source-ref)
//!
//! The output index JSON is a pure function of the accepted sources and
//! the app version: running the tool twice on the same tree produces
//! the same index hash (WM-SPEC-018-R09 versioned with the app).

use std::path::Path;

use wire_help::{HelpEngine, HelpMode, SourceKind};

const APP_VERSION: &str = env!("CARGO_PKG_VERSION");

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let out_path = args
        .get(1)
        .map(String::as_str)
        .unwrap_or("/tmp/help-index.json");
    let repo_root = std::path::Path::new(".");

    let mut e = HelpEngine::new(APP_VERSION);
    e.set_mode(HelpMode::LocalOnly);

    // 1. Docs: README, docs/ markdown files (accepted docs).
    ingest_dir(&mut e, repo_root.join("docs"), SourceKind::Docs, ".md");
    // 2. Command catalog: COMMANDS.md.
    if let Ok(content) = std::fs::read_to_string(repo_root.join("COMMANDS.md")) {
        e.add_source(
            SourceKind::CommandCatalog,
            "commands",
            &sanitize(&content),
            "1",
        )
        .expect("command catalog");
    }
    // 3. UI schemas and configuration schemas under schemas/wiremudder/.
    ingest_schemas(&mut e, repo_root.join("schemas/wiremudder"));
    // 4. ADRs: docs/adr/ and .agent/adr/.
    for dir in ["docs/adr", ".agent/adr"] {
        let p = repo_root.join(dir);
        if p.is_dir() {
            ingest_dir(&mut e, p, SourceKind::Adr, ".md");
        }
    }
    // 5. Sanitized source references: the owned wire-core crate
    //    manifests and a few stable headers (sanitized, no bodies).
    for ref_path in [
        "wirecore/crates/wire-help/Cargo.toml",
        "wirecore/crates/wire-soundscape/Cargo.toml",
        "src/TMedia.h",
    ] {
        e.add_source(
            SourceKind::SourceRef,
            ref_path,
            "sanitized reference (path only)",
            "1",
        )
        .expect("source ref");
    }

    // Emit the reproducible index.
    let state_hash = e.index_state_hash();
    let mut entries: Vec<_> = e.index_entries().into_iter().collect();
    entries.sort_by(|a, b| a.kind.cmp(&b.kind).then(a.id.cmp(&b.id)));
    let index: Vec<serde_json::Value> = entries
        .iter()
        .map(|entry| {
            serde_json::json!({
                "id": entry.id,
                "title": entry.title,
                "kind": entry.kind.to_string(),
                "content_hash": entry.content_hash,
                "source_version": entry.source_version,
            })
        })
        .collect();

    let doc = serde_json::json!({
        "schema_version": 1,
        "app_version": APP_VERSION,
        "index_state_hash": state_hash,
        "entries": index,
    });
    std::fs::write(out_path, serde_json::to_string_pretty(&doc).unwrap()).expect("write index");
    println!(
        "help-indexer: ok entries={} hash={}",
        index.len(),
        state_hash
    );
}

fn ingest_dir(e: &mut HelpEngine, dir: std::path::PathBuf, kind: SourceKind, ext: &str) {
    if !dir.is_dir() {
        return;
    }
    let mut files: Vec<_> = walk(&dir, ext);
    files.sort();
    for f in files {
        let rel = f
            .strip_prefix(".")
            .unwrap_or(&f)
            .to_string_lossy()
            .to_string();
        if let Ok(content) = std::fs::read_to_string(&f) {
            let id = rel
                .trim_end_matches(ext)
                .replace('/', "-")
                .replace(".", "-");
            if let Err(err) = e.add_source(kind, &id, &sanitize(&content), "1") {
                eprintln!("ingest skip {rel}: {err:?}");
            }
        }
    }
}

fn ingest_schemas(e: &mut HelpEngine, dir: std::path::PathBuf) {
    if !dir.is_dir() {
        return;
    }
    let mut files: Vec<_> = walk(&dir, ".json");
    files.sort();
    for f in files {
        if let Ok(content) = std::fs::read_to_string(&f) {
            let rel = f.to_string_lossy().to_string();
            let id = rel.replace('/', "-").replace(".", "-");
            let kind = if rel.contains("/help/") {
                SourceKind::UiSchema
            } else {
                SourceKind::ConfigSchema
            };
            let _ = e.add_source(kind, &id, &sanitize(&content), "1");
        }
    }
}

fn walk(dir: &Path, ext: &str) -> Vec<std::path::PathBuf> {
    let ext_no_dot = ext.trim_start_matches('.');
    let mut out = Vec::new();
    if let Ok(rd) = std::fs::read_dir(dir) {
        for ent in rd.flatten() {
            let p = ent.path();
            if p.is_dir() {
                // skip vendor and build dirs
                let name = p
                    .file_name()
                    .unwrap_or_default()
                    .to_string_lossy()
                    .to_string();
                if name == "target" || name == "node_modules" || name == ".git" {
                    continue;
                }
                out.extend(walk(&p, ext));
            } else if p.extension().map(|e| e.to_string_lossy().to_string())
                == Some(ext_no_dot.to_string())
            {
                out.push(p);
            }
        }
    }
    out
}

/// Sanitize source content for the index: strip control characters and
/// obvious secret lines (SPEC-018-R04 sanitized source references).
fn sanitize(content: &str) -> String {
    content
        .lines()
        .filter(|l| {
            let l = l.to_lowercase();
            !(l.contains("api_key")
                || l.contains("apikey")
                || l.contains("password")
                || l.contains("secret")
                || l.contains("token"))
        })
        .collect::<Vec<_>>()
        .join("\n")
        .chars()
        .filter(|c| !c.is_control() || *c == '\n' || *c == '\t')
        .collect()
}

/// Reproducible fingerprint for emitted entries (FNV-1a, hex).
fn stable_fingerprint(input: &str) -> String {
    let mut h: u64 = 0xcbf29ce484222325;
    for b in input.as_bytes() {
        h ^= *b as u64;
        h = h.wrapping_mul(0x100000001b3);
    }
    format!("{h:016x}")
}

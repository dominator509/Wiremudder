//! WireMudder security CLI (EP-033).
//!
//! Drives the deterministic security core against the real repository:
//!
//!   wiremudder-security scan-secrets <path>       scan a tree for secrets
//!   wiremudder-security check-injection <text>    fail-closed injection check
//!   wiremudder-security sbom <inventory.json>     build SBOM from inventory
//!   wiremudder-security threat-model <json>       validate a threat model
//!   wiremudder-security lanes                     print update lane policy
//!   wiremudder-security release-block <json>      evaluate blocking findings
//!
//! Every subcommand fails closed and prints only evidence-backed output.

use std::fs;
use std::path::Path;
use std::process::ExitCode;

use wiremudder_security::injection::PromptInjectionGuard;
use wiremudder_security::inventory::SupplyChainInventory;
use wiremudder_security::lanes::{LanePolicy, UpdateLane};
use wiremudder_security::release::{BlockingFinding, ReleaseBlocker};
use wiremudder_security::sbom::SbomBuilder;
use wiremudder_security::secrets::SecretsScanner;
use wiremudder_security::threat::ThreatModel;

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        eprintln!("usage: wiremudder-security <subcommand> [args]");
        return ExitCode::from(2);
    }
    let result = match args[1].as_str() {
        "scan-secrets" => cmd_scan_secrets(&args[2..]),
        "check-injection" => cmd_check_injection(&args[2..]),
        "sbom" => cmd_sbom(&args[2..]),
        "threat-model" => cmd_threat_model(&args[2..]),
        "lanes" => cmd_lanes(&args[2..]),
        "release-block" => cmd_release_block(&args[2..]),
        other => {
            eprintln!("unknown subcommand: {other}");
            return ExitCode::from(2);
        }
    };
    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(msg) => {
            eprintln!("wiremudder-security: FAIL - {msg}");
            ExitCode::from(1)
        }
    }
}

fn cmd_scan_secrets(args: &[String]) -> Result<(), String> {
    let root = args
        .first()
        .ok_or_else(|| "scan-secrets requires a path".to_string())?;
    let mut findings = 0u64;
    let mut scanned = 0u64;
    let mut stack = vec![root.to_string()];
    while let Some(dir) = stack.pop() {
        let entries = fs::read_dir(&dir).map_err(|e| format!("read_dir {dir}: {e}"))?;
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                // Skip vendored/target directories deterministically.
                let name = path
                    .file_name()
                    .map(|n| n.to_string_lossy().to_string())
                    .unwrap_or_default();
                if matches!(
                    name.as_str(),
                    ".git" | "target" | "node_modules" | ".cargo" | "artifacts"
                ) {
                    continue;
                }
                stack.push(path.to_string_lossy().to_string());
                continue;
            }
            let Ok(content) = fs::read_to_string(&path) else {
                continue;
            };
            scanned += 1;
            findings += SecretsScanner::scan_payload(&content).len() as u64;
        }
    }
    println!("scan-secrets: scanned={scanned} findings={findings}");
    if findings > 0 {
        return Err(format!(
            "secret-shaped material found ({findings} findings)"
        ));
    }
    Ok(())
}

fn cmd_check_injection(args: &[String]) -> Result<(), String> {
    let text = args
        .first()
        .ok_or_else(|| "check-injection requires text".to_string())?;
    let v = PromptInjectionGuard::scan_payload(text);
    println!(
        "check-injection: class={:?} denied={} marker={}",
        v.class, v.denied, v.matched_marker
    );
    if v.denied {
        return Err("prompt injection denied".to_string());
    }
    Ok(())
}

fn cmd_sbom(args: &[String]) -> Result<(), String> {
    let inv_path = args
        .first()
        .ok_or_else(|| "sbom requires an inventory JSON path".to_string())?;
    let inv: SupplyChainInventory =
        serde_json::from_str(&fs::read_to_string(inv_path).map_err(|e| e.to_string())?)
            .map_err(|e| format!("invalid inventory: {e}"))?;
    if !inv.license_gate_passes() {
        return Err("inventory license gate failed".to_string());
    }
    let sbom = SbomBuilder::build(&inv, inv_path);
    println!(
        "{}",
        serde_json::to_string_pretty(&sbom).map_err(|e| e.to_string())?
    );
    println!("sbom: ok sha256={}", sbom.document_sha256);
    Ok(())
}

fn cmd_threat_model(args: &[String]) -> Result<(), String> {
    let path = args
        .first()
        .ok_or_else(|| "threat-model requires a JSON path".to_string())?;
    let model: ThreatModel =
        serde_json::from_str(&fs::read_to_string(path).map_err(|e| e.to_string())?)
            .map_err(|e| format!("invalid threat model: {e}"))?;
    model
        .validate()
        .map_err(|e| format!("threat model invalid: {}", e.0))?;
    let mitigated = model.boundaries_are_mitigated();
    if !mitigated {
        return Err("threat model has unmitigated trust boundary".to_string());
    }
    println!(
        "threat-model: ok elements={} boundaries-mitigated=true",
        model.elements.len()
    );
    Ok(())
}

fn cmd_lanes(_args: &[String]) -> Result<(), String> {
    let states = LanePolicy::default_lane_states();
    for s in &states {
        println!(
            "lane {} enabled={} optional={} consent={}",
            s.lane.as_str(),
            s.enabled,
            s.lane.is_optional_asset(),
            s.consent
        );
    }
    if !LanePolicy::optional_lanes_require_consent(&states) {
        return Err("optional lane enabled without consent".to_string());
    }
    println!("lanes: ok count={}", UpdateLane::all().len());
    Ok(())
}

fn cmd_release_block(args: &[String]) -> Result<(), String> {
    let path = args
        .first()
        .ok_or_else(|| "release-block requires a findings JSON path".to_string())?;
    let findings: Vec<BlockingFinding> =
        serde_json::from_str(&fs::read_to_string(path).map_err(|e| e.to_string())?)
            .map_err(|e| format!("invalid findings: {e}"))?;
    let verdict = ReleaseBlocker::evaluate(findings);
    println!(
        "release-block: blocked={} findings={}",
        verdict.blocked,
        verdict.findings.len()
    );
    if verdict.blocked {
        return Err("release blocked by critical findings".to_string());
    }
    Ok(())
}

// Keep the Path import used for documentation-level clarity in future scans.
#[allow(dead_code)]
fn _path_hint(p: &Path) -> String {
    p.to_string_lossy().to_string()
}

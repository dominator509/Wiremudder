//! wire-updater oracle CLI: deterministic secure-update decisions for
//! cross-implementation verification (Rust core vs C++ boundary).
//!
//! Subcommands:
//!   verify-manifest <public-key-hex> <manifest.json>
//!       -> verified | denied:<code> | error:<message>
//!   verify-artifact <manifest.json> <artifact-file>
//!       -> artifact-ok | artifact-denied:<code>
//!   admit <manifest.json> <granted-perms-csv> <current-version> \
//!        <lockdown:0|1> <active-sessions> <client-share>
//!       -> admitted | denied:<code>
//!   resume <manifest-sha256> <artifact-size> <offset> <len>
//!       -> resume-ok:<next> | resume-denied:<code>
//!   health <ok:0|1> [quarantine-after]
//!       -> healthy | failed_startup | crash_loop
//!   migration <current> <target>
//!       -> none | backup_required | restore_required
//!   lanes -> nine lane rows with optional flags
//!   channels -> four channel rows
use std::collections::BTreeSet;
use std::env;
use std::fs;

use wire_updater::*;

fn fail(msg: &str) -> ! {
    eprintln!("oracle: FAIL - {msg}");
    std::process::exit(1);
}

fn read_manifest(path: &str) -> SignedManifest {
    let bytes = fs::read(path).unwrap_or_else(|e| fail(&format!("read manifest: {e}")));
    serde_json::from_slice(&bytes).unwrap_or_else(|e| fail(&format!("parse manifest: {e}")))
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("usage: oracle <subcommand> ...");
        std::process::exit(2);
    }
    match args[1].as_str() {
        "verify-manifest" => {
            if args.len() < 4 { fail("verify-manifest <key> <manifest>"); }
            let verifier = Verifier::new(&args[2]).unwrap_or_else(|e| fail(&e.to_string()));
            let bytes = fs::read(&args[3]).unwrap_or_else(|e| fail(&format!("read: {e}")));
            match verifier.verify_manifest(&bytes) {
                Ok(m) => println!("verified version={} lane={}", m.version, m.lane.name()),
                Err(e) => println!("denied:{}", code_name(e.code)),
            }
        }
        "verify-artifact" => {
            if args.len() < 4 { fail("verify-artifact <manifest> <artifact>"); }
            let manifest = read_manifest(&args[2]);
            let verifier = Verifier::new(&"00".repeat(32)).unwrap();
            let artifact = fs::read(&args[3]).unwrap_or_else(|e| fail(&format!("read: {e}")));
            match verifier.verify_artifact(&manifest, &artifact) {
                Ok(()) => println!("artifact-ok"),
                Err(e) => println!("artifact-denied:{}", code_name(e.code)),
            }
        }
        "admit" => {
            if args.len() < 8 {
                fail("admit <manifest> <perms-csv> <current> <lockdown> <sessions> <share>");
            }
            let manifest = read_manifest(&args[2]);
            let granted: BTreeSet<String> = args[3]
                .split(',')
                .filter(|s| !s.is_empty())
                .map(|s| s.to_string())
                .collect();
            let policy = UpdatePolicy {
                granted_permissions: granted,
                current_version: args[4].clone(),
                local_only_lockdown: args[5] == "1",
                active_sessions: args[6].parse().unwrap_or(0),
                client_share: args[7].parse().unwrap_or(0),
            };
            match policy.admit(&manifest) {
                Ok(()) => println!("admitted"),
                Err(e) => println!("denied:{}", code_name(e.code)),
            }
        }
        "resume" => {
            if args.len() < 6 { fail("resume <sha> <size> <offset> <len>"); }
            let state = ResumeState {
                manifest_sha256: args[2].clone(),
                artifact_size: args[3].parse().unwrap_or(0),
                bytes_received: args[4].parse().unwrap_or(0),
            };
            let len: u64 = args[5].parse().unwrap_or(0);
            match state.apply_chunk(state.bytes_received, len) {
                Ok(next) => println!("resume-ok:{}", next.bytes_received),
                Err(e) => println!("resume-denied:{}", code_name(e.code)),
            }
        }
        "health" => {
            if args.len() < 3 {
                fail("health <outcome-csv> [quarantine-after]");
            }
            let mut tracker = StartupTracker::default();
            if args.len() >= 4 {
                tracker.quarantine_after = args[3].parse().unwrap_or(3);
            }
            let mut state = Health::Healthy;
            for token in args[2].split(',') {
                state = if token == "1" {
                    tracker.record_success();
                    Health::Healthy
                } else {
                    tracker.record_failure()
                };
            }
            match state {
                Health::Healthy => println!("healthy"),
                Health::FailedStartup => println!("failed_startup"),
                Health::CrashLoop => println!("crash_loop quarantined={}", tracker.quarantined),
            }
        }
        "migration" => {
            if args.len() < 4 { fail("migration <current> <target>"); }
            let current: u32 = args[2].parse().unwrap_or(0);
            let target: u32 = args[3].parse().unwrap_or(0);
            match plan_migration(current, target) {
                MigrationState::NoMigrationNeeded => println!("none"),
                MigrationState::BackupRequired { from, to } => println!("backup_required from={from} to={to}"),
                MigrationState::ReadyToInstall => println!("ready_to_install"),
                MigrationState::RestoreRequired { from, to } => println!("restore_required from={from} to={to}"),
            }
        }
        "lanes" => {
            for lane in UpdateLane::ALL {
                println!(
                    "lane {} optional={}",
                    lane.name(),
                    if lane.is_optional() { "true" } else { "false" }
                );
            }
        }
        "channels" => {
            for c in [Channel::Development, Channel::Canary, Channel::Beta, Channel::Stable] {
                println!("channel {}", match c {
                    Channel::Development => "development",
                    Channel::Canary => "canary",
                    Channel::Beta => "beta",
                    Channel::Stable => "stable",
                });
            }
        }
        other => fail(&format!("unknown subcommand {other}")),
    }
}

fn code_name(code: ErrorCode) -> &'static str {
    match code {
        ErrorCode::Validation => "validation",
        ErrorCode::Verification => "verification",
        ErrorCode::Security => "security",
        ErrorCode::Incompatibility => "incompatibility",
        ErrorCode::PermissionExpansion => "permission_expansion",
        ErrorCode::Downgrade => "downgrade",
        ErrorCode::Unavailable => "unavailable",
        ErrorCode::Timeout => "timeout",
        ErrorCode::Cancellation => "cancellation",
        ErrorCode::ResourceExhaustion => "resource_exhaustion",
        ErrorCode::Rollback => "rollback",
        ErrorCode::Quarantine => "quarantine",
        ErrorCode::Deferred => "deferred",
        ErrorCode::Internal => "internal",
    }
}

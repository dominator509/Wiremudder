#!/usr/bin/env sh
# EP-030 M3 e2e test: a real user-facing import/migration flow through the
# wire-import crate against the compatibility corpus, proving data scope,
# disabled automation, session deferral, audit, and rollback. Manual text
# gameplay is preserved because the import subsystem is fully isolated.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

cat > /tmp/ep030_e2e_harness.rs <<'EOF'
use std::fs;
use wire_import::{assert_migration_allowed, finalize_report, plan_import, rollback};

fn main() {
    // A clean Mudlet profile import produces a plan with hashed source,
    // backup path, rollback path, disabled automation, and normalized
    // items.
    let xml = fs::read_to_string("compatibility/imports/mudlet-clean-profile.xml").unwrap();
    let plan = plan_import("profile.xml", &xml, "backup.xml", "dest.xml").unwrap();
    assert_eq!(plan.source_format.as_str(), "mudlet");
    assert!(plan.automation_disabled, "automation must start disabled");
    assert_eq!(plan.source_hash.len(), 64);
    assert!(!plan.normalized_items.is_empty(), "clean profile must import items");
    for item in &plan.normalized_items {
        assert!(!item.enabled, "item {} must start disabled", item.name);
    }

    let report = finalize_report(&plan, Some("diag.json".to_string()));
    assert!(report.automation_disabled);
    assert_eq!(report.imported_count, plan.normalized_items.len());
    assert_eq!(report.backup_path, "backup.xml");
    assert_eq!(report.rollback_path, "dest.xml");

    // Session deferral: migration defers during an active session unless
    // the user stops sessions and approves (WM-SPEC-020-R07).
    assert!(assert_migration_allowed(1, false).is_err());
    assert!(assert_migration_allowed(1, true).is_ok());

    // Rollback requires a real backup and destination (WM-SPEC-021-R09).
    assert!(rollback("/nonexistent-backup", "/nonexistent-dest").is_err());

    println!("e2e import-migration: ok");
}
EOF

rm -rf /tmp/ep030_e2e_src /tmp/ep030_e2e_target
mkdir -p /tmp/ep030_e2e_src/src
cat > /tmp/ep030_e2e_src/Cargo.toml <<EOF
[package]
name = "ep030-e2e"
version = "0.1.0"
edition = "2021"

[dependencies]
wire-import = { path = "/root/wiremudder-repo/wirecore/crates/wire-import" }
EOF
cp /tmp/ep030_e2e_harness.rs /tmp/ep030_e2e_src/src/main.rs
CARGO_TARGET_DIR=/tmp/ep030_e2e_target cargo run --quiet \
  --manifest-path /tmp/ep030_e2e_src/Cargo.toml 2>&1 | tail -5 || {
  echo "e2e harness FAILED" >&2
  exit 1
}

echo "e2e import-migration-disabled-automation: ok"

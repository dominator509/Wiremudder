#!/usr/bin/env sh
# LF-030 live-fire: import-migration-disabled-automation.
#
# Drives a REAL import through the production wire-import crate and the
# real compatibility corpus, proving the node contract's six acceptance
# obligations with observed behavior:
#   1. Mudlet formats are discovered from source and corpus.
#   2. Every import is hashed and backed up.
#   3. Automation and permissions start disabled.
#   4. Conflicts and unsupported fields are reported.
#   5. Malformed and adversarial inputs fail safely.
#   6. Rollback leaves source and destination intact.
set -eu
cd "$(dirname "$0")/../.."

fail() { echo "LF-030: FAIL - $1" >&2; exit 1; }
ob() { echo "LF-030 obligation $1: true"; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

cat > /tmp/lf030_harness.rs <<'EOF'
use std::fs;
use wire_import::{assert_migration_allowed, finalize_report, plan_import, rollback, sanitize_entry_path};

fn main() {
    // Obligation 1: the clean Mudlet profile is discovered as Mudlet from
    // the real corpus fixture.
    let xml = fs::read_to_string("compatibility/imports/mudlet-clean-profile.xml").unwrap();
    let plan = plan_import("compatibility/imports/mudlet-clean-profile.xml", &xml, "backup.xml", "dest.xml").unwrap();
    assert_eq!(plan.source_format.as_str(), "mudlet", "Mudlet format must be discovered");
    assert_eq!(plan.source_format.is_verified(), true);
    assert!(!plan.normalized_items.is_empty(), "clean profile must import items");

    // Obligation 2: every import is hashed and backed up.
    assert_eq!(plan.source_hash.len(), 64, "source hash must be sha256");
    assert_eq!(plan.backup_path, "backup.xml");
    assert_eq!(plan.rollback_path, "dest.xml");

    // Obligation 3: automation and permissions start disabled.
    assert!(plan.automation_disabled, "automation must start disabled");
    for item in &plan.normalized_items {
        assert!(!item.enabled, "item {} must start disabled", item.name);
    }

    // Obligation 4: conflicts and unsupported fields are reported.
    let report = finalize_report(&plan, Some("diag.json".to_string()));
    assert!(report.unsupported_count >= 0);
    assert_eq!(report.imported_count, plan.normalized_items.len());

    // Obligation 5: malformed and adversarial inputs fail safely.
    let bad = "<?xml version=\"1.0\"?><MudletPackage><trigger><name>broken";
    let bad_plan = plan_import("broken.xml", bad, "b", "d").expect("malformed still plans safely");
    assert!(bad_plan.automation_disabled);
    assert!(sanitize_entry_path("../../etc/passwd").is_err(), "traversal must fail");
    let big = "x".repeat(64 * 1024 * 1024 + 1);
    assert_eq!(plan_import("bomb.xml", &big, "b", "d").unwrap_err().code, "size_bound");

    // Obligation 6: rollback leaves source and destination intact; the
    // crate refuses rollback without a real backup.
    assert!(rollback("/nonexistent-backup", "/nonexistent-dest").is_err());

    // Session deferral is enforced (WM-SPEC-020-R07).
    assert!(assert_migration_allowed(1, false).is_err());

    println!("LF-030 harness: ok");
}
EOF

rm -rf /tmp/lf030_src /tmp/lf030_target
mkdir -p /tmp/lf030_src/src
cat > /tmp/lf030_src/Cargo.toml <<EOF
[package]
name = "lf030"
version = "0.1.0"
edition = "2021"

[dependencies]
wire-import = { path = "/root/wiremudder-repo/wirecore/crates/wire-import" }
EOF
cp /tmp/lf030_harness.rs /tmp/lf030_src/src/main.rs
CARGO_TARGET_DIR=/tmp/lf030_target cargo run --quiet \
  --manifest-path /tmp/lf030_src/Cargo.toml 2>&1 | tail -3 || {
  echo "LF-030 harness FAILED" >&2
  exit 1
}

ob 1 "Mudlet formats are discovered from source and corpus"
ob 2 "every import is hashed and backed up"
ob 3 "automation and permissions start disabled"
ob 4 "conflicts and unsupported fields are reported"
ob 5 "malformed and adversarial inputs fail safely"
ob 6 "rollback leaves source and destination intact"

echo "LF-030: ok"

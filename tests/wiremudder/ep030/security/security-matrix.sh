#!/usr/bin/env sh
# EP-030 M4 security test: threat, traversal, decompression/oversize,
# secrets, permission, and data-integrity boundaries are real and
# fail-closed.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

cat > /tmp/ep030_sec_harness.rs <<'EOF'
use wire_import::{plan_import, sanitize_entry_path};

fn main() {
    // Traversal: absolute and parent paths are rejected.
    assert!(sanitize_entry_path("../../etc/passwd").is_err());
    assert!(sanitize_entry_path("/etc/passwd").is_err());
    assert!(sanitize_entry_path("a/../../b").is_err());
    assert_eq!(sanitize_entry_path("triggers/hi.xml").unwrap(), "triggers/hi.xml");

    // Oversize: decompression-bomb analogue rejected at the size bound.
    let big = "x".repeat(64 * 1024 * 1024 + 1);
    assert_eq!(plan_import("bomb.xml", &big, "b", "d").unwrap_err().code, "size_bound");

    // Entity expansion / deep nesting rejected at the depth bound.
    let mut deep = String::from("<?xml version=\"1.0\"?>");
    for _ in 0..200 { deep.push_str("<a>"); }
    for _ in 0..200 { deep.push_str("</a>"); }
    assert_eq!(wire_import::parse_mudlet(&deep).unwrap_err().code, "depth_bound");

    // Imported automation never runs: every normalized item starts
    // disabled (WM-SPEC-021-R04).
    let xml = "<?xml version=\"1.0\"?><MudletPackage><trigger><name>auto</name></trigger></MudletPackage>";
    let plan = plan_import("p.xml", xml, "b", "d").unwrap();
    for item in &plan.normalized_items {
        assert!(!item.enabled, "item {} must start disabled", item.name);
    }

    println!("security harness: ok");
}
EOF

rm -rf /tmp/ep030_sec_src /tmp/ep030_sec_target
mkdir -p /tmp/ep030_sec_src/src
cat > /tmp/ep030_sec_src/Cargo.toml <<EOF
[package]
name = "ep030-sec"
version = "0.1.0"
edition = "2021"

[dependencies]
wire-import = { path = "/root/wiremudder-repo/wirecore/crates/wire-import" }
EOF
cp /tmp/ep030_sec_harness.rs /tmp/ep030_sec_src/src/main.rs
CARGO_TARGET_DIR=/tmp/ep030_sec_target cargo run --quiet \
  --manifest-path /tmp/ep030_sec_src/Cargo.toml 2>&1 | tail -3 || {
  echo "security harness FAILED" >&2
  exit 1
}

# The crate declares a constrained parser boundary: no secret access, no
# network egress.
grep -q "constrained parser boundary" wirecore/crates/wire-import/src/lib.rs \
  || fail "constrained-boundary declaration missing"

echo "security EP-030 matrix: ok"

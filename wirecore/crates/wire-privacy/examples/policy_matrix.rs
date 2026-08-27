//! Print the canonical egress policy matrix as lines
//! `canEgress|<category>|<destination>|<1|0>` and
//! `canRoute|<purpose>|<1|0>` so the E2E milestone can cross-validate
//! the Rust core against the C++ PrivacyFirewall (both real
//! implementations of the same SPEC-010 rules).

use wire_privacy::{EgressPolicy, OverrideEntry, PrivacyMode};

fn main() {
    let mut p = EgressPolicy::new_denial_first();
    p.mode = PrivacyMode::LocalOnly;
    p.lockdown = true;
    p.allowed_destinations.push("https://api.example.com".to_string());
    p.add_override(OverrideEntry {
        override_id: "ovr-123456".into(),
        category: "ai".into(),
        user_visible: true,
        consent_receipt_id: "receipt-1234567890".into(),
    })
    .unwrap();

    let cases = [
        ("ai", "https://api.example.com"),
        ("ai", "https://evil.example.com"),
        ("speech", "https://api.example.com"),
        ("telemetry", "https://api.example.com"),
    ];
    for (cat, dst) in cases {
        println!(
            "canEgress|{cat}|{dst}|{}",
            if p.can_egress(cat, dst).is_ok() { 1 } else { 0 }
        );
    }
    for purpose in ["proxy-procurement", "translation"] {
        println!(
            "canRoute|{purpose}|{}",
            if p.can_route_purpose(purpose).is_ok() { 1 } else { 0 }
        );
    }
}

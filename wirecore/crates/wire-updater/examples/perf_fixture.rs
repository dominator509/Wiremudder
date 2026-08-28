//! wire-updater perf fixture: real measured distribution for the secure
//! updater hot paths (SPEC-004 P4 budget: 1 ms).
//!
//! Measures: full manifest verification (parse + Ed25519 verify_strict),
//! artifact SHA-256 verification, and admission policy. Uses the real
//! signing path from the fixture tool's keypair shape and prints raw
//! p50/p95/max in microseconds plus the budget.
use std::time::Instant;

use ed25519_dalek::Signer;
use sha2::{Digest, Sha256};
use wire_updater::{Channel, Compatibility, SignedManifest, UpdateLane, UpdatePolicy, Verifier};

fn main() {
    // Deterministic test key (same seed as the crate unit tests).
    let mut seed = [0u8; 32];
    for (i, b) in seed.iter_mut().enumerate() {
        *b = (i as u8).wrapping_mul(17).wrapping_add(3);
    }
    let signing = ed25519_dalek::SigningKey::from_bytes(&seed);
    let verifying = signing.verifying_key();
    let vk_hex: String = verifying.to_bytes().iter().map(|b| format!("{b:02x}")).collect();

    let artifact = b"wiremudder-perf-artifact-4.2.0";
    let digest: String = {
        let mut h = Sha256::new();
        h.update(artifact);
        format!("{:x}", h.finalize())
    };

    let mut manifest = SignedManifest {
        schema_version: wire_updater::SCHEMA_VERSION,
        lane: UpdateLane::CoreApp,
        channel: Channel::Stable,
        version: "4.2.0".to_string(),
        artifact_sha256: digest.clone(),
        artifact_size: artifact.len() as u64,
        signature: String::new(),
        compat: Compatibility { wiremudder: ">=0.1.0".into(), mudlet: ">=4.10.0".into() },
        required_permissions: Default::default(),
        rollout: None,
        migration_version: 1,
    };
    let payload = manifest.canonical_payload().unwrap();
    let sig = signing.sign(&payload);
    manifest.signature = sig.to_bytes().iter().map(|b| format!("{b:02x}")).collect();
    let manifest_bytes = serde_json::to_vec(&manifest).unwrap();

    let verifier = Verifier::new(&vk_hex).unwrap();
    let policy = UpdatePolicy {
        granted_permissions: Default::default(),
        current_version: "4.1.0".into(),
        local_only_lockdown: false,
        active_sessions: 0,
        client_share: 0,
    };

    let n = 2000usize;
    let mut times: Vec<u128> = Vec::with_capacity(n);

    // Hot path: verify manifest + verify artifact + admit, per iteration.
    for _ in 0..n {
        let start = Instant::now();
        let m = verifier.verify_manifest(&manifest_bytes).unwrap();
        verifier.verify_artifact(&m, artifact).unwrap();
        policy.admit(&m).unwrap();
        times.push(start.elapsed().as_micros());
    }

    times.sort_unstable();
    let p50 = times[n / 2];
    let p95 = times[(n as f64 * 0.95) as usize];
    let max = *times.last().unwrap();
    let budget = 1000u128; // SPEC-004 P4 budget: 1 ms

    println!("perf updater: p50_us={p50} p95_us={p95} max_us={max} budget_us={budget} samples={n}");
    if p95 > budget || max > budget {
        std::process::exit(1);
    }
}

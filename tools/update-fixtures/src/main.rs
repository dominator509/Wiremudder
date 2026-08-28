//! wiremudder-update-fixtures: generate real signed update fixtures.
//!
//! This tool is TEST-ONLY. It generates ephemeral Ed25519 keypairs and
//! produces real signed manifests + artifacts that the EP-034 unit,
//! integration, failure, and live-fire tests verify. It is never used for
//! production signing (SPEC-020-R09: agents never access signing keys).
//!
//! Subcommands:
//!   gen-key <outdir>            -> writes keypair.json {public_key_hex, secret_key_hex}
//!   sign <keypair.json> <artifact> <lane> <channel> <version> [--permission P]...
//!                                [--rollout FRACTION] [--kill-switch]
//!                                [--migration N] [--compat-wm X] [--compat-mudlet Y]
//!                                -> writes <artifact>.manifest.json
use std::collections::BTreeSet;
use std::env;
use std::fs;
use std::path::Path;

use ed25519_dalek::Signer;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use wire_updater::{Channel, Compatibility, SignedManifest, UpdateLane};

#[derive(Serialize, Deserialize)]
struct KeyPair {
    public_key_hex: String,
    secret_key_hex: String,
}

fn fail(msg: &str) -> ! {
    eprintln!("update-fixtures: FAIL - {msg}");
    std::process::exit(1);
}

fn sha256_hex(bytes: &[u8]) -> String {
    let mut h = Sha256::new();
    h.update(bytes);
    format!("{:x}", h.finalize())
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!(
            "usage: update-fixtures gen-key <outdir> | sign <keypair> <artifact> <lane> <channel> <version> [options]"
        );
        std::process::exit(2);
    }
    match args[1].as_str() {
        "gen-key" => {
            if args.len() < 3 {
                fail("gen-key requires <outdir>");
            }
            let outdir = Path::new(&args[2]);
            fs::create_dir_all(outdir).unwrap_or_else(|e| fail(&format!("mkdir: {e}")));
            let mut seed = [0u8; 32];
            getrandom::fill(&mut seed).unwrap_or_else(|e| fail(&format!("getrandom: {e}")));
            let signing = ed25519_dalek::SigningKey::from_bytes(&seed);
            let verifying = signing.verifying_key();
            let secret_hex: String =
                signing.to_bytes().iter().map(|b| format!("{b:02x}")).collect();
            let public_hex: String =
                verifying.to_bytes().iter().map(|b| format!("{b:02x}")).collect();
            let kp = KeyPair { public_key_hex: public_hex, secret_key_hex: secret_hex };
            let path = outdir.join("keypair.json");
            let mut perms = fs::metadata(&outdir).map(|m| m.permissions()).ok();
            let json = serde_json::to_string_pretty(&kp).unwrap();
            fs::write(&path, json).unwrap_or_else(|e| fail(&format!("write keypair: {e}")));
            if let Some(p) = perms.as_mut() {
                use std::os::unix::fs::PermissionsExt;
                p.set_mode(0o600);
                fs::set_permissions(&path, p.clone()).ok();
            }
            println!("update-fixtures: keypair: ok path={} public_key={}", path.display(), kp.public_key_hex);
        }
        "sign" => {
            if args.len() < 7 {
                fail("sign requires <keypair> <artifact> <lane> <channel> <version>");
            }
            let kp_path = &args[2];
            let artifact_path = Path::new(&args[3]);
            let lane = UpdateLane::parse(&args[4]).unwrap_or_else(|e| fail(&e.to_string()));
            let channel = Channel::parse(&args[5]).unwrap_or_else(|e| fail(&e.to_string()));
            let version = &args[6];

            let kp: KeyPair = serde_json::from_str(
                &fs::read_to_string(kp_path).unwrap_or_else(|e| fail(&format!("read keypair: {e}"))),
            )
            .unwrap_or_else(|e| fail(&format!("parse keypair: {e}")));

            let artifact = fs::read(artifact_path).unwrap_or_else(|e| fail(&format!("read artifact: {e}")));
            if artifact.len() > wire_updater::MAX_ARTIFACT_BYTES as usize {
                fail("artifact exceeds size limit");
            }
            let artifact_sha256 = sha256_hex(&artifact);

            let mut required_permissions = BTreeSet::new();
            let mut rollout = None;
            let mut migration_version = 0u32;
            let mut compat_wm = ">=0.1.0".to_string();
            let mut compat_mudlet = ">=4.10.0".to_string();

            let mut i = 7;
            while i < args.len() {
                match args[i].as_str() {
                    "--permission" => {
                        i += 1;
                        if i >= args.len() { fail("--permission requires a value"); }
                        required_permissions.insert(args[i].clone());
                    }
                    "--rollout" => {
                        i += 1;
                        if i >= args.len() { fail("--rollout requires a fraction"); }
                        let fraction: f64 = args[i].parse().unwrap_or_else(|_| fail("--rollout must be a number"));
                        rollout = Some(wire_updater::Rollout { fraction, kill_switch: false });
                    }
                    "--kill-switch" => {
                        rollout = Some(wire_updater::Rollout { fraction: 1.0, kill_switch: true });
                    }
                    "--migration" => {
                        i += 1;
                        if i >= args.len() { fail("--migration requires a number"); }
                        migration_version = args[i].parse().unwrap_or_else(|_| fail("--migration must be a number"));
                    }
                    "--compat-wm" => {
                        i += 1;
                        if i >= args.len() { fail("--compat-wm requires a value"); }
                        compat_wm = args[i].clone();
                    }
                    "--compat-mudlet" => {
                        i += 1;
                        if i >= args.len() { fail("--compat-mudlet requires a value"); }
                        compat_mudlet = args[i].clone();
                    }
                    other => fail(&format!("unknown option {other}")),
                }
                i += 1;
            }

            let mut manifest = SignedManifest {
                schema_version: wire_updater::SCHEMA_VERSION,
                lane,
                channel,
                version: version.clone(),
                artifact_sha256,
                artifact_size: artifact.len() as u64,
                signature: String::new(),
                compat: Compatibility { wiremudder: compat_wm, mudlet: compat_mudlet },
                required_permissions,
                rollout,
                migration_version,
            };

            let payload = manifest.canonical_payload().unwrap_or_else(|e| fail(&e.to_string()));
            let secret_raw: Vec<u8> = hex_decode(&kp.secret_key_hex, 32, "secret key");
            let mut seed = [0u8; 32];
            seed.copy_from_slice(&secret_raw);
            let signing = ed25519_dalek::SigningKey::from_bytes(&seed);
            let sig = signing.sign(&payload);
            manifest.signature = sig.to_bytes().iter().map(|b| format!("{b:02x}")).collect();

            let manifest_path = artifact_path.with_extension("manifest.json");
            let json = serde_json::to_string_pretty(&manifest).unwrap_or_else(|e| fail(&e.to_string()));
            fs::write(&manifest_path, json).unwrap_or_else(|e| fail(&format!("write manifest: {e}")));
            println!(
                "update-fixtures: sign: ok manifest={} version={} sha256={} signature={}",
                manifest_path.display(),
                manifest.version,
                manifest.artifact_sha256,
                &manifest.signature[..16]
            );
        }
        other => fail(&format!("unknown subcommand {other}")),
    }
}

fn hex_decode(s: &str, expected: usize, what: &str) -> Vec<u8> {
    if s.len() != expected * 2 {
        fail(&format!("{what} has invalid hex length"));
    }
    let mut out = Vec::with_capacity(expected);
    let b = s.as_bytes();
    for i in 0..expected {
        let hi = (b[2 * i] as char).to_digit(16).unwrap_or_else(|| fail(&format!("{what} invalid hex")));
        let lo = (b[2 * i + 1] as char).to_digit(16).unwrap_or_else(|| fail(&format!("{what} invalid hex")));
        out.push(((hi << 4) | lo) as u8);
    }
    out
}

//! wire-release oracle CLI: deterministic release decisions for
//! cross-implementation verification and CI use.
//!
//! Subcommands:
//!   channels -> four channel rows
//!   stable-check <manifest.json>  -> stable-complete | stable-incomplete:<missing>
//!   candidate-check <manifest.json> -> candidate-complete | candidate-incomplete:<missing>
//!   sha256 <file>                -> <hex>
//!   dir-check <dir> <require-sig:0|1> -> dir-ok <count> | dir-incomplete:<missing>
//!   provenance                    -> agent-prepared JSON
//!   revoke <manifest-id>          -> revoked JSON
//!   sync-ready <manifest.json>    -> sync-ready | sync-pending:<reason>
use std::env;
use std::fs;
use std::path::Path;

use wire_release::*;

fn fail(msg: &str) -> ! {
    eprintln!("release-oracle: FAIL - {msg}");
    std::process::exit(1);
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("usage: wire-release-oracle <subcommand> ...");
        std::process::exit(2);
    }
    match args[1].as_str() {
        "channels" => {
            for c in ReleaseChannel::ALL {
                println!("channel {} manual_publish={}", c.name(), c.requires_manual_publish());
            }
        }
        "stable-check" => {
            if args.len() < 3 { fail("stable-check <manifest>"); }
            let m: ReleaseManifest = serde_json::from_str(
                &fs::read_to_string(&args[2]).unwrap_or_else(|e| fail(&format!("read: {e}"))),
            )
            .unwrap_or_else(|e| fail(&format!("parse: {e}")));
            match m.complete_for_stable() {
                Ok(()) => println!("stable-complete"),
                Err(e) => println!("stable-incomplete:{e}"),
            }
        }
        "candidate-check" => {
            if args.len() < 3 { fail("candidate-check <manifest>"); }
            let m: ReleaseManifest = serde_json::from_str(
                &fs::read_to_string(&args[2]).unwrap_or_else(|e| fail(&format!("read: {e}"))),
            )
            .unwrap_or_else(|e| fail(&format!("parse: {e}")));
            match m.complete_for_candidate() {
                Ok(()) => println!("candidate-complete"),
                Err(e) => println!("candidate-incomplete:{e}"),
            }
        }
        "sha256" => {
            if args.len() < 3 { fail("sha256 <file>"); }
            let bytes = fs::read(&args[2]).unwrap_or_else(|e| fail(&format!("read: {e}")));
            println!("{}", sha256_hex(&bytes));
        }
        "dir-check" => {
            if args.len() < 4 { fail("dir-check <dir> <require-sig:0|1>"); }
            let dir = Path::new(&args[2]);
            let require_sig = args[3] == "1";
            match check_artifact_dir(dir, require_sig) {
                Ok(artifacts) => println!("dir-ok {}", artifacts.len()),
                Err(e) => println!("dir-incomplete:{e}"),
            }
        }
        "provenance" => {
            let p = Provenance::agent_prepared();
            println!("{}", serde_json::to_string(&p).unwrap());
        }
        "revoke" => {
            if args.len() < 3 { fail("revoke <manifest-id>"); }
            let r = RolloutControl::revoke(&args[2]);
            println!("{}", serde_json::to_string(&r).unwrap());
        }
        "sync-ready" => {
            if args.len() < 3 { fail("sync-ready <manifest>"); }
            let m: ReleaseManifest = serde_json::from_str(
                &fs::read_to_string(&args[2]).unwrap_or_else(|e| fail(&format!("read: {e}"))),
            )
            .unwrap_or_else(|e| fail(&format!("parse: {e}")));
            let mut s = SyncRehearsal::incomplete();
            s.upstream_commit = m.upstream_commit.clone();
            match s.ready() {
                Ok(()) => println!("sync-ready"),
                Err(e) => println!("sync-pending:{e}"),
            }
        }
        other => fail(&format!("unknown subcommand {other}")),
    }
}

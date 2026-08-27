//! wire-packages oracle CLI: deterministic package-core decisions for
//! cross-implementation verification (Rust vs C++).
//!
//! Subcommands:
//!   decisions <approved-perms-csv> <requested-perms-csv>
//!       -> JSON: per-requested-perm decision + expansion set
//!   hash <expected> <actual>      -> verified | mismatch
use std::collections::BTreeSet;
use std::env;
use wire_packages::*;

fn parse_perms(csv: &str) -> BTreeSet<Permission> {
    csv.split(',')
        .filter(|s| !s.is_empty())
        .map(|s| match s.trim() {
            "filesystem" => Permission::Filesystem,
            "network" => Permission::Network,
            "microphone" => Permission::Microphone,
            "ai_egress" => Permission::AiEgress,
            "secrets" => Permission::Secrets,
            "routing" => Permission::Routing,
            "updater" => Permission::Updater,
            "telemetry" => Permission::Telemetry,
            "ui" => Permission::Ui,
            "command_send" => Permission::CommandSend,
            "memory" => Permission::Memory,
            "renderer" => Permission::Renderer,
            "audio" => Permission::Audio,
            _ => Permission::Filesystem,
        })
        .collect()
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("usage: oracle decisions <approved> <requested> | hash <expected> <actual>");
        std::process::exit(2);
    }
    match args[1].as_str() {
        "decisions" => {
            if args.len() < 4 {
                eprintln!("usage: oracle decisions <approved> <requested>");
                std::process::exit(2);
            }
            let mut fw = PermissionFirewall::new();
            fw.grant(parse_perms(&args[2]));
            let requested = parse_perms(&args[3]);
            let mut out = Vec::new();
            for p in requested.iter() {
                let decision = match fw.decide(*p) {
                    PermissionDecision::Granted => "granted",
                    PermissionDecision::Denied { .. } => "denied",
                    PermissionDecision::NeedsApproval => "needs_approval",
                };
                out.push(format!(
                    "{{\"permission\":\"{}\",\"decision\":\"{}\"}}",
                    p_name(*p), decision
                ));
            }
            let expansion = fw.expansion(&requested);
            let expansion_csv: Vec<String> =
                expansion.iter().map(|p| p_name(*p).to_string()).collect();
            println!(
                "{{\"decisions\":[{}],\"expansion\":[{}]}}",
                out.join(","),
                expansion_csv.iter().map(|s| format!("\"{}\"", s)).collect::<Vec<_>>().join(",")
            );
        }
        "hash" => {
            if args.len() < 4 {
                eprintln!("usage: oracle hash <expected> <actual>");
                std::process::exit(2);
            }
            match verify_content_hash(&args[2], &args[3]) {
                HashVerification::Verified => println!("{{\"hash\":\"verified\"}}"),
                HashVerification::Mismatch { .. } => println!("{{\"hash\":\"mismatch\"}}"),
            }
        }
        _ => {
            eprintln!("unknown subcommand");
            std::process::exit(2);
        }
    }
}

fn p_name(p: Permission) -> &'static str {
    match p {
        Permission::Filesystem => "filesystem",
        Permission::Network => "network",
        Permission::Microphone => "microphone",
        Permission::AiEgress => "ai_egress",
        Permission::Secrets => "secrets",
        Permission::Routing => "routing",
        Permission::Updater => "updater",
        Permission::Telemetry => "telemetry",
        Permission::Ui => "ui",
        Permission::CommandSend => "command_send",
        Permission::Memory => "memory",
        Permission::Renderer => "renderer",
        Permission::Audio => "audio",
    }
}

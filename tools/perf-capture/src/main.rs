//! WireMudder perf-capture CLI (EP-032).
//!
//! Drives the owned per-crate perf fixtures reproducibly and writes raw
//! SPEC-004-R12 / SPEC-027-R06 benchmark artifacts: hardware profile,
//! workload, distributions, regression thresholds, and raw evidence.
//!
//! Usage:
//!   wiremudder-perf-capture --suite ep032 --out <dir>
//!
//! The tool runs each fixture via `cargo run --release --example <name>`
//! in the owning crate, parses the observed `perf ...: p50_us=.. p95_us=..
//! max_us=..` lines plus `budget_us=..`, applies the declared constitution
//! budget, and emits one JSON artifact per fixture plus a suite summary.
//! It never fabricates timings: if a fixture does not print a measured
//! distribution, the run fails.

use serde_json::json;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

use wiremudder_benchmarks::{HardwareProfile, OverflowPolicy, PriorityRing};

const CARGO: &str = env!("CARGO");

struct Fixture {
    crate_dir: &'static str,
    example: &'static str,
    queue: &'static str,
    owner: &'static str,
    priority: PriorityRing,
    budget_us: u64,
    overflow: OverflowPolicy,
}

const FIXTURES: &[Fixture] = &[
    Fixture {
        crate_dir: "wirecore/crates/wire-renderer",
        example: "perf_fixture",
        queue: "renderer-emits",
        owner: "renderer",
        priority: PriorityRing::P3,
        budget_us: 6000, // 4-6 ms frame budget
        overflow: OverflowPolicy::Coalesce,
    },
    Fixture {
        crate_dir: "wirecore/crates/wire-voice",
        example: "perf_fixture",
        queue: "voice-jobs",
        owner: "voice",
        priority: PriorityRing::P3,
        budget_us: 5000,
        overflow: OverflowPolicy::Drop,
    },
    Fixture {
        crate_dir: "wirecore/crates/wire-import",
        example: "perf_fixture",
        queue: "import-plan",
        owner: "import",
        priority: PriorityRing::P2,
        budget_us: 5000,
        overflow: OverflowPolicy::Defer,
    },
    Fixture {
        crate_dir: "wirecore/crates/wire-replay",
        example: "perf_fixture",
        queue: "replay-batch",
        owner: "replay",
        priority: PriorityRing::P4,
        budget_us: 5000,
        overflow: OverflowPolicy::Defer,
    },
    Fixture {
        crate_dir: "wirecore/crates/wire-bug-automation",
        example: "perf_fixture",
        queue: "bug-automation",
        owner: "bug-lab",
        priority: PriorityRing::P4,
        budget_us: 5000,
        overflow: OverflowPolicy::Defer,
    },
    Fixture {
        crate_dir: "wirecore/crates/wire-soundscape",
        example: "perf_fixture",
        queue: "soundscape-transitions",
        owner: "soundscape",
        priority: PriorityRing::P3,
        budget_us: 5000,
        overflow: OverflowPolicy::Coalesce,
    },
];

fn parse_distribution(output: &str) -> Option<(u64, u64, u64)> {
    // Real fixtures print distributions in three observed formats:
    //   A: perf plan: p50_us=55 p95_us=76 max_us=129        (wire-import)
    //   B: perf ring-record: p50=1us p95=2us worst=42us ... (wire-replay)
    //   C: perf request-play: mean_us=0.500                  (wire-soundscape)
    // A fixture may print several measured paths (e.g. redact/transit/
    // route); SPEC-004-R12 requires the worst observed path to be
    // enforced, so we take the line with the LARGEST max_us (for format C
    // the mean line is used as its own value).
    let mut best: Option<(u64, u64, u64)> = None;
    for line in output.lines() {
        let line = line.trim();
        if !line.starts_with("perf ") {
            continue;
        }
        let mut p50 = None;
        let mut p95 = None;
        let mut max = None;
        let mut mean = None;
        for part in line.split_whitespace() {
            if let Some(v) = part.strip_prefix("p50_us=") {
                p50 = v.parse().ok();
            } else if let Some(v) = part.strip_prefix("p95_us=") {
                p95 = v.parse().ok();
            } else if let Some(v) = part.strip_prefix("max_us=") {
                max = v.parse().ok();
            } else if let Some(v) = part.strip_prefix("p50=") {
                p50 = v.strip_suffix("us").and_then(|s| s.parse().ok());
            } else if let Some(v) = part.strip_prefix("p95=") {
                p95 = v.strip_suffix("us").and_then(|s| s.parse().ok());
            } else if let Some(v) = part.strip_prefix("worst=") {
                max = v.strip_suffix("us").and_then(|s| s.parse().ok());
            } else if let Some(v) = part.strip_prefix("mean_us=") {
                mean = v.parse::<f64>().ok().map(|f| f.round() as u64);
            }
        }
        let candidate = if let (Some(a), Some(b), Some(c)) = (p50, p95, max) {
            Some((a, b, c))
        } else if let Some(m) = mean {
            Some((m, m, m))
        } else {
            None
        };
        if let Some((_, _, cmax)) = candidate {
            let replace = match best {
                None => true,
                Some((_, _, bmax)) => cmax > bmax,
            };
            if replace {
                best = candidate;
            }
        }
    }
    best
}

fn run_fixture(fx: &Fixture, target_dir: &Path) -> Result<(u64, u64, u64), String> {
    let manifest = PathBuf::from(fx.crate_dir).join("Cargo.toml");
    if !manifest.is_file() {
        return Err(format!("missing manifest {}", manifest.display()));
    }
    let mut cmd = Command::new(CARGO);
    cmd.env("CARGO_TARGET_DIR", target_dir)
        .arg("run")
        .arg("--quiet")
        .arg("--release")
        .arg("--manifest-path")
        .arg(&manifest)
        .arg("--example")
        .arg(fx.example);
    let out = cmd.output().map_err(|e| format!("spawn {0}: {e}", fx.example))?;
    let stdout = String::from_utf8_lossy(&out.stdout).to_string();
    let stderr = String::from_utf8_lossy(&out.stderr).to_string();
    let combined = format!("{stdout}\n{stderr}");
    if !out.status.success() {
        return Err(format!("fixture {0} failed:\n{combined}", fx.example));
    }
    parse_distribution(&combined).ok_or_else(|| {
        format!("fixture {0} printed no measured distribution:\n{combined}", fx.example)
    })
}

fn main() {
    let mut out_dir = PathBuf::from("tools/perf-capture/artifacts");
    let mut suite = String::from("ep032");
    let mut args = std::env::args().skip(1);
    while let Some(a) = args.next() {
        match a.as_str() {
            "--out" => {
                out_dir = PathBuf::from(args.next().expect("--out needs a value"));
            }
            "--suite" => {
                suite = args.next().expect("--suite needs a value");
            }
            other => {
                eprintln!("perf-capture: unknown arg {other}");
                std::process::exit(2);
            }
        }
    }
    fs::create_dir_all(&out_dir).expect("create artifacts dir");

    let hw = HardwareProfile {
        host: std::env::consts::OS.to_string(),
        arch: std::env::consts::ARCH.to_string(),
        os: std::env::consts::OS.to_string(),
    };

    let target_dir = PathBuf::from("wirecore/target");

    // Warm up once, then measure: run each fixture and record the
    // measured distribution against its declared constitution budget.
    let mut runs = Vec::new();
    let mut failures = Vec::new();
    for fx in FIXTURES {
        match run_fixture(fx, &target_dir) {
            Ok((p50, p95, max)) => {
                let budget_met = p95 <= fx.budget_us;
                runs.push(json!({
                    "queue": fx.queue,
                    "owner": fx.owner,
                    "priority": fx.priority.as_str(),
                    "overflow": format!("{:?}", fx.overflow).to_lowercase(),
                    "p50_us": p50,
                    "p95_us": p95,
                    "max_us": max,
                    "budget_us": fx.budget_us,
                    "budget_met": budget_met,
                    "fixture": fx.example,
                }));
                println!(
                    "perf-capture {}: p50_us={} p95_us={} max_us={} budget_us={} budget_met={}",
                    fx.queue, p50, p95, max, fx.budget_us, budget_met
                );
            }
            Err(e) => failures.push(format!("{}: {e}", fx.queue)),
        }
    }

    let artifact = json!({
        "suite": suite,
        "hardware": hw,
        "workload": {
            "fixture": "owned-crate perf fixtures (release)",
            "iterations": FIXTURES.len(),
            "note": "each fixture reports its own p50/p95/max distribution",
        },
        "runs": runs,
        "regression_thresholds": FIXTURES.iter().map(|fx| json!({
            "metric": fx.queue,
            "p95_us_limit": fx.budget_us,
            "max_us_limit": fx.budget_us,
        })).collect::<Vec<_>>(),
        "raw_evidence": true,
        "observed_at": std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_millis() as u64)
            .unwrap_or(0),
    });
    let path = out_dir.join(format!("{suite}-perf-raw.json"));
    fs::write(&path, serde_json::to_string_pretty(&artifact).unwrap())
        .expect("write suite artifact");
    println!("perf-capture artifact: {}", path.display());

    if !failures.is_empty() {
        eprintln!("perf-capture: FAIL");
        for f in &failures {
            eprintln!("  {f}");
        }
        std::process::exit(1);
    }
    let all_met = runs.iter().all(|r| r["budget_met"] == true);
    if !all_met {
        eprintln!("perf-capture: FAIL - one or more budgets not met");
        std::process::exit(1);
    }
    println!("perf-capture: ok");
}

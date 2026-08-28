//! EP-030 M4 performance fixture (SPEC-004, SPEC-027-R06).
//!
//! Runs the real production paths of wire-import — format detection,
//! traversal sanitization, plan construction (hash + parse + report) —
//! in release mode, records a real measured distribution, and asserts the
//! SPEC-004 P3 budget (5 ms worst observed). Raw artifact is written to
//! `wirecore/target/ep030-perf-raw.json`.

use std::time::{Instant, SystemTime, UNIX_EPOCH};

use wire_import::{finalize_report, plan_import, sanitize_entry_path};

const BUDGET_US: u128 = 5000;
const ITERATIONS: u32 = 2000;

fn now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

fn main() {
    let mut detect_times: Vec<u128> = Vec::with_capacity(ITERATIONS as usize);
    let mut sanitize_times: Vec<u128> = Vec::with_capacity(ITERATIONS as usize);
    let mut plan_times: Vec<u128> = Vec::with_capacity(ITERATIONS as usize);

    for i in 0..ITERATIONS {
        let xml = format!(
            r#"<?xml version="1.0"?><MudletPackage><trigger><name>t{i}</name></trigger><alias><name>a{i}</name></alias></MudletPackage>"#
        );

        let t0 = Instant::now();
        let format = wire_import::detect_format(&xml);
        detect_times.push(t0.elapsed().as_micros());
        assert_eq!(format, wire_import::SourceFormat::Mudlet);

        let t1 = Instant::now();
        let path = sanitize_entry_path(&format!("triggers/t{i}.xml")).unwrap();
        sanitize_times.push(t1.elapsed().as_micros());
        assert!(path.starts_with("triggers/"));

        let t2 = Instant::now();
        let plan = plan_import(&format!("profile-{i}.xml"), &xml, "backup.xml", "dest.xml").unwrap();
        let report = finalize_report(&plan, Some("diag.json".to_string()));
        assert!(report.automation_disabled);
        assert_eq!(report.source_hash.len(), 64);
        plan_times.push(t2.elapsed().as_micros());
    }

    let mut stats = |v: &[u128]| -> (u128, u128, u128) {
        let mut s = v.to_vec();
        s.sort_unstable();
        let p50 = s[s.len() / 2];
        let p95 = s[(s.len() as f64 * 0.95) as usize];
        let max = *s.last().unwrap();
        (p50, p95, max)
    };

    let (d50, d95, dmax) = stats(&detect_times);
    let (s50, s95, smax) = stats(&sanitize_times);
    let (p50, p95, pmax) = stats(&plan_times);

    println!("perf detect: p50_us={d50} p95_us={d95} max_us={dmax}");
    println!("perf sanitize: p50_us={s50} p95_us={s95} max_us={smax}");
    println!("perf plan: p50_us={p50} p95_us={p95} max_us={pmax}");
    println!("budget_us={BUDGET_US}");

    let worst = dmax.max(smax).max(pmax);
    let raw = serde_json::json!({
        "node": "EP-030",
        "hardware": {
            "host": std::env::consts::OS,
            "arch": std::env::consts::ARCH,
        },
        "workload": {
            "iterations": ITERATIONS,
            "detect": {"p50_us": d50, "p95_us": d95, "max_us": dmax},
            "sanitize": {"p50_us": s50, "p95_us": s95, "max_us": smax},
            "plan": {"p50_us": p50, "p95_us": p95, "max_us": pmax},
        },
        "threshold_us": BUDGET_US,
        "worst_us": worst,
        "budget_met": worst <= BUDGET_US,
        "observed_at": now_ms(),
    });
    let raw_dir = std::path::Path::new("wirecore/target");
    std::fs::create_dir_all(raw_dir).expect("create raw dir");
    std::fs::write(
        raw_dir.join("ep030-perf-raw.json"),
        serde_json::to_string_pretty(&raw).unwrap(),
    )
    .expect("write perf raw");

    if worst <= BUDGET_US {
        println!("perf fixture EP-030: ok");
    } else {
        eprintln!("perf fixture EP-030: FAIL worst_us={worst} exceeds budget_us={BUDGET_US}");
        std::process::exit(1);
    }
}

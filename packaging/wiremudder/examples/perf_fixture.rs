//! wire-release perf fixture: real measured distribution for the release
//! core hot paths (SPEC-004 P4 budget: 1 ms). Measures checksum
//! computation and artifact-dir verification over a real artifact set.
use std::time::Instant;

use wire_release::*;

fn main() {
    let tmp = std::env::temp_dir().join(format!("wire-release-perf-{}", std::process::id()));
    std::fs::create_dir_all(&tmp).unwrap();
    for name in STABLE_ARTIFACT_FILES {
        let bytes: Vec<u8> = (0..4096).map(|i| (i % 251) as u8).collect();
        std::fs::write(tmp.join(name), bytes).unwrap();
    }

    let n = 2000usize;
    let mut times: Vec<u128> = Vec::with_capacity(n);
    for _ in 0..n {
        let start = Instant::now();
        let artifacts = check_artifact_dir(&tmp, true).unwrap();
        assert_eq!(artifacts.len(), STABLE_ARTIFACT_FILES.len());
        times.push(start.elapsed().as_micros());
    }

    times.sort_unstable();
    let p50 = times[n / 2];
    let p95 = times[(n as f64 * 0.95) as usize];
    let max = *times.last().unwrap();
    let budget = 1000u128; // SPEC-004 P4 budget: 1 ms

    println!("perf release: p50_us={p50} p95_us={p95} max_us={max} budget_us={budget} samples={n}");
    if p95 > budget || max > budget {
        std::process::exit(1);
    }
    std::fs::remove_dir_all(&tmp).unwrap();
}

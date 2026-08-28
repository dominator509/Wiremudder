# WireMudder Performance, Benchmarks, Degradation, and Fairness — Design

Node: EP-032 (critical)
Dependencies: EP-009, EP-015, EP-023, EP-024, EP-025, EP-026
Owning specs: SPEC-004, SPEC-027
Owned features: WM-FEAT-0131, 0134..0145, 0163
Owned requirements: WM-SPEC-002-R07, 002-R09, 004-R12, 019-R10, 027-R06

## 1. Purpose

Run the full performance constitution, establish hardware baselines,
enforce P0/P1 budgets, validate queue behavior and session fairness, and
prove degradation of every optional subsystem — with raw artifacts and
regression thresholds (SPEC-004-R12, SPEC-027-R06).

## 2. Architecture

Two new boundaries:

### 2.1 `benchmarks/wiremudder/` — the SPEC-004 model crate

A deterministic Rust library encoding the constitution as testable
invariants:

- `PriorityRing` P0..P4 (SPEC-004-R01..R05).
- `Budget { time_us, memory_bytes, cancelable }` (R07).
- `BoundedQueue` with the seven declared overflow policies — Process,
  Coalesce, Drop, Defer, Pause, Disable, Quarantine — and observed
  metrics: processed, dropped, coalesced, deferred, quarantined,
  p50/p95/max latency (R06, R08).
- `FairnessGovernor`: per-session max work share with round reset so one
  busy session cannot starve another (R09).
- `DegradationState`: every degradation mode preserves raw text gameplay
  (R10, constitution prime directive).
- `BenchmarkArtifact`: hardware profile, workload, runs, regression
  thresholds, raw_evidence (R12/R06 shape).

### 2.2 `tools/perf-capture/` — the reproducible driver

A CLI that runs each owned crate's existing `perf_fixture` example in
release mode, parses the real measured distribution (three formats:
`p50_us=`, `p50=..us worst=..us`, and `mean_us=`), enforces the
worst-observed budget per R12, and writes one raw JSON artifact per suite
to `tools/perf-capture/artifacts/`.

## 3. Integration

No inherited Mudlet source is edited. The tool drives the real owned
crate fixtures:

| Queue | Owner | Ring | Budget | Overflow |
| --- | --- | --- | --- | --- |
| renderer-emits | renderer | P3 | 6000 µs | Coalesce |
| voice-jobs | voice | P3 | 5000 µs | Drop |
| import-plan | import | P2 | 5000 µs | Defer |
| replay-batch | replay | P4 | 5000 µs | Defer |
| bug-automation | bug-lab | P4 | 5000 µs | Defer |
| soundscape-transitions | soundscape | P3 | 5000 µs | Coalesce |

## 4. Commands and Observed Behavior

```
cargo test --manifest-path benchmarks/wiremudder/Cargo.toml        # 9 passed
cargo run --release --manifest-path tools/perf-capture/Cargo.toml -- \
  --suite ep032 --out tools/perf-capture/artifacts
```

Observed (2026-08-28, x86_64 linux, release):
- renderer-emits p95 34 µs / 6000 µs budget — met
- voice-jobs p95 14 µs / 5000 µs — met
- import-plan p95 13 µs / 5000 µs — met
- replay-batch p95 216 µs / 5000 µs — met
- bug-automation ≤ 8 µs / 5000 µs — met
- soundscape-transitions p95 2 µs / 5000 µs — met

## 5. Degradation and Fairness

The e2e priority-flood proves a P3 renderer-emit flood coalesces at its
bounded capacity while the P0 outbound queue keeps processing every item
with budget met and zero drops (constitution prime directive).

## 6. Security and Privacy

The model and tool hold no secrets, no network access, no process
execution beyond spawning cargo for the owned fixtures, and no authority.
Degradation never disables consent, redaction, command safety, or
signature verification (SPEC-004 security rule).

## 7. Rollback

- Model crate: remove `benchmarks/wiremudder/`.
- Driver: remove `tools/perf-capture/`.
- Tests/docs: remove `tests/wiremudder/ep032/`, `tests/wiremudder/performance/`,
  `docs/wiremudder/performance/`.

No inherited path is touched; rollback is fully within the node's new
boundaries.

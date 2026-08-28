# WireMudder Performance, Benchmarks, Degradation, and Fairness —
# Operations Runbook

Node: EP-032 (critical)

## Health

The benchmark model crate builds and its deterministic suite passes:

```
cargo test --manifest-path benchmarks/wiremudder/Cargo.toml   # 9 passed
```

The perf-capture driver runs all owned crate perf fixtures in release
mode and reports `perf-capture: ok` only when every fixture printed a
measured distribution and every budget was met:

```
cargo run --release --manifest-path tools/perf-capture/Cargo.toml -- \
  --suite ep032 --out tools/perf-capture/artifacts
```

## Readiness

Readiness for the performance gate is the raw artifact
`tools/perf-capture/artifacts/ep032-perf-raw.json`: it must exist,
contain hardware + workload + runs + regression thresholds, and every
run must have `budget_met: true`. The M4 regression-gate test enforces
this.

## Budgets (SPEC-004-R11)

| Metric | Budget |
| --- | --- |
| Manual command accepted | < 5 ms |
| Command queued for send | < 10 ms |
| Incoming text appended | < 10 ms |
| Emergency stop propagation | < 10 ms |
| Renderer optional work | 4-6 ms/frame |

Observed baselines may tighten but not silently loosen these goals. Any
change requires ADR with distributions, hardware profile, workload, and
raw evidence (WM-SPEC-004-R12).

## Disable

Disabling an optional subsystem is the constitution's fallback: set its
queue's overflow policy to `Disable` or `Drop` and its
`DegradationState` to `Disabled`. Raw text gameplay is never affected —
the model's `preserves_raw_text()` is invariant for every degradation
state.

## Recovery

- If a fixture fails to print a distribution: run the fixture directly
  (`cargo run --release --example perf_fixture --manifest-path
  wirecore/crates/<crate>/Cargo.toml`) and confirm it prints `perf ...`
  lines. The parser accepts `p50_us=`/`p95_us=`/`max_us=`, `p50=..us`
  `worst=..us`, and `mean_us=` formats; a new fixture must use one of
  these or extend the parser with evidence.
- If a budget is not met: do not weaken the threshold. Quarantine the
  slow rule (P1), reduce frequency or drop/coalesce (P2/P3), or defer to
  idle (P4). Re-run the gate.
- If `perf-capture` fails to spawn cargo: confirm `CARGO_TARGET_DIR`
  points at the workspace target dir and the owned crate manifests exist.

## Backup and Restore

The model and tool are source-only; the repository is the backup. No
runtime state is persisted beyond the raw artifacts, which are
regenerable by re-running the driver.

## Upgrade

- New benchmark fixture: add the crate's `examples/perf_fixture.rs`
  (existing pattern), register it in `tools/perf-capture/src/main.rs`
  `FIXTURES` with its ring, budget, and overflow policy, then re-run the
  suite and commit the new raw artifact with evidence.
- New queue type: extend `benchmarks/wiremudder/src/lib.rs` with a
  deterministic unit test first (TDD).

## Rollback

- Model crate: remove `benchmarks/wiremudder/`.
- Driver: remove `tools/perf-capture/`.
- Tests/docs: remove `tests/wiremudder/ep032/`,
  `tests/wiremudder/performance/`, `docs/wiremudder/performance/`.

No inherited path is touched by this node; rollback never crosses a
completed green tag.

## Security

The model and tool hold no secrets, no network access, no authority, and
no package permissions. perf-capture only spawns `cargo` for the owned
fixture manifests. Degradation never disables consent, redaction,
command safety, or signature verification (SPEC-004 security rule).

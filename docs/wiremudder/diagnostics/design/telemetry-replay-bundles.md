# WireMudder Telemetry, Replay, and Diagnostic Bundles — Design

## Overview

EP-028 implements local-first structured telemetry, bounded crash-safe
ring buffers, redaction, structured fingerprints and correlation IDs,
deterministic session replay, diagnostic bundles, and sanitized fixture
generation. All data stays local; no hosted telemetry, crash reporting,
or analytics endpoint is required for core operation (WM-SPEC-026-R08).

## Boundaries

- `wirecore/crates/wire-telemetry/` — capture engine: `TelemetryEngine`
  (off by default), `RingBuffer` (bounded), `Redactor` (corpus),
  `TelemetryEvent` (SPEC-019-R02 fields), `DataClass` (SPEC-023-R05),
  `TelemetryError` (SPEC-025-R02 stable error).
- `wirecore/crates/wire-replay/` — replay and bundles: `SessionReplay`
  (deterministic, versioned), `BundleBuilder` (redacted, previewable,
  content-addressed), `FixtureGenerator` (sanitized fixtures,
  dedup keys), `ReplayError`.
- `src/wiremudder/ui/diagnostics/` — passive Qt6 boundary pane surface.
- `schemas/wiremudder/telemetry/` — canonical JSON schemas.

## Key Behaviors

### Telemetry off by default (WM-SPEC-019-R01)

`TelemetryEngine::new` starts with `enabled = false`. Only an explicit
`enable()` call turns capture on; `record()` on a disabled engine is a
no-op. The diagnostics pane surfaces `captureEnabledByDefault() == false`.

### Bounded crash-safe ring buffers (WM-FEAT-0223)

`RingBuffer::new(capacity)` rejects zero and >65536. `push` evicts the
oldest event when full and returns the drop count. With a journal path,
every accepted event is appended to a local JSONL journal so a crash
loses at most the in-memory tail; `recover_journal` rehydrates the most
recent `capacity` events and stops at the first corrupt record
(fail-closed, never fabricates).

### Redaction corpus (WM-SPEC-019-R02, WM-SPEC-019-R05)

`Redactor::redact_text` is a single-pass scanner: it finds the earliest
corpus marker, consumes the marker plus separators and the inline value
token, and replaces the whole span with `[REDACTED]`. Because the marker
itself is consumed, the replacement can never be re-matched — no
infinite loop, no partial secret leakage. `redact_details` applies the
same rule recursively to detail maps/arrays.

### Fingerprints and correlation (WM-FEAT-0224)

`TelemetryEvent::fingerprint_for` hashes only structural fields
(subsystem, severity, feature, classification) — never payload content —
so deduplication works without private content (WM-FEAT-0227).
`TelemetryError` carries a `correlation_id` per instance.

### Deterministic replay (WM-SPEC-019-R04)

`SessionReplay` preserves `client_version` (app + 40-char git sha),
assigns monotonic `seq` at capture, and `replay_events()` emits strict
`seq` order. `content_hash()` is stable across serialization.

### Bundle preview matches export (WM-SPEC-019-R03, WM-SPEC-026-R07)

`BundleBuilder::build` serializes the redacted replay to canonical bytes,
hashes them (content address), and derives the preview from the same
redacted events. `export_bytes` returns the identical bytes, so the
preview is always a faithful redacted view of the export. The bundle
`approved_for_submission` flag starts false and flips only through
`approve()` (explicit user action).

### Sanitized fixtures (WM-FEAT-0128, WM-SPEC-019-R05)

`FixtureGenerator::generate` drops voice/transcript kinds unless the
caller approves them, redacts all remaining text, and bounds the fixture
at `MAX_FIXTURE_EVENTS`.

## Error Model (SPEC-025)

`TelemetryError` and `ReplayError` both carry: stable `code`, safe
`message`, `correlation_id`, `retry_class`, `user_action`,
`diagnostic_ref`, and redacted `internal_cause`.

## States (SPEC-025)

Loading, Ready, Disabled, Denied, Degraded, Canceled, Unavailable,
Error — surfaced by the diagnostics pane.

## Commands

- `cargo test --manifest-path wirecore/crates/wire-telemetry/Cargo.toml`
- `cargo test --manifest-path wirecore/crates/wire-replay/Cargo.toml`
- `cargo run --manifest-path wirecore/crates/wire-replay/Cargo.toml --example e2e_diagnostics`
- `g++ -std=c++17 -fPIC -c src/wiremudder/ui/diagnostics/diagnostics_boundary.cpp -I/opt/qt/6.8.2/gcc_64/include -I/opt/qt/6.8.2/gcc_64/include/QtCore -Wall -Wextra`

## Observed Behavior

- 11/11 wire-telemetry unit tests pass.
- 8/8 wire-replay unit tests pass.
- e2e example prints all six acceptance obligations and `e2e EP-028
  diagnostics-flow: ok`.
- Qt6 boundary compiles clean (`-Wall -Wextra`, zero warnings).

## Rollback

- `git checkout -- src/CMakeLists.txt` reverts the only inherited edit.
- Delete `wirecore/crates/wire-telemetry/`, `wirecore/crates/wire-replay/`,
  `src/wiremudder/ui/diagnostics/`, `schemas/wiremudder/telemetry/`
  (new files only).
- Fallback per node contract: keep local crash logs and manual text
  export only, with replay and external submission disabled.

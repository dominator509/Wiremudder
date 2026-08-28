# WireMudder Telemetry, Replay, and Diagnostic Bundles — Operations

## Health and Readiness

- **Core**: telemetry is disabled by default; core gameplay never depends
  on it. Health of the optional system is observable through the
  diagnostics pane state (Loading, Ready, Disabled, Denied, Degraded,
  Canceled, Unavailable, Error).
- **Readiness** means capture can accept events: `TelemetryEngine`
  constructed with a writable journal path (when persistence is on) and
  capture explicitly enabled.

## Start

1. Client starts with telemetry **off** (WM-SPEC-019-R01). No capture,
   no journal, no egress.
2. User explicitly enables capture in the diagnostics pane.
3. Optionally configure a journal path (crash-safe persistence). Events
   are appended as JSONL, bounded by ring capacity in memory.

## Stop / Disable

1. `disable()` stops capture immediately; further `record` calls are
   no-ops.
2. Disabling never deletes local data and never touches manual text
   gameplay (failure-8 proof).

## Recovery

- **Crash**: on restart, `recover_journal` rehydrates the most recent
  `capacity` events from the journal tail. Recovery stops at the first
  corrupt record — it never fabricates events (fail-closed).
- **Journal unavailable**: capture returns a typed `telemetry-journal`
  unavailable error; the in-memory buffer stays consistent (no partial
  effect).
- **Ring full**: the oldest event is evicted and the drop counter
  increments; the buffer never grows past capacity.

## Backup and Restore

- The journal file IS the crash-safe copy. Back up the journal path.
- Restore = point the engine at the backed-up journal and call
  `recover_journal`.

## Upgrade and Rollback

- Schemas are versioned (`schema_version: 1`); a version mismatch is
  rejected rather than migrated silently.
- Rollback: `git checkout -- src/CMakeLists.txt` reverts the only
  inherited edit; delete the new crates, schemas, and pane directory.
- Fallback (per node contract): keep local crash logs and manual text
  export only, with replay and external submission disabled.

## Diagnostics and Incident Triage

1. Check the diagnostics pane: severity counters, ring occupancy, drop
   and coalesce counters, bundle content hash.
2. Generate a sanitized fixture; verify the redaction corpus stripped
   markers and voice/transcript kinds (unless approved).
3. Build a diagnostic bundle; verify preview matches export and the
   content address matches the exported bytes.
4. If a secret appears in any preview/export: treat as P0, disable
   capture, quarantine the journal, and rotate the credential.

## Runbook Drill (SPEC-026-R06)

- Start with telemetry off: `TelemetryEngine::new` → `is_enabled() == false`.
- Enable: `enable()` → `record()` stores a redacted event.
- Kill the process mid-write: restart → `recover_journal` restores the
  tail.
- Delete the journal directory: next `record` fails closed with a typed
  error; gameplay unaffected.
- Approve a bundle: `approve()` flips `approved_for_submission`; without
  it the bundle can never be submitted.

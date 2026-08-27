# WireMudder Context Distillation and Token Budget Operations Runbook (EP-015 M4)

## Health and Readiness

- Crate health: `cargo test -p wire-context` (15 tests) and
  `cargo test -p wire-token-budget` (10 tests). Green means the
  deterministic grammar, routing, degradation, and validation invariants
  hold.
- Compatibility health: `sh compatibility/context/check.sh` prints
  `compatibility EP-015 M3 context: ok` when the locked corpus still
  maps to the exact typed-event tags.
- Evidence health: `.agent/state/evidence/EP-015/M4/performance-001.json`
  records per-line distillation latency and capsule size against budget.

## Disable

- Distillation is an optional system layered on the socket/terminal
  path. Disabling it never blocks manual text gameplay: the raw line is
  echoed first; distillation subscribes as a listener. A broken
  distiller yields typed errors or no events, never a hang.

## Recovery

- Divergent corpus (oracle fails): the deterministic grammar drifted.
  Restore the corpus expectations or fix the grammar rule; re-run
  `sh compatibility/context/check.sh`. AI extraction is never the
  recovery path - it stays disabled until EP-016.
- Budget misconfiguration: `TokenBudget` caps are data, not code; reset
  to `default_full()` and re-verify routing decisions with the unit
  tests.

## Backup and Restore

- Capsules and usage records persist through EP-014 storage. Use
  `wiremudder-backup.sh backup/export/verify` on the storage database
  exactly as documented in the EP-014 runbook. Restore = point the app
  at the verified snapshot file.

## Upgrade

- Schema changes go through `schemas/wiremudder/context/` with a bumped
  version constant in the owning crate. Version drift is caught by the
  M2 schema unit test.
- Back up storage before upgrading (backup-aware migration,
  WM-SPEC-023-R08).

## Rollback

- Revert the node commits. No inherited paths are edited, so rollback is
  a pure revert of namespaced code. Never cross a completed green tag.

## Diagnostics

- `PRAGMA integrity_check` on the storage database; `cargo test` for
  both crates; the corpus oracle for grammar integrity; perf evidence
  JSON for latency regressions.

## Incident Triage

1. Distillation stops producing events: run the corpus oracle; a
   divergence pinpoints the rule.
2. Budget dashboard full: bounded by design; typed `DashboardFull`
   tells callers to rotate or persist records to EP-014 storage.
3. Secret leak suspected: run the security matrix; `secrets-redacted`
   and `output-secret-rejected` must be ok; if not, redaction runs
   before any provider path is blocked.

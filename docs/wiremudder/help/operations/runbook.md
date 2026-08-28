# Contextual Help, Setup Coach, and Source Index — Operations (EP-027)

## Health and Readiness

- Health: the help engine is healthy when it can answer from the
  index. Observable via `index_len()`, `index_state_hash()`,
  `source_index_state()` counters, and the bounded audit trail
  (MAX_AUDIT=1024).
- Readiness: ready when the index contains at least one entry from an
  accepted source and mode is not Disabled.
- Help never blocks settings interaction or gameplay
  (WM-SPEC-018-R10): lookups are O(log n) over the index and measured
  under the 5 ms budget.

## Disable

Three independent disable paths (fail-closed):

1. `set_mode(Disabled)` denies all answers, coach proposes, and ask
   contexts (Denial::Disabled).
2. The fallback: ship static local help and field-level documentation
   links without AI or source indexing (node contract fallback).
3. Source indexing stays disabled until explicitly enabled (opt-in).

## Recovery

- Unavailable dependency: an ask context with no approved refs denies
  with UnavailableDependency; re-request with approved refs.
- Stale source: answer reports StaleSource when the source version
  differs from the app manifest; regenerate the index with
  `tools/help-indexer` to refresh.
- Secret-bearing file during indexing: skipped (SecretDetected) with a
  counter; the index remains intact. No partial state.
- Budget exhaustion: index/field-help/coach-step/source-index caps deny
  with QueueFull; counters stay consistent.

## Backup and Restore

- The Help Knowledge Index is reproducible: regenerate from accepted
  sources via `tools/help-indexer` (identical inputs → identical
  hash). Keep the accepted sources in version control.
- The source index is a local cache; resume from a checkpoint
  (resumable) or rebuild. Removal is explicit and complete
  (`remove_source_index`).

## Upgrade

- Schema versions are stable (`HELP_SCHEMA_VERSION = 1`). Upgrade by
  adding a new schema version; the engine validates inputs and reports
  stale/unavailable source evidence instead of guessing
  (WM-SPEC-018-R09).
- Rollback: `git checkout -- src/CMakeLists.txt` removes the boundary
  from the client build (discovered amendment rollback). The crate,
  schemas, and tool are additive and reversible by deletion.

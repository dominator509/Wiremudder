# WireMudder Deterministic Graph

## Rules

The graph is a finite DAG. One node is leased at a time. The line order is the deterministic tie-breaker. Status is derived from `.agent/state/LEDGER.md`. `scripts/graph-next.sh` is the dispatch authority.

## Machine Table

GRAPH-TABLE-BEGIN
NODE EP-000 DEPS -
NODE EP-001 DEPS EP-000
NODE EP-002 DEPS EP-001
NODE EP-003 DEPS EP-002
NODE EP-004 DEPS EP-003
NODE EP-005 DEPS EP-004
NODE EP-006 DEPS EP-005
NODE EP-007 DEPS EP-006
NODE EP-008 DEPS EP-007
NODE EP-009 DEPS EP-008
NODE EP-010 DEPS EP-009
NODE EP-011 DEPS EP-009
NODE EP-012 DEPS EP-009
NODE EP-013 DEPS EP-009
NODE EP-014 DEPS EP-006,EP-009
NODE EP-015 DEPS EP-009,EP-014
NODE EP-016 DEPS EP-006,EP-015
NODE EP-017 DEPS EP-008,EP-016
NODE EP-018 DEPS EP-006,EP-017
NODE EP-019 DEPS EP-008,EP-018
NODE EP-020 DEPS EP-013,EP-014,EP-017
NODE EP-021 DEPS EP-013,EP-014,EP-015
NODE EP-022 DEPS EP-010,EP-017,EP-021
NODE EP-023 DEPS EP-008,EP-009,EP-014
NODE EP-024 DEPS EP-006,EP-008,EP-016,EP-023
NODE EP-025 DEPS EP-012,EP-015,EP-021
NODE EP-026 DEPS EP-024,EP-025
NODE EP-027 DEPS EP-006,EP-012,EP-016
NODE EP-028 DEPS EP-003,EP-006,EP-014
NODE EP-029 DEPS EP-022,EP-028
NODE EP-030 DEPS EP-010,EP-013,EP-014
NODE EP-031 DEPS EP-012,EP-024,EP-025
NODE EP-032 DEPS EP-009,EP-015,EP-023,EP-024,EP-025,EP-026
NODE EP-033 DEPS EP-006,EP-008,EP-010,EP-011,EP-014,EP-016,EP-028,EP-030,EP-032
NODE EP-034 DEPS EP-010,EP-033
NODE EP-035 DEPS EP-031,EP-032,EP-034
NODE EP-036 DEPS EP-003,EP-011,EP-012,EP-023,EP-035
NODE EP-037 DEPS EP-010,EP-027,EP-030,EP-036
NODE EP-038 DEPS EP-029,EP-032,EP-033,EP-035,EP-036,EP-037
NODE EP-039 DEPS EP-038
GRAPH-TABLE-END

## Dispatch

- `NEXT EP-XXX`: acquire the lease and execute the node.
- `RESUME EP-XXX`: the node has an active lease; the holder continues or a stale lease is taken over under `.agent/LOOPS.md`.
- `BLOCKED EP-XXX`: terminal until the named human decision is resolved.
- `STALL EP-XXX`: graph defect; append NODE_BLOCKED with graph evidence.
- `ALL_DONE`: run EP-039 ship completion and append RUN_COMPLETE.

## Build Arc

Discovery and inherited baseline precede all implementation. Compatibility and schemas precede the bridge. Privacy, profiles, and command safety precede AI or automation. Classic parity and storage precede context and memory. AI precedes guarded assistance. Voice, renderer, and sound remain optional. Performance, security, update, installer, platform, documentation, release-candidate, and ship gates finish the graph.

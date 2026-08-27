# EP-007 Profiles and Routing — Operations

Node: EP-007. Verified 2026-08-27.

## Health and Readiness

- Profile store: `ProfileStoreQt` loads `profiles.json` from the chosen
  data directory. Missing file = clean empty store (first run). Corrupt
  file = load fails with a typed error; the store is left unchanged.
- Routing store: `RoutingStoreQt` loads `routing.json` from the chosen
  data directory. Same semantics.
- Routing decisions are pure-local and bounded (measured p95 0.018ms at
  100k iterations on the host); they never block on network I/O.

## Disable

- Clear the selected route (`remove` clears selection; `select` requires
  an existing valid route). With no selection, connections follow the
  inherited direct path — but a *selected* route is never silently
  bypassed (WM-SPEC-006-R06).
- Future route kinds (interface binding, VM/netns, self-hosted relay)
  are disabled by construction: constructing or selecting one returns
  `UnsupportedKind`.

## Restart and Cold Resume

- Persist both stores with `saveToDir`; on restart `loadFromDir` restores
  routes, selection, and profiles. Data is local-first JSON.
- Cold resume: run the boot sequence, confirm the lease, re-run the last
  checked milestone verifier subcommand.

## Backup and Restore

- Backup: copy the two JSON files (`profiles.json`, `routing.json`).
- Restore: place the files in the data directory and load. A corrupt
  restore fails closed — the stores refuse partial state.

## Upgrade

- Schema versions are constants (`PROFILE_SCHEMA_VERSION = 1`,
  `ROUTING_SCHEMA_VERSION = 1`). Any future version bump must migrate
  explicitly; a mismatched version is rejected on load/import.

## Rollback

- All EP-007 code lives in the four authorized boundaries; rollback is a
  clean `git revert` of the EP-007 commits or `git checkout` of the
  lease base `591057b7`. No inherited file is affected.
- Fixtures (`fixtures/echo_server.py`, `fixtures/socks5_relay.py`) are
  SIMULATION test-only servers bound to 127.0.0.1 and torn down by
  script traps; they never run in production paths.

## Security Notes

- Credentials never appear in routing audit entries or exports; the
  redacted route view omits the username field entirely (WM-FEAT-0092).
- AI, autopilot, scripts, packages, and plugins cannot create profiles
  or modify routing/AI defaults (WM-SPEC-006-R08, WM-FEAT-0173).

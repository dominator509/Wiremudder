# Classic Parity Operations (EP-009 M4)

## Health

- Parity oracle: `python3 compatibility/classic/parity_oracle.py --compare-all tests/wiremudder/classic`
  exits 0 when all fixtures agree, 1 on disagreement/validation error.
- Baseline build: `test -x build-linux-debug-nosan/src/mudlet`.
- Lua runtime: `command -v lua5.1`.

## Readiness

The parity layer is ready when the corpus agrees and the mudlet baseline
binary is present. Readiness is declared by
`tests/wiremudder/ep009/e2e/001-parity-flow.sh` (corpus agreement,
determinism, degraded-optional preservation).

## Disable

The oracle is a read-only checker; it never gates manual gameplay.
Removing `compatibility/classic/` and `tests/wiremudder/classic/` disables
parity checking without affecting the inherited client. There is no
runtime hook that depends on the oracle.

## Recovery

- Malformed fixture: oracle exits 1 with the fixture id; repair the JSON
  and re-run.
- Corpus disagreement: read the oracle reason, determine whether the
  WireMudder trace or the reference trace is wrong, fix under source
  evidence, re-run.
- Oracle crash: stdlib-only; reinstall nothing. Re-run.

## Backup and Restore

Fixtures are version-controlled. Restore any fixture from git:
`/usr/bin/git checkout -- <path>`.

## Upgrade

Adding fixtures is additive. Adding a new compatibility level requires a
decision-log entry and an oracle unit test.

## Rollback

Revert the last milestone commit:
`/usr/bin/git revert --no-edit <commit>`.
No state is mutated by the oracle; rollback is clean.

## Measured Baseline (2026-08-27)

See `.agent/state/evidence/EP-009/M4/oracle-latency.json` for the
distribution (p50/p95/p99/mean) and raw sample file. Budget: 10 ms per
fixture verdict (P4 check-time path).

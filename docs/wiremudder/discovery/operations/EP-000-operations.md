# WireMudder Discovery Operations — EP-000

## Health

- `sh scripts/validate-blueprint.sh` prints `blueprint validation: ok` (545 authority files).
- `sh scripts/preflight.sh` prints `preflight: ok`.
- `sh scripts/graph-next.sh` prints a dispatch line, not `STALL`.

## Readiness

A node is ready to work when: lease acquired, ledger tail shows
`LEASE` for the node, `validate-blueprint.sh` and `preflight.sh` both
pass, and `node-contract-check.sh EP-XXX` prints ok.

## Disable

Optional providers are disabled by leaving their keys empty in `.env`
(see PREFLIGHT.md). The discovery node itself has no external
dependencies and cannot be disabled without failing the graph.

## Recovery and Restart

1. Run the boot sequence (AGENTS.md section 2).
2. `sh scripts/ledger.sh tail 40` to find the last milestone.
3. Re-run the last checked milestone verifier subcommand.
4. Continue at the first unchecked milestone.

## Backup and Restore

- The discovery state is fully in-git: `.agent/state/LEDGER.md`,
  `.agent/state/source-evidence.jsonl`, `.agent/state/upstream-tree.tsv`,
  `.agent/state/COMMANDS.lock.tsv`, and `.agent/state/evidence/`.
- Backup = a git tag or commit; restore = checkout the tag and re-run
  `preflight.sh`.

## Upgrade and Rollback

- Upgrade the pinned baseline only through an accepted upstream sync
  (SPEC-001-R06) on a dedicated branch with gates before merge.
- Rollback = `git revert` of the last milestone commit; never cross a
  completed `green/EP-XXX` tag.

## Incident Response

- Evidence hash drift: re-run `source-evidence-check.sh`; if a record is
  corrupt, restore from git and re-record with the same command.
- Scope violation: `scope-audit.sh EP-XXX` lists unauthorized paths;
  revert them, then re-verify.
- Truncated inventory file: regenerate with
  `tests/wiremudder/ep000/unit/gen_upstream_tree.py` and re-run unit 001.

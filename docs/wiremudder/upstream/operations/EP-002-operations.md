# WireMudder Upstream Governance Operations — EP-002

## Health

- `sh scripts/validate-blueprint.sh` prints `blueprint validation: ok`.
- `git remote -v` shows upstream=Mudlet and origin=dominator509/Wiremudder.
- `sh scripts/graph-next.sh` prints a dispatch line.

## Readiness

Governance is ready when: remotes are unambiguous, patch classification
runs (`tests/wiremudder/ep002/unit/classify_patch.py`), and
`green/EP-001` exists.

## Sync Drill

1. `git fetch upstream development`
2. `git switch -c sync/drill-<id>`
3. Merge or cherry-pick the controlled upstream change.
4. Run gates: `sh scripts/validate-blueprint.sh`, `sh scripts/preflight.sh`,
   `sh scripts/node-verify.sh <active>`.
5. On green, merge to `wire/development`, record before/after SHAs
   (SPEC-001-R09), push.
6. On failure, `git switch wire/development`, delete the sync branch.
   The previous green tag stays intact (SPEC-001-R10).

## Recovery and Restart

- A failed sync never promotes: return to the last green tag.
- Rollback = `git revert`; never cross a completed green tag.
- Cold resume: run the boot sequence, re-run the last checked milestone.

## Backup and Restore

- Origin (github.com/dominator509/Wiremudder) mirrors the branch and
  green tags. Local state is in-git under `.agent/state/`.

## Incident Response

- Merge conflict during sync: abort with `git merge --abort`, record the
  conflict, classify the change, and re-plan the drill.
- Green tag missing: check `git tag -l 'green/*'` and the ledger; do not
  proceed past a missing completion proof.
- Remote secret leak: remove the file, rotate any exposed credential,
  and add a blocking rule to `.gitignore`.

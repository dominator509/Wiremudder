# EP-008 Command Safety — Operations

Node: EP-008. Verified 2026-08-27.

## Health and Readiness

- Gateway readiness: the command database must be non-empty (world set)
  and at the current schema version. A stale/unavailable database makes
  `propose()` fail with `CommandDatabaseUnavailable` — automation pauses
  rather than guessing (WM-SPEC-009-R10).
- Emergency stop state is a single global boolean; `blocks()` is an O(1)
  read that never stalls P0 (WM-SPEC-004-R01/R09/R11). Measured
  propagation 15us on the host (budget 10ms).

## Disable

- Set `profile_automation_enabled=false` in the gate context: all
  non-manual proposals are denied (`AutomationDisabled`). Manual input
  is unaffected (WM-SPEC-009-R01).
- Remove rules or clear the world from the command database to pause
  automation.

## Restart and Cold Resume

- The gateway is in-memory; audit and queue state are not persisted by
  this node (persistence is owned by later nodes EP-014/EP-023). Cold
  resume: re-run the boot sequence, confirm the lease, re-run the last
  checked milestone verifier subcommand.

## Emergency Stop

- Engage: `engageEmergencyStop()` — cancels the visible queue, sets the
  global flag, blocks new proposals, and records the cancellation in the
  audit. Release: `releaseEmergencyStop()`.
- Manual disconnect and shutdown controls remain available while the
  emergency stop is engaged (WM-SPEC-017-R08).

## Backup and Restore

- Command database rules are code/config in this node (world rules are
  seeded per world in later nodes). Rebuild by re-running the rule
  registration; no user data is at risk in this node.

## Upgrade

- Schema versions are constants (`ACTION_SCHEMA_VERSION = 1`,
  `POLICY_SCHEMA_VERSION = 1`). A version bump must migrate explicitly;
  mismatched versions fail closed.

## Rollback

- All EP-008 code lives in the four authorized boundaries. Rollback is a
  clean `git revert` of the EP-008 commits or `git checkout` of the
  lease base `41e6fc97`. No inherited file is affected.

## Security Notes

- Prompt injection cannot override the gate (WM-SPEC-022-R04): the
  injection-flagged context denies all proposals, and suggestion text is
  opaque data — only the normalized command is policy-looked-up.
- No high-confidence shortcut exists (WM-SPEC-009-R05): the only send
  path re-evaluates the full gate; denied commands never send.
- Audit records are complete and replayable (WM-SPEC-009-R09): every
  proposal carries source, suggestion, normalized command, tier,
  approval requirement, pacing decision, and final result.

# Operations

This page is the user-facing summary of the operations runbooks. The full
procedures live in the [Operations Runbook](../operations/runbook.md).

## Backup

Your profile, worlds, triggers, aliases, timers, macros, maps, packages,
and settings can be backed up to a local archive. The backup is verified by
hash after creation.

## Restore

Restoring from a backup returns your profile to the backed-up state.
Restore is a real, tested path (WM-SPEC-028-R04): your data is preserved
and the backup is validated before anything is overwritten.

## Rollback

If an update or configuration change breaks something, roll back to the
previous version or the previous backup. The rollback procedure is
documented and drilled (WM-FEAT-0243).

## Incident Runbooks

Incident runbooks cover start, stop, health, recovery, backup, restore,
upgrade, rollback, disable, diagnostics, and incident triage
(SPEC-026-R06). Each runbook states the exact command, the expected
sentinel, and how to verify recovery.

## Disable

Optional systems (AI providers, voice, renderer, telemetry, autopilot) can
be disabled without affecting manual gameplay. The core classic client
keeps working with every optional subsystem disabled (SPEC-000-R03).

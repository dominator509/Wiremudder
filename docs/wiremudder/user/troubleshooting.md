# Troubleshooting

If something is not working, work through this page in order. The exact
diagnostic commands are in the [Operations Runbook](../operations/runbook.md).

## The client starts but the terminal is empty

1. Check the connection status in the toolbar. If it is disconnected,
   reconnect to the world.
2. Check the profile's server address and port.
3. Check the logs for a connection error (see [Telemetry](telemetry.md)).

## A trigger or alias does not fire

1. Check that the item is enabled.
2. Check the pattern against the actual line using the Trigger Test Lab
   (WM-SPEC-008-R07).
3. Check the script editor for syntax errors.
4. Check whether the script exceeded its budget — look for a slow-offender
   diagnostic in the support bundle.

## A package does not load

1. Check the manifest: it must declare version, provenance, license,
   content hash, requested permissions, update policy, and supported
   WireMudder/Mudlet versions (WM-SPEC-008-R03).
2. Check that you approved the requested permissions (WM-SPEC-008-R04).
3. Check the content hash — a modified archive will be rejected.

## An update caused a problem

Roll back to the previous version. The rollback preserves your profile and
data (WM-SPEC-028-R04). See [Updates](updates.md) and
[Operations](operations.md).

## I want to share a problem with a maintainer

Create a support bundle and preview it before sharing. Secrets and private
content are redacted (SPEC-026-R07). See [Telemetry](telemetry.md).

## The client is slow

Check the performance page for budgets and degradation behavior
(WM-FEAT-0239). Optional systems (AI, voice, renderer) can be disabled
without affecting manual gameplay.

## Manual gameplay is never interrupted

Optional systems fail independently of the manual gameplay path. If
anything optional degrades or fails, you can keep playing by typing
commands in the terminal.

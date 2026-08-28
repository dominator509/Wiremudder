# Updates

WireMudder updates through signed update manifests. The client verifies the
signature and content hash before applying anything (WM-FEAT-0187).

## Update Policy

- **Auto** — updates are applied automatically up to a declared major
  version limit. You choose the limit when you approve the update policy.
- **Manual** — the client notifies you; you choose when to install.
- **Never** — updates are not installed. You can still install a new
  version manually.

A package or the client cannot silently change its update policy to
something more permissive than you approved (WM-SPEC-008-R05).

## Rollback

If an update causes a problem, you can roll back to the previous version.
The rollback is a real, tested path (WM-SPEC-028-R04): your profile and
data are preserved, and the previous manifest is restored. See
[Operations](operations.md) for the step-by-step runbook.

## What Updates Cannot Do

- They cannot expand package permissions without renewed approval.
- They cannot send your data anywhere.
- Auto-deployment is disabled by default; release signing remains
  maintainer-controlled (SPEC-000-R10).

# Package Author Guide

This guide documents how to write a WireMudder package that loads safely
and passes the real validation gates. It is the authoritative reference for
the package manifest, permissions, and update policy (WM-SPEC-008-R03/R04/R05).

## What a Package Is

A package is an archive or directory of automation assets — triggers,
aliases, timers, macros, maps, themes, sounds, Soul templates, or help
indexes — accompanied by a manifest that declares exactly what the package
is and what it may access (WM-SPEC-008-R08).

## The Manifest

Every package must have a manifest at `manifest.json` matching
`schemas/wiremudder/packages/manifest.schema.json`. The manifest is
validated before anything is loaded. It requires:

- `name` — the package name.
- `version` — the package version.
- `provenance` — either `user_local` (author + added_at) or `signed`
  (signer + signature).
- `license` — the license identifier.
- `content_sha256` — the hex SHA-256 of the packaged content (64 hex
  chars).
- `requested_permissions` — an array of permission names.
- `update_policy` — `never`, `manual`, or `auto` with a `max_major` limit.
- `compatibility` — supported `wiremudder` and `mudlet` versions.

Example: [examples/wiremudder/manifest.example.json](../../../examples/wiremudder/manifest.example.json).

## Permissions

Permissions cover **filesystem, network, microphone, ai_egress, secrets,
routing, updater, telemetry, ui, command_send, memory, renderer, and
audio** access (WM-SPEC-008-R04). The default is **deny**.

- List only the permissions your package actually needs.
- Every requested permission is shown to the user for approval at install.
- The user can deny any permission; the package must degrade gracefully.
- Your package must not access anything it did not request.

The permission firewall is enforced by the real `wire-packages` core. The
oracle CLI demonstrates the exact decision semantics:

```
wire-packages-oracle decisions "" "network,secrets,command_send"
# -> all three denied; expansion = all three

wire-packages-oracle decisions "network" "network,secrets,command_send"
# -> network granted; secrets and command_send denied; expansion = those two
```

`expansion` is the set of permissions requested but not yet approved. It is
reported to the user at install.

## Update Policy

- `never` — the package is not auto-updated.
- `manual` — the user is notified and chooses when to update.
- `auto` — updates are applied automatically up to `max_major`; a higher
  major version requires renewed approval.

**Updates cannot silently expand permissions.** If a new version requests a
permission the user has not approved, the update stops and asks for renewed
approval, showing exactly which permissions are new (WM-SPEC-008-R05).

## Content Hash

The `content_sha256` must match the actual packaged content. The client
verifies the hash before extraction (case-insensitive). A modified archive
is rejected. The hash verification is a real, tested path:

```
wire-packages-oracle hash <expected> <actual>   # -> verified | mismatch
```

## Imported Automation

If your package contains imported automation, it starts **disabled** or
behind a confirmation gate, and the user sees a migration report before
anything becomes active (WM-SPEC-008-R06).

## Safety Rules

- Package extraction prevents traversal, symlink escape, oversized files,
  and executable surprise (SPEC-008 Security).
- A plugin crash cannot terminate an active session; a runaway hook is
  quarantined (WM-SPEC-008-R10).
- Package checks and indexing are P4 and pause during active play
  (SPEC-008 Performance).

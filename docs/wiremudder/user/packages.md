# Packages

A package bundles automation, triggers, aliases, maps, themes, sounds,
Soul templates, or help indexes with a signed or user-local
provenance-aware manifest (WM-SPEC-008-R08).

## Installing

Install a package from an `.mpackage` archive or a directory containing a
manifest. Before anything is loaded, the client validates the manifest
(version, provenance, license, content hash, requested permissions, update
policy, and supported WireMudder/Mudlet versions per WM-SPEC-008-R03) and
verifies the content hash.

## Permissions

When you install a package, you are shown the permissions it requests.
Permissions cover filesystem, network, microphone, AI egress, secrets,
routing, updater, telemetry, UI, command send, memory, renderer, and audio
access. Everything defaults to deny; you must explicitly approve what the
package may use (WM-SPEC-008-R04). You can deny any permission and the
package still runs, minus that capability.

## Updating

Package updates cannot silently expand permissions. If a new version
requests more than you previously approved, the client stops and asks for
renewed approval (WM-SPEC-008-R05). You are told exactly which permissions
are new.

## Imports

Imported automation from other clients starts **disabled** or behind a
confirmation gate, and the client shows you a migration report before
anything becomes active (WM-SPEC-008-R06). See [Imports](imports.md).

## Removing

Removing a package removes its files and revokes its permissions. Your
profile data and manual gameplay are not touched.

## Package Authoring

If you write packages, see the [Package Author Guide](../package-author/README.md)
for the manifest format, permission semantics, and update policy rules.

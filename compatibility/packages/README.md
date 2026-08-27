# Package Compatibility Conventions (compatibility/packages)

Oracle and fixture conventions for SPEC-008 / EP-010 package handling.

## Purpose

WireMudder imports packages through the inherited dlgPackageExporter /
dlgPackageManager surface (WM-SRC-000076..000079). This tree defines how
package manifests are validated, how permissions are firewalled
(default deny), and how imports start disabled or confirmation-gated.

## Package Manifest

See `schemas/wiremudder/packages/manifest.schema.json`. Every package
declares: name, version, provenance (user-local or signed), license,
content hash, requested permissions, update policy, and compatibility
(WM-SPEC-008-R03).

## Permission Firewall (WM-SPEC-008-R04)

Permissions default deny. Categories: filesystem, network, microphone,
ai_egress, secrets, routing, updater, telemetry, ui, command_send,
memory, renderer, audio. A package runs only with the permissions
explicitly granted. Expansion (WM-SPEC-008-R05) requires renewed
approval.

## Import Gate (WM-SPEC-008-R06)

Imported automation starts disabled or pending confirmation and displays
a migration report. No untrusted import executes automatically.

## Quarantine (WM-SPEC-008-R10)

A plugin crash cannot terminate an active session; a runaway hook is
quarantined and cannot run until explicitly released.

## Enforced Provenance (WM-SPEC-020-R05)

License, content hash, and compatibility are enforced before install.
Hash mismatch rejects the package.

# WireMudder Platform Compatibility Matrix (EP-036)

Certification follows SPEC-027-R08: Windows, macOS, and Linux certification
uses clean builds, tests, packaging, upgrade, rollback, and smoke evidence.
A platform is "certified" only with complete green evidence; otherwise it is
development-only and unadvertised (EP-036 fallback).

## Linux

- **Status**: certified (this host; real evidence in
  `.agent/state/evidence/EP-036/` and `tests/wiremudder/platform/`).
- Clean build (zero warnings): release core, updater core.
- Full unit suites pass.
- Installer smoke passes (launch + user-data preservation on upgrade).
- Packaging: source archive, binary, checksums, SBOM, provenance.

## Windows

- **Status**: development-only (no host evidence in this environment).
- Required evidence for certification:
  1. Clean build of the release core and updater core on Windows (MSVC).
  2. Full unit suites pass on Windows.
  3. Installer (Windows) launches and preserves user data on upgrade.
  4. Post-install smoke passes.
- Until the above evidence exists, Windows is not advertised as certified.

## macOS

- **Status**: development-only (no host evidence in this environment).
- Required evidence for certification:
  1. Clean build of the release core and updater core on macOS (Clang).
  2. Full unit suites pass on macOS.
  3. Installer (macOS) launches and preserves user data on upgrade.
  4. Post-install smoke passes.
- Until the above evidence exists, macOS is not advertised as certified.

## Upstream Sync

- The pinned upstream commit (`UPSTREAM.lock.yaml`, `development_commit`)
  must remain an ancestor of HEAD before every stable release (SPEC-001).
- Upstream sync regression is rehearsed and must pass the compatibility
  surface before certification (SPEC-028-R09).

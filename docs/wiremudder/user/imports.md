# Imports and Governance

## Imports

Migrating from another client is safe and reversible.

- Mudlet profile, package, module, map, script, trigger, alias, timer,
  macro, layout, theme, and related formats are discovered from the pinned
  source and fixtures — never guessed (SPEC-021-R01).
- Every import creates a source hash, format version, provenance record,
  backup, normalized result, warning list, unsupported-item list, and
  rollback path (SPEC-021-R03).
- Imported automation, network access, package permissions, AI access,
  routing references, microphone access, and external calls start
  **disabled** until you review them (SPEC-021-R04).
- A failed import leaves the original and destination unchanged except for
  a removable diagnostic report (SPEC-021-R09).

Other clients (MUSHclient, TinTin++, zMUD/CMUD) and generic JSON, CSV, and
YAML paths have separate compatibility and legal review tracks
(SPEC-008-R09, SPEC-021-R02). Their status is documented honestly in the
[Compatibility Matrix](../../../compatibility/platform/matrix.md) and the
feature index.

## Governance

- **Contribution** — see the [Developer Guide](../developer/README.md) and
  the inherited CONTRIBUTING.md at the repository root.
- **Upstream** — WireMudder tracks the pinned Mudlet fork. Upstream sync is
  rehearsed before every stable release (SPEC-028-R09). See
  [docs/wiremudder/upstream/](../../upstream/).
- **Licensing** — the client preserves the Mudlet license and attribution.
  Third-party licenses are recorded in the SBOM (WM-FEAT-0246).

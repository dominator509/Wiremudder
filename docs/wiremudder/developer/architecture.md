# Developer: WireCore Architecture

WireMudder preserves the Mudlet-derived foundation and adds isolated
WireCore services behind narrow, evidence-backed boundaries.

## Layers

```
Mudlet-derived client (src/)  <-  inherited Qt/C++ runtime, manual gameplay
        |  (bridge)
WireCore Rust services (wirecore/crates/*)
        |  (schemas)
Canonical schemas (schemas/wiremudder/*)
```

## The Bridge

The bridge is the narrow channel between the Qt client and WireCore. It
stays minimal by design. Every message across the bridge has a schema and
a correlation ID.

## Service Boundaries

Each WireCore crate owns a coherent domain and exposes deterministic
oracle CLIs for cross-implementation checks:

- `wire-packages` — package firewall, quarantine, hash verification.
- `wire-updater` — signed manifests, verification, rollout, rollback.
- `wire-release` — deterministic artifact packaging and checksums.
- `wire-security` — threat model, secrets, injection guard, SBOM.
- `wire-agents` — Soul documents, permission checks, council.
- `wire-help` — Help Knowledge Index, Setup Coach, source index.

## C++ Boundaries

Where the Qt client must interact with WireCore, a small header under
`src/wiremudder/<domain>/` declares the same semantics as the Rust core.
Compile-time invariant tests confirm agreement.

## Data Flow

- Input enters through the client, is normalized to a schema, and crosses
  the bridge with a correlation ID.
- WireCore validates, decides, and returns a typed result.
- Optional systems never enter the manual gameplay path.

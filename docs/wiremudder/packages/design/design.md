# Package Sandbox Design (EP-010 M3)

## Architecture

```
package archive / manifest (schemas/wiremudder/packages/manifest.schema.json)
   |
   v
manifest validation (WM-SPEC-008-R03)
   |
   v
content hash verification (WM-SPEC-020-R05, Rust oracle + C++ boundary)
   |
   v
PermissionFirewall (WM-SPEC-008-R04, default deny; Rust core + C++ header)
   |  expansion -> renewed approval (WM-SPEC-008-R05)
   v
import gate -> Disabled | PendingConfirmation (WM-SPEC-008-R06)
   |
   v
Quarantine for runaway hooks (WM-SPEC-008-R10)
```

## Integration Points

1. **Rust core** - `wirecore/crates/wire-packages/` implements the
   firewall, quarantine, hash verification, and manifest model with 7
   unit tests. The oracle binary (`wire-packages-oracle`) exposes
   deterministic decisions for cross-implementation checks.
2. **C++ boundary** - `src/wiremudder/packages/package_boundary.h`
   declares the same semantics for the Qt layer: `PermissionFirewall`,
   `Quarantine`, `ImportState`, `verifyContentHash`. Compile-time
   invariant tests confirm agreement with the Rust core.
3. **Schemas** - `schemas/wiremudder/packages/manifest.schema.json`
   enforces the manifest contract.
4. **Import gate** - untrusted imports start `Disabled` or
   `PendingConfirmation`; nothing executes automatically.

## Observed Behavior (2026-08-27)

- Oracle: `decisions "" "network,secrets,command_send"` -> all denied,
  expansion = all three.
- Oracle: `decisions "network" "network,secrets,command_send"` -> network
  granted, secrets+command_send denied, expansion = secrets+command_send.
- Hash: `ABC123` vs `abc123` verified (case-insensitive); mismatch
  detected.
- The package layer declares no hook into `commandSubmitted` or
  `sendData` - the manual command path is untouched (P0 preserved).

## Rollback

All artifacts are additive under namespaced boundaries
(`src/wiremudder/packages/`, `wirecore/crates/wire-packages/`,
`schemas/wiremudder/packages/`, `compatibility/packages/`). Reverting the
M3 commit removes them without touching inherited source.

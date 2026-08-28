# WireMudder Security, Threat Model, License, SBOM, and Supply Chain — Operations Runbook

Node: EP-033 · Owning specs: SPEC-001, SPEC-020, SPEC-022, SPEC-027, SPEC-028

## Health

- Crate unit suite: `cargo test --manifest-path security/wiremudder/Cargo.toml`
  → `33 passed`.
- Shared repo secrets gate: `sh tests/wiremudder/security/001-repo-secrets-gate.sh`
  → `security shared-boundary secrets-gate: ok`.
- Node verifier: `sh scripts/node-verifiers/EP-033.sh verify` → all M1–M5
  subcommands then completion checks.

## Readiness

The security core is ready when:

1. The crate builds with zero warnings.
2. The real inventory (`sbom/wiremudder/inventory.json`) covers source,
   dependency, and submodule provenance with the license gate passing.
3. The SBOM artifact (`sbom/wiremudder/sbom.json`) is reproducible
   (identical document SHA-256 across runs).
4. The threat model fixture validates with every trust boundary mitigated.
5. The tracked tree has no secret-shaped material outside documented zones.

## Secret Findings

1. Run `wiremudder-security scan-secrets <path>` or the shared gate.
2. Any finding exits nonzero; the scanner prints the count only, never the
   value (redaction is applied before display).
3. Inspect the finding location, remove the material, and route credentials
   through the Secrets Vault (wire-secrets crate, SPEC-010).
4. Re-run the scan to confirm zero findings.

## Prompt-Injection Denials

1. Untrusted content that fails `check-injection` is denied at the boundary.
2. The denial is typed (Direct/Indirect/Encoded/Roleplay/ToolUse/
   MemoryPoisoning) and never overridable by the content itself.
3. Record the denial in the audit log; gameplay continues.

## SBOM and License Refresh

1. Rebuild inventory from `.gitmodules` and crate manifests
   (`sbom/wiremudder/inventory.json`).
2. Regenerate the SBOM: `wiremudder-security sbom sbom/wiremudder/inventory.json`.
3. Verify reproducibility: run twice, compare document SHA-256.
4. Confirm the license inventory carries the GPL source obligations
   (`licenses/wiremudder/licenses.json`).

## Disable

The security core is optional and namespaced. To disable:

1. Remove the `security/`, `sbom/`, and `licenses/` boundaries.
2. The inherited Mudlet build and manual text gameplay are unaffected
   (no inherited source paths are edited by this node).

## Recovery

- **Failed scan** (nonzero): remove findings, re-run scan, re-run the shared
  gate, then re-run `sh scripts/node-verifiers/EP-033.sh M4`.
- **SBOM drift**: regenerate from the committed inventory; the document hash
  is deterministic for identical inputs.
- **Rollback**: `git revert` the last milestone commit; the node is additive
  and reversible. Never cross a completed green tag.

## Backup / Restore

- The inventory, SBOM, and license artifacts are generated from committed
  fixtures and source; regenerate rather than restore.
- The ledger and evidence under `.agent/state/` are the durable record; do
  not edit by hand (append-only).

## Upgrade / Rollback

- Upgrades follow Graphlock contracts (SPEC-028-R08): same fences, tests,
  evidence, and rollback discipline as initial development.
- A failed update leaves the previous green tag intact (SPEC-020-R04,
  SPEC-001-R10).

## Release Blocking

- `ReleaseBlocker` evaluates findings; any critical security finding, secret
  leak, signature failure, or emergency-stop failure blocks release
  (SPEC-028-R03).
- A blocking verdict is a STOP condition for the release lane until fixed or
  explicitly accepted by a human maintainer (SPEC-022-R10).

# WireMudder Security, Threat Model, License, SBOM, and Supply Chain — Design

Node: EP-033 · Owning specs: SPEC-001, SPEC-020, SPEC-022, SPEC-027, SPEC-028

## 1. Purpose

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore
services. This node delivers the deterministic security core that protects
users from hostile servers, packages, providers, updates, prompt injection,
data leakage, hidden automation, and resource exhaustion — and the
supply-chain, SBOM, license, and release-blocking evidence the release lanes
require.

## 2. Trust Boundaries

| Boundary | Direction | Mitigation | Evidence |
|---|---|---|---|
| session-bridge | network input → core processing | bounded frame sizes, typed errors | `security/wiremudder/src/threat.rs` |
| prompt-boundary | untrusted content → policy | fail-closed injection guard | `security/wiremudder/src/injection.rs` |
| package-boundary | package/plugin code → core authority | path validation, least privilege | `tests/wiremudder/security/` |
| secrets-boundary | credentials → logs/context | scanner + redaction | `security/wiremudder/src/secrets.rs` |
| update-boundary | update metadata → install | signed/hash/provenance gates | `security/wiremudder/src/sbom.rs` |

## 3. Threat Model

The authoritative machine-validated threat model is
`tests/wiremudder/ep033/fixtures/threat-model-session-bridge.json`. It covers
SPEC-022-R08 elements: data flow, assets, actors, entry points, trust
boundaries, misuse cases, mitigations, residual risk, and verification. Every
trust boundary is explicitly covered by a mitigation, and the model fails
validation if any category is missing.

## 4. Core Components

- `wiremudder-security` crate (`security/wiremudder/`) — deterministic rules:
  - `PromptInjectionGuard` — direct, indirect, encoded, roleplay, tool-use,
    memory-poisoning markers; policy-level override denial.
  - `SecretsScanner` — private key blocks, AWS access key ids, OpenAI-style
    keys; fail-closed findings and redaction.
  - `ThreatModel` — SPEC-022-R08 completeness + boundary mitigation checks.
  - `SupplyChainInventory` — source, dependency, submodule, binary, model,
    voice, audio, visual, package, installer, update provenance with license
    gate.
  - `SbomBuilder` — reproducible, hash-anchored SBOM documents.
  - `LicenseInventory` — GPL/source obligations and canonical notices.
  - `UpdateLane` / `LanePolicy` — nine separate update lanes; optional assets
    never silently enabled.
  - `ReleaseBlocker` — critical findings block release.

## 5. CLI

`wiremudder-security` subcommands (all fail closed):

| Command | Behavior |
|---|---|
| `scan-secrets <path>` | scan a tree; exits 1 on findings |
| `check-injection <text>` | deny fail-closed on markers |
| `sbom <inventory.json>` | build reproducible SBOM |
| `threat-model <json>` | validate completeness + mitigations |
| `lanes` | print nine-lane policy |
| `release-block <json>` | evaluate blocking findings |

## 6. Integration

- Real repository inventory: `sbom/wiremudder/inventory.json` is generated
  from `.gitmodules` (real locked submodule SHAs) plus the pinned upstream
  source and WireCore crates.
- Real SBOM artifact: `sbom/wiremudder/sbom.json` (12 components, document
  SHA-256).
- Real license inventory: `licenses/wiremudder/licenses.json` (GPL-2.0 core,
  GPL-3.0 WireCore, MIT/BSD third-party).
- Shared repo security gate: `tests/wiremudder/security/001-repo-secrets-gate.sh`.

## 7. User-Visible Flow

Headless gameplay continues to render raw text regardless of the security
core. The security core is consulted at boundaries: package import, update
install, prompt/context assembly, diagnostics packaging, and permission
denials. On denial the optional action is refused with a typed error and
gameplay continues — never blocked for the core text loop.

## 8. Rollback

The security core is additive and namespaced. Removing the `security/`,
`sbom/`, and `licenses/` boundaries restores the prior behavior without
touching inherited Mudlet paths. All gates are deterministic and reproducible
from the committed inventory fixtures.

## 9. Verification Commands

```sh
sh scripts/node-contract-check.sh EP-033
sh scripts/record-evidence.sh EP-033 M3 "EP-033 M3: ok" -- sh scripts/node-verifiers/EP-033.sh M3
sh scripts/scope-audit.sh EP-033
sh scripts/node-verify.sh EP-033   # final: node verify EP-033: ok
```

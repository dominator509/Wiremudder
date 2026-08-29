NODE-META-BEGIN
ID: EP-039
DEPS: EP-038
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-039
VERIFY_SENTINEL: node verify EP-039: ok
GREEN_TAG: green/EP-039
NODE-META-END

# 1. Purpose and Big Picture

Run the final fresh ship gate, verify evidence hashes and release profile claims, create the release tag and manual signing/publishing packet, append RUN_COMPLETE, and leave production unpublished because auto-deploy is not authorized.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-039.md`.
- Own features: cross-cutting node.
- Own requirements: WM-SPEC-028-R06.
- Use namespaced new code and the smallest evidence-backed inherited integration patch.
- Leave the repository buildable, reversible, auditable, and cold-resumable.

# 3. Non-goals

- No greenfield rewrite, mass rename, broad cleanup, or alternate architecture.
- No work owned by a later node.
- No production publish, stable signing, or key access.
- No mock, stub, demo success, sample success, placeholder behavior, or hidden fallback in production.
- No provider, platform, import format, or asset certification without live-fire evidence.
- No weakening of Graphlock, compatibility, security, privacy, performance, accessibility, or test gates.

# 4. Context and Orientation

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-038. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-039.md`
- `.agent/expected-files/EP-039.txt`
- `.agent/expected-files/EP-039.discovered.txt`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-039.txt`. The milestone fence is `.agent/milestone-files/EP-039-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-039.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-039-production-readiness-ship-and-run-complete.md`
- `.agent/node-contracts/EP-039.md`
- `.agent/expected-files/EP-039.txt`
- `.agent/expected-files/EP-039.discovered.txt`
- `.agent/milestone-files/EP-039-M1.txt`
- `.agent/milestone-files/EP-039-M2.txt`
- `.agent/milestone-files/EP-039-M3.txt`
- `.agent/milestone-files/EP-039-M4.txt`
- `.agent/milestone-files/EP-039-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-039/`
- `scripts/node-verifiers/EP-039.sh`
- `tests/live-fire/LF-039-ship-gate.sh`
- `tests/wiremudder/ep039/`
- `docs/wiremudder/ship/`
- `release/wiremudder/final/`
- `.agent/state/final-evidence/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-039.md`.
- Accepted specifications: SPEC-000, SPEC-020, SPEC-028.
- Live-fire: `LF-039` `ship-gate`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Production Readiness, Ship, and Run Complete.

READ:
- `.agent/execplans/EP-039-production-readiness-ship-and-run-complete.md`
- `.agent/node-contracts/EP-039.md`
- `.agent/milestone-files/EP-039-M1.txt`
- `.agent/expected-files/EP-039.txt`
- `.agent/expected-files/EP-039.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-039-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: cross-cutting node.
3. Review owned requirements: WM-SPEC-028-R06.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-039`
2. `sh scripts/record-evidence.sh EP-039 M1 "EP-039 M1: ok" -- sh scripts/node-verifiers/EP-039.sh M1`
3. `sh scripts/scope-audit.sh EP-039`

EXPECT:
- `EP-039 M1: ok`
- `scope audit EP-039: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-039 MILESTONE_PASS "M1 EP-039 M1: ok; evidence=.agent/state/evidence/EP-039/M1"`

FALLBACK: Do not tag a stable release; emit the exact blocking evidence and preserve the last green release candidate.

COMMIT: `git add -A && git commit -m "[EP-039][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Production Readiness, Ship, and Run Complete inside namespaced boundaries.

READ:
- `.agent/execplans/EP-039-production-readiness-ship-and-run-complete.md`
- `.agent/node-contracts/EP-039.md`
- `.agent/milestone-files/EP-039-M2.txt`
- `.agent/expected-files/EP-039.txt`
- `.agent/expected-files/EP-039.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-039-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-039`
2. `sh scripts/record-evidence.sh EP-039 M2 "EP-039 M2: ok" -- sh scripts/node-verifiers/EP-039.sh M2`
3. `sh scripts/scope-audit.sh EP-039`

EXPECT:
- `EP-039 M2: ok`
- `scope audit EP-039: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-039 MILESTONE_PASS "M2 EP-039 M2: ok; evidence=.agent/state/evidence/EP-039/M2"`

FALLBACK: Do not tag a stable release; emit the exact blocking evidence and preserve the last green release candidate.

COMMIT: `git add -A && git commit -m "[EP-039][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Production Readiness, Ship, and Run Complete with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-039-production-readiness-ship-and-run-complete.md`
- `.agent/node-contracts/EP-039.md`
- `.agent/milestone-files/EP-039-M3.txt`
- `.agent/expected-files/EP-039.txt`
- `.agent/expected-files/EP-039.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-039-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-039`
2. `sh scripts/record-evidence.sh EP-039 M3 "EP-039 M3: ok" -- sh scripts/node-verifiers/EP-039.sh M3`
3. `sh scripts/scope-audit.sh EP-039`

EXPECT:
- `EP-039 M3: ok`
- `scope audit EP-039: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-039 MILESTONE_PASS "M3 EP-039 M3: ok; evidence=.agent/state/evidence/EP-039/M3"`

FALLBACK: Do not tag a stable release; emit the exact blocking evidence and preserve the last green release candidate.

COMMIT: `git add -A && git commit -m "[EP-039][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Production Readiness, Ship, and Run Complete deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-039-production-readiness-ship-and-run-complete.md`
- `.agent/node-contracts/EP-039.md`
- `.agent/milestone-files/EP-039-M4.txt`
- `.agent/expected-files/EP-039.txt`
- `.agent/expected-files/EP-039.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-039-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-039`
2. `sh scripts/record-evidence.sh EP-039 M4 "EP-039 M4: ok" -- sh scripts/node-verifiers/EP-039.sh M4`
3. `sh scripts/scope-audit.sh EP-039`

EXPECT:
- `EP-039 M4: ok`
- `scope audit EP-039: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-039 MILESTONE_PASS "M4 EP-039 M4: ok; evidence=.agent/state/evidence/EP-039/M4"`

FALLBACK: Do not tag a stable release; emit the exact blocking evidence and preserve the last green release candidate.

COMMIT: `git add -A && git commit -m "[EP-039][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Production Readiness, Ship, and Run Complete, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-039-production-readiness-ship-and-run-complete.md`
- `.agent/node-contracts/EP-039.md`
- `.agent/milestone-files/EP-039-M5.txt`
- `.agent/expected-files/EP-039.txt`
- `.agent/expected-files/EP-039.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-039-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-039` at `tests/live-fire/LF-039-ship-gate.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-039`
2. `sh scripts/record-evidence.sh EP-039 M5 "EP-039 M5: ok" -- sh scripts/node-verifiers/EP-039.sh M5`
3. `sh scripts/scope-audit.sh EP-039`

EXPECT:
- `EP-039 M5: ok`
- `scope audit EP-039: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-039 MILESTONE_PASS "M5 EP-039 M5: ok; evidence=.agent/state/evidence/EP-039/M5"`

FALLBACK: Do not tag a stable release; emit the exact blocking evidence and preserve the last green release candidate.

COMMIT: `git add -A && git commit -m "[EP-039][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-039` and require `node verify EP-039: ok`. Then run `sh scripts/expected-files-audit.sh EP-039`, `sh scripts/scope-audit.sh EP-039`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

# 10. Idempotence and Recovery

Resume cold by running the boot sequence, confirming the lease, reading Progress, discoveries, decisions, outcomes, and the ledger tail, then re-running the last checked milestone sentinel. Provisioning, migrations, imports, updates, event consumption, provider calls, and external effects are idempotent or have explicit detection and compensation. Roll back under LOOPS.md and never cross a completed green tag.

# 11. Progress

- [x] M1: Evidence, contracts, and exact path lock
- [x] M2: Core behavior and deterministic invariants
- [x] M3: Real integration and user-visible flow
- [x] M4: Forced failures, abuse cases, performance, and operations
- [x] M5: Live-fire, evidence closure, and green tag readiness

# 12. Surprises and Discoveries

- 2026-08-28: `cargo deny`/`cargo about` are not configured for this repository (no deny.toml / about.hbs); the real dependency/license mechanism is the `security/wiremudder` CLI whose `sbom` subcommand reproduces the committed `document_sha256=b38005dc13082e9c7a58b3fb1a0a08888235222eefb8e6803971f3403cf20f94` and enforces `license_gate_passes()` (evidence WM-SRC-000338/000339).
- 2026-08-28: `clang-tidy` on a directory target fails ("Is a directory"); the working form is a per-file loop with `--extra-arg=-I"$PWD"` (repo root), verified status 0 over all 53 WireMudder-owned boundary files (WM-SRC-000332).
- 2026-08-28: `scripts/production_readiness.py` used `ledger.sh status`, whose last-row semantics report released nodes as PENDING; fixed to require a NODE_DONE ledger row plus the green tag (boot commit c4d4c647).
- 2026-08-28: EP-033/EP-038 fences own `sbom/wiremudder/`, `licenses/wiremudder/`, `release/wiremudder/candidate/` but never produced SBOM.spdx.json / THIRD_PARTY_NOTICES.md / EVIDENCE_INDEX.json; the run gates require them, so EP-039 extended its static fence with those exact paths (EP-038 fence-extension precedent 642d5c5e).
- 2026-08-29: the release oracle's `stable-check` validates the manifest completeness FLAG only, not cryptographic signature content; the real signature denial surface is the physical artifact gate `dir-check <dir> 1`, which demands an on-disk `wiremudder.sig`. A fabricated JSON signature claim passes `stable-check` but cannot survive `dir-check` (evidence: EP-039 M4 failure tests).
- 2026-08-29: the candidate `EVIDENCE_INDEX.json` evidence-corpus hash was frozen at M2 (425 files) while the corpus grew to 432 through M3/M4; M5 evidence closure regenerated `.agent/state/final-evidence/index.json` + `evidence-corpus.sha256` by the canonical method (`find .agent/state/evidence -type f | sort | xargs sha256sum | sha256sum`) and synced the candidate index to `ea51ad4a7620ca28c103dee3b861adb9578e5f62073c4c977f9e9f9f0638c83f`.
- 2026-08-29: posix sh env-prefix commands (`VAR=x cmd`) cannot be passed through a function's `"$@"` under `set -eu`; the release-claims measurement used `env WIREMUDDER_RELEASE_PROFILE=full sh ...` instead. Test paths one directory deeper than `tests/wiremudder/ep039/unit` need one extra `..` in the cd chain (requirements/wm-spec-028-r06 uses five `..`).

# 13. Decision Log

- 2026-08-28: Lock the 12 missing ship-gate commands (lint, typecheck, integration, e2e, compatibility, security, dependency_audit, license, performance, accessibility, platform, smoke) using docs/ai-instructions.md as the accepted command authority. Evidence: WM-SRC-000332..000343; COMMANDS.lock.tsv rows; verify.sh now passes lint and typecheck. Alternatives: cargo deny / cargo about rejected (not configured for this repo). Consequence: run-level gates execute real, evidenced commands. Reversal: remove lock rows and evidence records. Security/privacy/license/compat/perf/upstream impact: none; commands are read-only and fail-closed.
- 2026-08-29: M4 signature-lie test rewritten to assert the oracle's real contract: `stable-check` is a completeness-flag check; the artifact gate `dir-check 1` is the signature denial surface. The test now proves honest-manifest refusal, physical-gate refusal of the unsigned dir, and absence of signature material - no assertion the oracle does not make.
- 2026-08-29: M5 evidence closure regenerated the final evidence index and corpus hash (432 files, canonical method) and synced the candidate EVIDENCE_INDEX `evidence_corpus` to the closed hash. The M2-time frozen hash was not reproducible by any standard aggregation and would have failed the ship gate.

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.

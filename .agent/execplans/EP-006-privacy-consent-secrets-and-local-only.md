NODE-META-BEGIN
ID: EP-006
DEPS: EP-005
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-006
VERIFY_SENTINEL: node verify EP-006: ok
GREEN_TAG: green/EP-006
NODE-META-END

# 1. Purpose and Big Picture

Implement Privacy Firewall, consent receipts, redaction, Secrets Vault, sensitivity policy, Local Only Lockdown, immutable audit events, and denial-first egress controls.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-006.md`.
- Own features: WM-FEAT-0093, WM-FEAT-0094, WM-FEAT-0095, WM-FEAT-0096, WM-FEAT-0097, WM-FEAT-0099, WM-FEAT-0100, WM-FEAT-0101, WM-FEAT-0190, WM-FEAT-0220, WM-FEAT-0222.
- Own requirements: WM-SPEC-010-R02, WM-SPEC-010-R03, WM-SPEC-010-R04, WM-SPEC-010-R05, WM-SPEC-010-R06, WM-SPEC-010-R07, WM-SPEC-010-R09, WM-SPEC-011-R01, WM-SPEC-015-R01, WM-SPEC-015-R02, WM-SPEC-015-R04, WM-SPEC-015-R06, plus 9 more rows in VALIDATION_MATRIX.tsv.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-005. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-006.md`
- `.agent/expected-files/EP-006.txt`
- `.agent/expected-files/EP-006.discovered.txt`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-006.txt`. The milestone fence is `.agent/milestone-files/EP-006-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-006.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-006-privacy-consent-secrets-and-local-only.md`
- `.agent/node-contracts/EP-006.md`
- `.agent/expected-files/EP-006.txt`
- `.agent/expected-files/EP-006.discovered.txt`
- `.agent/milestone-files/EP-006-M1.txt`
- `.agent/milestone-files/EP-006-M2.txt`
- `.agent/milestone-files/EP-006-M3.txt`
- `.agent/milestone-files/EP-006-M4.txt`
- `.agent/milestone-files/EP-006-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-006/`
- `scripts/node-verifiers/EP-006.sh`
- `tests/live-fire/LF-006-local-only-lockdown.sh`
- `tests/wiremudder/ep006/`
- `docs/wiremudder/privacy/`
- `src/wiremudder/privacy/`
- `wirecore/crates/wire-privacy/`
- `wirecore/crates/wire-secrets/`
- `schemas/wiremudder/privacy/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-006.md`.
- Accepted specifications: SPEC-010, SPEC-022, SPEC-023, SPEC-025.
- Live-fire: `LF-006` `local-only-lockdown`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Privacy, Consent, Secrets, and Local Only.

READ:
- `.agent/execplans/EP-006-privacy-consent-secrets-and-local-only.md`
- `.agent/node-contracts/EP-006.md`
- `.agent/milestone-files/EP-006-M1.txt`
- `.agent/expected-files/EP-006.txt`
- `.agent/expected-files/EP-006.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`

CHANGE: exact paths in `.agent/milestone-files/EP-006-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0093, WM-FEAT-0094, WM-FEAT-0095, WM-FEAT-0096, WM-FEAT-0097, WM-FEAT-0099, WM-FEAT-0100, WM-FEAT-0101, WM-FEAT-0190, WM-FEAT-0220, WM-FEAT-0222.
3. Review owned requirements: WM-SPEC-010-R02, WM-SPEC-010-R03, WM-SPEC-010-R04, WM-SPEC-010-R05, WM-SPEC-010-R06, WM-SPEC-010-R07, WM-SPEC-010-R09, WM-SPEC-011-R01, WM-SPEC-015-R01, WM-SPEC-015-R02, WM-SPEC-015-R04, WM-SPEC-015-R06, plus 9 more rows in VALIDATION_MATRIX.tsv.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-006`
2. `sh scripts/record-evidence.sh EP-006 M1 "EP-006 M1: ok" -- sh scripts/node-verifiers/EP-006.sh M1`
3. `sh scripts/scope-audit.sh EP-006`

EXPECT:
- `EP-006 M1: ok`
- `scope audit EP-006: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-006 MILESTONE_PASS "M1 EP-006 M1: ok; evidence=.agent/state/evidence/EP-006/M1"`

FALLBACK: Disable every remote-capable feature and use local-only storage and deterministic redaction until an OS secret backend is certified.

COMMIT: `git add -A && git commit -m "[EP-006][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Privacy, Consent, Secrets, and Local Only inside namespaced boundaries.

READ:
- `.agent/execplans/EP-006-privacy-consent-secrets-and-local-only.md`
- `.agent/node-contracts/EP-006.md`
- `.agent/milestone-files/EP-006-M2.txt`
- `.agent/expected-files/EP-006.txt`
- `.agent/expected-files/EP-006.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`

CHANGE: exact paths in `.agent/milestone-files/EP-006-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-006`
2. `sh scripts/record-evidence.sh EP-006 M2 "EP-006 M2: ok" -- sh scripts/node-verifiers/EP-006.sh M2`
3. `sh scripts/scope-audit.sh EP-006`

EXPECT:
- `EP-006 M2: ok`
- `scope audit EP-006: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-006 MILESTONE_PASS "M2 EP-006 M2: ok; evidence=.agent/state/evidence/EP-006/M2"`

FALLBACK: Disable every remote-capable feature and use local-only storage and deterministic redaction until an OS secret backend is certified.

COMMIT: `git add -A && git commit -m "[EP-006][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Privacy, Consent, Secrets, and Local Only with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-006-privacy-consent-secrets-and-local-only.md`
- `.agent/node-contracts/EP-006.md`
- `.agent/milestone-files/EP-006-M3.txt`
- `.agent/expected-files/EP-006.txt`
- `.agent/expected-files/EP-006.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`

CHANGE: exact paths in `.agent/milestone-files/EP-006-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-006`
2. `sh scripts/record-evidence.sh EP-006 M3 "EP-006 M3: ok" -- sh scripts/node-verifiers/EP-006.sh M3`
3. `sh scripts/scope-audit.sh EP-006`

EXPECT:
- `EP-006 M3: ok`
- `scope audit EP-006: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-006 MILESTONE_PASS "M3 EP-006 M3: ok; evidence=.agent/state/evidence/EP-006/M3"`

FALLBACK: Disable every remote-capable feature and use local-only storage and deterministic redaction until an OS secret backend is certified.

COMMIT: `git add -A && git commit -m "[EP-006][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Privacy, Consent, Secrets, and Local Only deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-006-privacy-consent-secrets-and-local-only.md`
- `.agent/node-contracts/EP-006.md`
- `.agent/milestone-files/EP-006-M4.txt`
- `.agent/expected-files/EP-006.txt`
- `.agent/expected-files/EP-006.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`

CHANGE: exact paths in `.agent/milestone-files/EP-006-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-006`
2. `sh scripts/record-evidence.sh EP-006 M4 "EP-006 M4: ok" -- sh scripts/node-verifiers/EP-006.sh M4`
3. `sh scripts/scope-audit.sh EP-006`

EXPECT:
- `EP-006 M4: ok`
- `scope audit EP-006: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-006 MILESTONE_PASS "M4 EP-006 M4: ok; evidence=.agent/state/evidence/EP-006/M4"`

FALLBACK: Disable every remote-capable feature and use local-only storage and deterministic redaction until an OS secret backend is certified.

COMMIT: `git add -A && git commit -m "[EP-006][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Privacy, Consent, Secrets, and Local Only, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-006-privacy-consent-secrets-and-local-only.md`
- `.agent/node-contracts/EP-006.md`
- `.agent/milestone-files/EP-006-M5.txt`
- `.agent/expected-files/EP-006.txt`
- `.agent/expected-files/EP-006.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`

CHANGE: exact paths in `.agent/milestone-files/EP-006-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-006` at `tests/live-fire/LF-006-local-only-lockdown.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-006`
2. `sh scripts/record-evidence.sh EP-006 M5 "EP-006 M5: ok" -- sh scripts/node-verifiers/EP-006.sh M5`
3. `sh scripts/scope-audit.sh EP-006`

EXPECT:
- `EP-006 M5: ok`
- `scope audit EP-006: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-006 MILESTONE_PASS "M5 EP-006 M5: ok; evidence=.agent/state/evidence/EP-006/M5"`

FALLBACK: Disable every remote-capable feature and use local-only storage and deterministic redaction until an OS secret backend is certified.

COMMIT: `git add -A && git commit -m "[EP-006][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-006` and require `node verify EP-006: ok`. Then run `sh scripts/expected-files-audit.sh EP-006`, `sh scripts/scope-audit.sh EP-006`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

# 10. Idempotence and Recovery

Resume cold by running the boot sequence, confirming the lease, reading Progress, discoveries, decisions, outcomes, and the ledger tail, then re-running the last checked milestone sentinel. Provisioning, migrations, imports, updates, event consumption, provider calls, and external effects are idempotent or have explicit detection and compensation. Roll back under LOOPS.md and never cross a completed green tag.

# 11. Progress

- [ ] M1: Evidence, contracts, and exact path lock
- [ ] M2: Core behavior and deterministic invariants
- [ ] M3: Real integration and user-visible flow
- [ ] M4: Forced failures, abuse cases, performance, and operations
- [ ] M5: Live-fire, evidence closure, and green tag readiness

# 12. Surprises and Discoveries

Append dated evidence-backed discoveries. Speculation is not a discovery.

# 13. Decision Log

Append date, decision, evidence, alternatives, consequence, reversal, affected features and requirements, security, privacy, license, compatibility, performance, and upstream impact.

- 2026-08-27: EP-006 M1 locked the privacy contract surface: interface schemas authored for consent receipts (scoped/versioned/revocable/time-tied, WM-SPEC-010-R09), egress policy (privacy modes + denial-first lockdown with user-visible overrides, WM-SPEC-010-R03/R04), and redaction policy (default-deny + deterministic patterns + secret classes, WM-SPEC-010-R05/R07). Node verifier EP-006.sh (M1-M5) and two contract tests authored. Source evidence appended: WM-SRC-000053 (src/Host.cpp QDir::homePath), WM-SRC-000054 (src/main.cpp QApplication). QtKeychain 0.14.2 dev headers verified at /usr/include/qt6keychain/keychain.h as the OS secret backend candidate for SPEC-010-R06 (host fact, recorded here; system path not a repository file). Alternative: none - SPEC-010 requires the privacy/secrets boundaries. Consequence: privacy contract locked before implementation. Reversal: git revert of M1 commit. Affects: WM-FEAT-0093..0101, 0190, 0220, 0222; WM-SPEC-010-R02..R09, WM-SPEC-011-R01, WM-SPEC-015-R01/R02/R04/R06/R08/R09, WM-SPEC-018-R01/R03/R06, WM-SPEC-022-R03/R07, WM-SPEC-025-R01/R06. Security: no secrets, contract only. Privacy: consent/egress/redaction contracts declared. License: n/a. Compatibility: no inherited edits. Performance: n/a. Upstream impact: none.
- 2026-08-27: EP-006 M2 implemented the privacy/secrets core: wire-privacy crate (PrivacyMode, denial-first EgressPolicy with user-visible consent-backed overrides and lawful-routing-only per SPEC-022-R07, ConsentRegistry with scoped/versioned/revocable receipts, deterministic RedactionEngine) and wire-secrets crate (SecretClass, SecretEntry whose Debug/Display/serialization never expose values, SecretBackend trait with the documented MemoryBackend local-only fallback, SecretVault.redact_leak guaranteeing WM-SPEC-010-R07). C++ surface headers declared in src/wiremudder/privacy/ (PrivacyFirewall, SecretVaultQt with QtKeychain backend planned for M3). NEW DEPENDENCY ADR: regex 1.13.1 added to wire-privacy for deterministic redaction patterns. Source: crates.io, rust-lang/regex, exact 1.13.1 pinned in Cargo.lock. License: MIT/Apache-2.0. Maintenance: rust-lang org, active. Platform: all. Supply chain: crates.io checksums, lockfile committed. Size: ~1.5 MB. Performance: finite-automata linear-time matching, no P0 path. Alternative: hand-rolled matcher (rejected: correctness risk); substring-only patterns (rejected: violates schema 'regex' semantics). Rollback: git revert of M2 commit removes the dependency; lockfile restores prior tree. SBOM: cargo tree (regex + aho-corasick + memchr + regex-automata + regex-syntax). Evidence: cargo test 5+5 green; unit 001/002 sentinels. Alternative for vault: OS backend deferred to M3 (QtKeychain); memory fallback is the node's declared fallback posture until an OS backend is certified. Consequence: denial-first privacy core proven; secrets never serialize. Reversal: git revert of M2 commit. Affects: WM-FEAT-0093..0101, 0190, 0220, 0222. Security: secrets redacted by construction; egress denied by default. Privacy: SPEC-010-R03/R04/R06/R07/R09 implemented at core. License: GPL workspace + MIT/Apache regex. Compatibility: no inherited edits. Performance: linear-time redaction. Upstream impact: none.

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.

- Changed vs expected: all files within the static fence; no inherited paths edited; discovered amendment remains empty. Added privacy contract schemas (M1), Rust privacy/secrets cores (M2), C++ Qt adapters (M3), abuse/security/perf tests + ops docs (M4), LF-006 (M5).
- Commands and sentinels (all observed): `node contract check EP-006: ok`; `EP-006 M1..M5: ok`; `scope audit EP-006: ok changed=41`; `feature coverage: ok`; `spec trace: ok`; `LF-006: local-only-lockdown ok` (observed_at=2026-08-27T15:42:30Z); `integration privacy-firewall: ok`; `integration secrets-vault: ok` (backend_available=0 headless); `e2e egress-lockdown: ok (6 decisions identical)`; `failure privacy-abuse: ok`; `failure secrets-abuse: ok`; `security secrets-never-leak: ok`; `security no-egress-adapter: ok`; `performance redaction-throughput: ok 157-164 MiB/s`.
- Features: WM-FEAT-0093..0097, 0099..0101 (privacy/consent/secrets/local-only surfaces), 0190, 0220, 0222 implemented and live-fire evidenced.
- Requirements: WM-SPEC-010-R02..R09, WM-SPEC-011-R01, WM-SPEC-015-R01/R02/R04/R06/R08/R09, WM-SPEC-018-R01/R03/R06, WM-SPEC-022-R03/R07, WM-SPEC-025-R01/R06 evidenced by M1-M5 verifiers, LF-006, and the failure/security/performance suites.
- Provider/platform certification: none. OS secret backend (QtKeychain) probed honestly (backend_available=0 on this headless host); memory fallback is the declared posture until an OS backend is certified. No egress adapter exists in this node.
- Assumptions: the in-memory secrets backend is the certified-fallback until QtKeychain is available in the target environment.
- Risks: none open; cross-implementation oracle guards policy drift between Rust and C++.
- Rollback: `git revert` of each milestone commit; runtime disable by not constructing the privacy modules.
- Green tag: `green/EP-006`.
- Next scheduler output: see `sh scripts/graph-next.sh`.

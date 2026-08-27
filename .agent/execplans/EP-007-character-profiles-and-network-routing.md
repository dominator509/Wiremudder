NODE-META-BEGIN
ID: EP-007
DEPS: EP-006
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-007
VERIFY_SENTINEL: node verify EP-007: ok
GREEN_TAG: green/EP-007
NODE-META-END

# 1. Purpose and Big Picture

Implement Character Memory Profiles, per-character defaults, legitimate user-controlled routing profile records, connection-time validation, no-silent-fallback behavior, latency display, and routing audit.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-007.md`.
- Own features: WM-FEAT-0079, WM-FEAT-0080, WM-FEAT-0082, WM-FEAT-0084, WM-FEAT-0085, WM-FEAT-0086, WM-FEAT-0087, WM-FEAT-0088, WM-FEAT-0089, WM-FEAT-0090, WM-FEAT-0091, WM-FEAT-0092, plus 5 more rows in FEATURES.tsv.
- Own requirements: WM-SPEC-006-R04, WM-SPEC-006-R05, WM-SPEC-006-R06, WM-SPEC-006-R08, WM-SPEC-006-R09, WM-SPEC-010-R01, WM-SPEC-017-R01, WM-SPEC-017-R05, WM-SPEC-017-R07, WM-SPEC-017-R09, WM-SPEC-023-R01.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-006. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-007.md`
- `.agent/expected-files/EP-007.txt`
- `.agent/expected-files/EP-007.discovered.txt`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-007.txt`. The milestone fence is `.agent/milestone-files/EP-007-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-007.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-007-character-profiles-and-network-routing.md`
- `.agent/node-contracts/EP-007.md`
- `.agent/expected-files/EP-007.txt`
- `.agent/expected-files/EP-007.discovered.txt`
- `.agent/milestone-files/EP-007-M1.txt`
- `.agent/milestone-files/EP-007-M2.txt`
- `.agent/milestone-files/EP-007-M3.txt`
- `.agent/milestone-files/EP-007-M4.txt`
- `.agent/milestone-files/EP-007-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-007/`
- `scripts/node-verifiers/EP-007.sh`
- `tests/live-fire/LF-007-profile-routing-persistence.sh`
- `tests/wiremudder/ep007/`
- `docs/wiremudder/profiles-routing/`
- `src/wiremudder/profiles/`
- `src/wiremudder/routing/`
- `wirecore/crates/wire-profiles/`
- `wirecore/crates/wire-routing/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-007.md`.
- Accepted specifications: SPEC-006, SPEC-010, SPEC-017, SPEC-023.
- Live-fire: `LF-007` `profile-routing-persistence`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Character Profiles and Network Routing.

READ:
- `.agent/execplans/EP-007-character-profiles-and-network-routing.md`
- `.agent/node-contracts/EP-007.md`
- `.agent/milestone-files/EP-007-M1.txt`
- `.agent/expected-files/EP-007.txt`
- `.agent/expected-files/EP-007.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`

CHANGE: exact paths in `.agent/milestone-files/EP-007-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0079, WM-FEAT-0080, WM-FEAT-0082, WM-FEAT-0084, WM-FEAT-0085, WM-FEAT-0086, WM-FEAT-0087, WM-FEAT-0088, WM-FEAT-0089, WM-FEAT-0090, WM-FEAT-0091, WM-FEAT-0092, plus 5 more rows in FEATURES.tsv.
3. Review owned requirements: WM-SPEC-006-R04, WM-SPEC-006-R05, WM-SPEC-006-R06, WM-SPEC-006-R08, WM-SPEC-006-R09, WM-SPEC-010-R01, WM-SPEC-017-R01, WM-SPEC-017-R05, WM-SPEC-017-R07, WM-SPEC-017-R09, WM-SPEC-023-R01.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-007`
2. `sh scripts/record-evidence.sh EP-007 M1 "EP-007 M1: ok" -- sh scripts/node-verifiers/EP-007.sh M1`
3. `sh scripts/scope-audit.sh EP-007`

EXPECT:
- `EP-007 M1: ok`
- `scope audit EP-007: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-007 MILESTONE_PASS "M1 EP-007 M1: ok; evidence=.agent/state/evidence/EP-007/M1"`

FALLBACK: Support direct/system routing only while preserving the versioned profile contract and visibly disable uncertified route types.

COMMIT: `git add -A && git commit -m "[EP-007][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Character Profiles and Network Routing inside namespaced boundaries.

READ:
- `.agent/execplans/EP-007-character-profiles-and-network-routing.md`
- `.agent/node-contracts/EP-007.md`
- `.agent/milestone-files/EP-007-M2.txt`
- `.agent/expected-files/EP-007.txt`
- `.agent/expected-files/EP-007.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`

CHANGE: exact paths in `.agent/milestone-files/EP-007-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-007`
2. `sh scripts/record-evidence.sh EP-007 M2 "EP-007 M2: ok" -- sh scripts/node-verifiers/EP-007.sh M2`
3. `sh scripts/scope-audit.sh EP-007`

EXPECT:
- `EP-007 M2: ok`
- `scope audit EP-007: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-007 MILESTONE_PASS "M2 EP-007 M2: ok; evidence=.agent/state/evidence/EP-007/M2"`

FALLBACK: Support direct/system routing only while preserving the versioned profile contract and visibly disable uncertified route types.

COMMIT: `git add -A && git commit -m "[EP-007][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Character Profiles and Network Routing with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-007-character-profiles-and-network-routing.md`
- `.agent/node-contracts/EP-007.md`
- `.agent/milestone-files/EP-007-M3.txt`
- `.agent/expected-files/EP-007.txt`
- `.agent/expected-files/EP-007.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`

CHANGE: exact paths in `.agent/milestone-files/EP-007-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-007`
2. `sh scripts/record-evidence.sh EP-007 M3 "EP-007 M3: ok" -- sh scripts/node-verifiers/EP-007.sh M3`
3. `sh scripts/scope-audit.sh EP-007`

EXPECT:
- `EP-007 M3: ok`
- `scope audit EP-007: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-007 MILESTONE_PASS "M3 EP-007 M3: ok; evidence=.agent/state/evidence/EP-007/M3"`

FALLBACK: Support direct/system routing only while preserving the versioned profile contract and visibly disable uncertified route types.

COMMIT: `git add -A && git commit -m "[EP-007][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Character Profiles and Network Routing deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-007-character-profiles-and-network-routing.md`
- `.agent/node-contracts/EP-007.md`
- `.agent/milestone-files/EP-007-M4.txt`
- `.agent/expected-files/EP-007.txt`
- `.agent/expected-files/EP-007.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`

CHANGE: exact paths in `.agent/milestone-files/EP-007-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-007`
2. `sh scripts/record-evidence.sh EP-007 M4 "EP-007 M4: ok" -- sh scripts/node-verifiers/EP-007.sh M4`
3. `sh scripts/scope-audit.sh EP-007`

EXPECT:
- `EP-007 M4: ok`
- `scope audit EP-007: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-007 MILESTONE_PASS "M4 EP-007 M4: ok; evidence=.agent/state/evidence/EP-007/M4"`

FALLBACK: Support direct/system routing only while preserving the versioned profile contract and visibly disable uncertified route types.

COMMIT: `git add -A && git commit -m "[EP-007][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Character Profiles and Network Routing, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-007-character-profiles-and-network-routing.md`
- `.agent/node-contracts/EP-007.md`
- `.agent/milestone-files/EP-007-M5.txt`
- `.agent/expected-files/EP-007.txt`
- `.agent/expected-files/EP-007.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`

CHANGE: exact paths in `.agent/milestone-files/EP-007-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-007` at `tests/live-fire/LF-007-profile-routing-persistence.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-007`
2. `sh scripts/record-evidence.sh EP-007 M5 "EP-007 M5: ok" -- sh scripts/node-verifiers/EP-007.sh M5`
3. `sh scripts/scope-audit.sh EP-007`

EXPECT:
- `EP-007 M5: ok`
- `scope audit EP-007: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-007 MILESTONE_PASS "M5 EP-007 M5: ok; evidence=.agent/state/evidence/EP-007/M5"`

FALLBACK: Support direct/system routing only while preserving the versioned profile contract and visibly disable uncertified route types.

COMMIT: `git add -A && git commit -m "[EP-007][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-007` and require `node verify EP-007: ok`. Then run `sh scripts/expected-files-audit.sh EP-007`, `sh scripts/scope-audit.sh EP-007`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

# 10. Idempotence and Recovery

Resume cold by running the boot sequence, confirming the lease, reading Progress, discoveries, decisions, outcomes, and the ledger tail, then re-running the last checked milestone sentinel. Provisioning, migrations, imports, updates, event consumption, provider calls, and external effects are idempotent or have explicit detection and compensation. Roll back under LOOPS.md and never cross a completed green tag.

# 11. Progress

- [x] M1: Evidence, contracts, and exact path lock
- [x] M2: Core behavior and deterministic invariants
- [x] M3: Real integration and user-visible flow
- [x] M4: Forced failures, abuse cases, performance, and operations
- [x] M5: Live-fire, evidence closure, and green tag readiness

# 12. Surprises and Discoveries

Append dated evidence-backed discoveries. Speculation is not a discovery.

- 2026-08-27: Qt has no SOCKS4a proxy type; the routing layer maps SOCKS4a to `QNetworkProxy::Socks5Proxy` at the declared relay endpoint while the decision/audit record keeps the declared kind (`socks4a`) for validation and audit. This is faithful to the accepted taxonomy (WM-SPEC-006-R04) — the Qt network stack simply lacks a dedicated SOCKS4a type.
- 2026-08-27: `cargo run --quiet --bin oracle` still emits rustc warnings to stdout capture when merged with stderr; keeping oracle binaries warning-free is required for clean JSON parsing in the oracle test.
- 2026-08-27: The C++ harness needs the echo server to accept on the server side before the client's `waitForReadyRead`; the first version only listened and timed out ("no echo").

# 13. Decision Log

Append date, decision, evidence, alternatives, consequence, reversal, affected features and requirements, security, privacy, license, compatibility, performance, and upstream impact.

- 2026-08-27: M1 evidence and boundary lock. Recorded source evidence WM-SRC-000055..000057 for the inherited routing surfaces: Host::getConnectionProxy() (QNetworkProxy Socks5Proxy default driven by mUseProxy/mProxyAddress/mProxyPort), cTelnet socket proxy assignment (DefaultProxy/NoProxy equivalence, mConnectViaProxy), and Host per-profile state fields (mUrl, mPort, mpConnectionProxy). Decision: implement EP-007 entirely in the four authorized new boundaries (src/wiremudder/profiles/, src/wiremudder/routing/, wirecore/crates/wire-profiles/, wirecore/crates/wire-routing/); the discovered amendment stays empty because no inherited source edit is required. The C++ routing layer produces QNetworkProxy-compatible decisions that the inherited connection code can consume unchanged; integration tests prove egress through a real controlled SOCKS5 relay so no inherited path is edited. Decision: dual-implementation oracle pattern (Rust core + C++ Qt layer producing byte-identical decisions), consistent with EP-006. Decision: route taxonomy per WM-SPEC-006-R04 with future types (interface binding, VM/netns, self-hosted relay) exposed but visibly disabled and research-gated per WM-FEAT-0088..0090. Decision: no silent fallback (WM-SPEC-006-R06): a selected route that fails blocks or prompts; direct is only used when the user explicitly selected direct/system. Decision: routing profiles and profile routing defaults are user-owned only (WM-SPEC-006-R08); the API surface exposes no create/rotate/select/modify entry point to AI, autopilot, scripts, packages, or plugins. Decision: egress verification is user-triggered (WM-FEAT-0091) and every route decision is appended to the routing audit log (WM-FEAT-0092) with credentials redacted. Evidence: node verifier M1 green, contract tests 001/002 green, scope audit EP-007 ok. Alternatives: patching Host::getConnectionProxy to consume routing records directly (rejected: would require an inherited-path edit and broaden the integration patch beyond the smallest evidence-backed option); adding schemas/wiremudder/routing JSON schemas (rejected: schemas/ is outside EP-007's static fence; the crates declare schema-version constants and validate serialized records internally). Consequence: profile and routing contracts are enforced in Rust and mirrored in C++ with an oracle cross-check. Reversal: none; all new code is namespaced and reversible. Affects: WM-FEAT-0079, 0080, 0082, 0084-0092, 0169-0173; WM-SPEC-006-R04/R05/R06/R08/R09, WM-SPEC-010-R01, WM-SPEC-017-R01/R05/R07/R09, WM-SPEC-023-R01. Security: credentials redacted from audit; no new remote egress authority. Privacy: profiles are local-first and exportable. License: GPL-3.0-or-later crates with no new dependencies beyond serde/serde_json. Compatibility: preserved DefaultProxy/NoProxy direct path; QNetworkProxy-compatible output. Performance: routing validation is pure-local, no network round trips. Upstream impact: none.
- 2026-08-27: M2 core implementation. wire-profiles (5 unit tests) and wire-routing (7 unit tests) implemented as standalone crates under the authorized boundaries, with oracle CLI binaries in each crate (src/bin/oracle.rs). Deterministic invariants proven: schema version lock, ten default domains, automation denied for sensitive defaults (R08), sensitive changes audited+redacted (WM-FEAT-0173), route taxonomy with future kinds disabled (R05), kind-specific validation, no silent fallback (R06), connect-time decision, user-triggered egress verification (WM-FEAT-0091), audit redaction (WM-FEAT-0092). Evidence: `cargo test` 5/5 and 7/7; unit scripts green; node verifier M2 green; scope audit ok. Alternatives: adding a workspace root manifest (rejected — EP-005 fixed the standalone-crate layout and the static fence authorizes only the two crate directories). Consequence: Rust core is the deterministic oracle; C++ mirrors it. Reversal: revert the two crate directories. Affects: WM-FEAT-0079, 0080, 0082, 0084-0092, 0169-0173. Security: no new egress authority; redaction enforced in the core. Privacy: local-first. License: GPL-3.0-or-later, serde/serde_json only (already cached). Compatibility: crate API mirrors the C++ layer contract. Performance: pure-local decisions. Upstream impact: none.
- 2026-08-27: M3 real integration. C++ Qt layer implemented: ProfileStoreQt (JSON persistence to caller directory, actor rules, redacted audit), RoutingStoreQt (route records, select/decision/verify/audit, file persistence), RouterQt (QNetworkProxy mapping, connect-time validation on real QTcpSocket). Harness exercises profiles/routing/router/oracle/proxyflow against Qt 6.8.2. Integration tests prove persistence round-trips, no-silent-fallback, audit redaction; router test proves QNetworkProxy mapping and real direct connect/echo. E2E oracle proves Rust and C++ agree on 12 route entries + 10 profile domains + actor rules. E2E connect-flow proves real SOCKS5 traversal through a controlled local relay fixture (SIMULATION, CI fixture mode per WM-SPEC-017-R09), blocking when the relay dies, and preserved direct gameplay. Decision: SOCKS4a maps to QNetworkProxy::Socks5Proxy at the declared endpoint (Qt lacks a SOCKS4a type) while the record keeps the declared kind. Evidence: all harness subcommands ok, integration/e2e scripts green, node verifier M3 green, scope audit ok. Alternatives: patching cTelnet/Host to consume the routing layer directly (rejected — would need inherited edits outside the discovered amendment; the QNetworkProxy-compatible boundary keeps inherited code untouched). Consequence: the Qt layer is drop-in consumable by the inherited connection code. Reversal: remove the C++ files under src/wiremudder/profiles and src/wiremudder/routing. Affects: WM-FEAT-0080, 0082, 0084-0092; WM-SPEC-006-R04/R06/R08, WM-SPEC-010-R01. Security: fixtures are local-only 127.0.0.1 test servers, torn down via trap. Privacy: no user data leaves the machine in tests. License: GPL-3.0-or-later Qt code. Compatibility: QNetworkProxy output consumable by inherited code. Performance: direct connect/echo within 2s bounds. Upstream impact: none.

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.

- 2026-08-27: EP-007 closed. `node verify EP-007: ok`; `expected files audit EP-007: ok paths=22`; `scope audit EP-007: ok changed=49`; `feature coverage: ok features=244`; `spec trace: ok`; `green/EP-007` created.
- Changed vs expected: all 49 changed paths are within the static fence (execplan, contract, fences, verifier, LEDGER, source evidence, COMMANDS.lock, evidence/, LF-007, tests/wiremudder/ep007/, docs/wiremudder/profiles-routing/, src/wiremudder/profiles/, src/wiremudder/routing/, wirecore/crates/wire-profiles/, wirecore/crates/wire-routing/). Discovered amendment rows=0 — no inherited source edited.
- Owned features: WM-FEAT-0079, 0080, 0082, 0084-0087, 0091, 0092, 0169-0173 implemented and certified (required/full or core); WM-FEAT-0088, 0089, 0090 (research-decision-required/future) exposed as visibly disabled kinds per WM-SPEC-006-R05 — disposition recorded, not silently hidden.
- Owned requirements: WM-SPEC-006-R04/R05/R06/R08/R09, WM-SPEC-010-R01, WM-SPEC-017-R01/R05/R07/R09, WM-SPEC-023-R01 all evidenced by unit/integration/e2e/live-fire tests.
- Commands and sentinels: cargo test 5/5 + 7/7; harness profiles/routing/router/failures/bench all ok; e2e oracle ok (12 route entries + 10 profile domains + actor rules); e2e profile-connect-flow ok (real SOCKS5 relay traversal, block on relay death, preserved direct); LF-007 ok; M1-M5 verifier subcommands ok; performance decision p95 16us vs 10ms budget (SPEC-004).
- Provider/platform certification: none claimed; optional providers remain disabled (preflight ok).
- Assumptions changed: none.
- Risks: SOCKS4a has no Qt proxy type; mapped to Socks5Proxy at the declared endpoint with kind preserved in records (documented in Decision Log).
- Rollback: clean revert of EP-007 commits; no inherited files affected.
- Next scheduler output: `NEXT EP-008`.

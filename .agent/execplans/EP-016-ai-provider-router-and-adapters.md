NODE-META-BEGIN
ID: EP-016
DEPS: EP-006,EP-015
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-016
VERIFY_SENTINEL: node verify EP-016: ok
GREEN_TAG: green/EP-016
NODE-META-END

# 1. Purpose and Big Picture

Implement provider-neutral local and remote adapters, privacy and budget routing, health, streaming, cancellation, fallback, evaluation, and certification without requiring remote services for core operation.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-016.md`.
- Own features: WM-FEAT-0037, WM-FEAT-0038.
- Own requirements: WM-SPEC-013-R03, WM-SPEC-013-R04, WM-SPEC-013-R08, WM-SPEC-013-R10, WM-SPEC-025-R07, WM-SPEC-025-R09.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-006, EP-015. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-016.md`
- `.agent/expected-files/EP-016.txt`
- `.agent/expected-files/EP-016.discovered.txt`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-013-context-distillation-token-budget-and-provider-routing.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-016.txt`. The milestone fence is `.agent/milestone-files/EP-016-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-016.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-016-ai-provider-router-and-adapters.md`
- `.agent/node-contracts/EP-016.md`
- `.agent/expected-files/EP-016.txt`
- `.agent/expected-files/EP-016.discovered.txt`
- `.agent/milestone-files/EP-016-M1.txt`
- `.agent/milestone-files/EP-016-M2.txt`
- `.agent/milestone-files/EP-016-M3.txt`
- `.agent/milestone-files/EP-016-M4.txt`
- `.agent/milestone-files/EP-016-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-016/`
- `scripts/node-verifiers/EP-016.sh`
- `tests/live-fire/LF-016-provider-routing-fallback.sh`
- `tests/wiremudder/ep016/`
- `docs/wiremudder/ai-providers/`
- `wirecore/crates/wire-ai-router/`
- `wirecore/crates/wire-provider-adapters/`
- `schemas/wiremudder/ai/`
- `config/wiremudder/providers/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-016.md`.
- Accepted specifications: SPEC-010, SPEC-013, SPEC-022, SPEC-025, SPEC-026.
- Live-fire: `LF-016` `provider-routing-fallback`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for AI Provider Router and Adapters.

READ:
- `.agent/execplans/EP-016-ai-provider-router-and-adapters.md`
- `.agent/node-contracts/EP-016.md`
- `.agent/milestone-files/EP-016-M1.txt`
- `.agent/expected-files/EP-016.txt`
- `.agent/expected-files/EP-016.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-013-context-distillation-token-budget-and-provider-routing.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`

CHANGE: exact paths in `.agent/milestone-files/EP-016-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0037, WM-FEAT-0038.
3. Review owned requirements: WM-SPEC-013-R03, WM-SPEC-013-R04, WM-SPEC-013-R08, WM-SPEC-013-R10, WM-SPEC-025-R07, WM-SPEC-025-R09.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-016`
2. `sh scripts/record-evidence.sh EP-016 M1 "EP-016 M1: ok" -- sh scripts/node-verifiers/EP-016.sh M1`
3. `sh scripts/scope-audit.sh EP-016`

EXPECT:
- `EP-016 M1: ok`
- `scope audit EP-016: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-016 MILESTONE_PASS "M1 EP-016 M1: ok; evidence=.agent/state/evidence/EP-016/M1"`

FALLBACK: Run in AI-disabled mode or use a certified local endpoint through the provider-neutral contract; do not simulate a provider.

COMMIT: `git add -A && git commit -m "[EP-016][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for AI Provider Router and Adapters inside namespaced boundaries.

READ:
- `.agent/execplans/EP-016-ai-provider-router-and-adapters.md`
- `.agent/node-contracts/EP-016.md`
- `.agent/milestone-files/EP-016-M2.txt`
- `.agent/expected-files/EP-016.txt`
- `.agent/expected-files/EP-016.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-013-context-distillation-token-budget-and-provider-routing.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`

CHANGE: exact paths in `.agent/milestone-files/EP-016-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-016`
2. `sh scripts/record-evidence.sh EP-016 M2 "EP-016 M2: ok" -- sh scripts/node-verifiers/EP-016.sh M2`
3. `sh scripts/scope-audit.sh EP-016`

EXPECT:
- `EP-016 M2: ok`
- `scope audit EP-016: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-016 MILESTONE_PASS "M2 EP-016 M2: ok; evidence=.agent/state/evidence/EP-016/M2"`

FALLBACK: Run in AI-disabled mode or use a certified local endpoint through the provider-neutral contract; do not simulate a provider.

COMMIT: `git add -A && git commit -m "[EP-016][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate AI Provider Router and Adapters with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-016-ai-provider-router-and-adapters.md`
- `.agent/node-contracts/EP-016.md`
- `.agent/milestone-files/EP-016-M3.txt`
- `.agent/expected-files/EP-016.txt`
- `.agent/expected-files/EP-016.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-013-context-distillation-token-budget-and-provider-routing.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`

CHANGE: exact paths in `.agent/milestone-files/EP-016-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-016`
2. `sh scripts/record-evidence.sh EP-016 M3 "EP-016 M3: ok" -- sh scripts/node-verifiers/EP-016.sh M3`
3. `sh scripts/scope-audit.sh EP-016`

EXPECT:
- `EP-016 M3: ok`
- `scope audit EP-016: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-016 MILESTONE_PASS "M3 EP-016 M3: ok; evidence=.agent/state/evidence/EP-016/M3"`

FALLBACK: Run in AI-disabled mode or use a certified local endpoint through the provider-neutral contract; do not simulate a provider.

COMMIT: `git add -A && git commit -m "[EP-016][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break AI Provider Router and Adapters deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-016-ai-provider-router-and-adapters.md`
- `.agent/node-contracts/EP-016.md`
- `.agent/milestone-files/EP-016-M4.txt`
- `.agent/expected-files/EP-016.txt`
- `.agent/expected-files/EP-016.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-013-context-distillation-token-budget-and-provider-routing.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`

CHANGE: exact paths in `.agent/milestone-files/EP-016-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-016`
2. `sh scripts/record-evidence.sh EP-016 M4 "EP-016 M4: ok" -- sh scripts/node-verifiers/EP-016.sh M4`
3. `sh scripts/scope-audit.sh EP-016`

EXPECT:
- `EP-016 M4: ok`
- `scope audit EP-016: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-016 MILESTONE_PASS "M4 EP-016 M4: ok; evidence=.agent/state/evidence/EP-016/M4"`

FALLBACK: Run in AI-disabled mode or use a certified local endpoint through the provider-neutral contract; do not simulate a provider.

COMMIT: `git add -A && git commit -m "[EP-016][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for AI Provider Router and Adapters, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-016-ai-provider-router-and-adapters.md`
- `.agent/node-contracts/EP-016.md`
- `.agent/milestone-files/EP-016-M5.txt`
- `.agent/expected-files/EP-016.txt`
- `.agent/expected-files/EP-016.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-013-context-distillation-token-budget-and-provider-routing.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`

CHANGE: exact paths in `.agent/milestone-files/EP-016-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-016` at `tests/live-fire/LF-016-provider-routing-fallback.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-016`
2. `sh scripts/record-evidence.sh EP-016 M5 "EP-016 M5: ok" -- sh scripts/node-verifiers/EP-016.sh M5`
3. `sh scripts/scope-audit.sh EP-016`

EXPECT:
- `EP-016 M5: ok`
- `scope audit EP-016: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-016 MILESTONE_PASS "M5 EP-016 M5: ok; evidence=.agent/state/evidence/EP-016/M5"`

FALLBACK: Run in AI-disabled mode or use a certified local endpoint through the provider-neutral contract; do not simulate a provider.

COMMIT: `git add -A && git commit -m "[EP-016][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-016` and require `node verify EP-016: ok`. Then run `sh scripts/expected-files-audit.sh EP-016`, `sh scripts/scope-audit.sh EP-016`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

# 10. Idempotence and Recovery

Resume cold by running the boot sequence, confirming the lease, reading Progress, discoveries, decisions, outcomes, and the ledger tail, then re-running the last checked milestone sentinel. Provisioning, migrations, imports, updates, event consumption, provider calls, and external effects are idempotent or have explicit detection and compensation. Roll back under LOOPS.md and never cross a completed green tag.

# 11. Progress

- [x] M1: Evidence, contracts, and exact path lock
- [x] M2: Core behavior and deterministic invariants
- [x] M3: Real integration and user-visible flow
- [x] M4: Forced failures, abuse cases, performance, and operations
- [x] M5: Live-fire, evidence closure, and green tag readiness

# 12. Surprises and Discoveries

- 2026-08-27 (M4): the first router implementation full-sorted the candidate
  route table (O(n log n)) per decision; the 10k-route perf fixture measured
  1951us p95. Only the best route is needed, so the selection was replaced
  with a deterministic O(n) min-scan; the same fixture then measured 136us
  p95 (14x). Routing must never add P0 work (SPEC-004).
- 2026-08-27 (M4): read/write timeouts on the std TcpStream client were
  initially mapped to Unavailable; they are now mapped to the distinct typed
  Timeout error so timeout and cancellation remain separately observable
  (SPEC-025).
- 2026-08-27 (M3): the real Ollama /api/chat response shape matched the
  parser assumptions exactly (message.content, prompt_eval_count, eval_count,
  total_duration); live streaming delivered 18-22 NDJSON chunks per request.

# 13. Decision Log

- 2026-08-27 (M1): Provider adapters live in two standalone crates
  (wire-provider-adapters, wire-ai-router) using path deps on the existing
  wire-privacy crate; serde/serde_json/regex are the only external deps
  (regex already pinned by wire-privacy). Alternative: rusqlite-style new
  supply chain rejected; no ADR needed. Consequence: zero new supply chain.
- 2026-08-27 (M1): remote adapters ship as a policy-denying disabled adapter
  (certified=false, configured=false); the router never selects them.
  Consequence: acceptance obligation 6 (uncertified adapters stay disabled
  and unadvertised) is structurally enforced.
- 2026-08-27 (M2): routing is a pure deterministic function over declared
  inputs; user policy is honored only when the route passes the privacy and
  configuration gates. Any remote block makes remote selection fail closed
  and local selection is marked degraded explicitly (never silent).
- 2026-08-27 (M3): local HTTP client is std TcpStream only (no TLS on
  loopback); cancellation uses a shared atomic flag with a public CancelHandle
  so cancel can originate from any thread.
- 2026-08-27 (M5): certification is evidence-gated; the local route became
  certified=true only after LF-016 live-fire recorded real measured values
  in .agent/state/evidence/EP-016/M5/lf016-certification.json.

# 14. Outcomes and Retrospective

- Changed versus expected: 49 paths (two new crates, ai schemas, provider
  config, unit/integration/e2e/failure/security/performance suites, feature
  and requirement tests, design + operations docs, LF-016, verifier, ledger,
  evidence). No inherited source edited; discovered amendment rows=0.
- Source evidence: 111 records (M1 record 108-111 checkpoints; checker ok).
- Commands and sentinels: `EP-016 M1..M5: ok`, `node verify EP-016: ok`,
  `LF-016: ok`, `feature WM-FEAT-0037/0038: ok`, all 6 requirement tests ok.
- Performance (release, 20k samples): redact p95=2.7us; route-10k p95=136us;
  parse p95=0.9us; payload p95=0.5us.
- Feature disposition: WM-FEAT-0037 certified (local adapter, LF-016);
  WM-FEAT-0038 certified (router, LF-016). Remote adapters remain disabled
  and uncertified by policy.
- Requirement disposition: R03/R04/R08/R10 (SPEC-013) and R07/R09 (SPEC-025)
  all proven by automated tests + live-fire.
- Provider certification: ollama/tinyllama local path certified via LF-016
  (evidence file with real measured values). No remote provider certified.
- Assumptions changed: none.
- Risks: local provider is a controlled dependency; LF-016 fails loudly if
  Ollama is down. Redaction is pattern-based (regex) and should be extended
  with vault-fed secret redaction (wire-privacy redact_secrets) before
  release.
- Rollback: restore config/wiremudder/providers/*.json from git to disable
  AI routing; crate rollback by commit, never crossing a green tag.
- Green tag: green/EP-016.
- Next scheduler output: see graph-next.sh (EP-017).

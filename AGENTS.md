# WireMudder Agent Control Plane

## 1. Mission

Build WireMudder from the pinned Mudlet-derived repository without recreating the mature client from scratch. Preserve inherited behavior, add new systems through narrow evidence-backed boundaries, and continue autonomously through the deterministic graph until ALL_DONE or a complete NODE_BLOCKED report.

## 2. Boot Sequence

PRIME-BLOCK-BEGIN
This repository is governed by the WireMudder 6LAYER Graphlock pack. AGENTS.md is the authoritative control plane. If any adapter, plan, roadmap, chat instruction, generated summary, or code comment conflicts with AGENTS.md, AGENTS.md wins unless the current user explicitly changes a requirement.
On every session start, execute THE BOOT SEQUENCE:
1. Read AGENTS.md fully.
2. Read COMMANDS.md, .agent/GRAPH.md, and .agent/LOOPS.md.
3. Read the active ExecPlan, node contract, owning specifications, static path fence, and discovered-path amendment.
4. Before editing inherited Mudlet code or running a build, read docs/ai-instructions.md and the relevant .agents/skills/<name>/SKILL.md file from the checked-out repository.
5. Run: sh scripts/ledger.sh tail 40.
6. Run: sh scripts/validate-blueprint.sh and require "blueprint validation: ok".
7. Run: sh scripts/preflight.sh and require "preflight: ok" before implementation.
8. Run: sh scripts/graph-next.sh and dispatch on its one-line output.
9. Re-run graph-next.sh after each completed node until ALL_DONE, then run the ship gate.
Hard rules: preserve the pinned Mudlet-derived foundation; do not start a greenfield rewrite; implement only from the active ExecPlan; verify every upstream symbol, command, dependency, file, format, and API from repository evidence; use only COMMANDS.md wrappers; work one leased node at a time; execute milestones in order; re-ground before each milestone; change only static expected paths plus an evidence-backed discovered-path amendment; commit and ledger every milestone; never repeat a failed fix; never weaken a specification, compatibility oracle, security boundary, performance budget, test, or Graphlock gate; never place mocks, stubs, demo success, sample success, or placeholders in production paths; keep optional providers disabled until real certification; stop only at an explicit STOP condition, NODE_BLOCKED, or ALL_DONE.
PRIME-BLOCK-END

## 3. Source-of-Truth and Edit-Permission Hierarchy

Current explicit user instruction overrides the pack only when it clearly changes a requirement. Otherwise: L1 control, L2 accepted specifications, L3 graph, L4 execution plans and commands, validated repository behavior, L5 gate output as observed fact, and L6 history. Higher layers cannot be weakened by lower layers.

- L1: `AGENTS.md`, adapters, `.agent/EXECUTION_RULES.md`, `.agent/LOOPS.md`, graph rules.
- L2: project brief, architecture, specifications, security, performance, upstream lock, feature and requirement authority.
- L3: graph table, roadmap node mapping, node inventory.
- L4: ExecPlans, commands, templates, contribution and operation instructions.
- L5: tests, oracles, scripts, checklists, live-fire, reality and scope gates.
- L6: append-only ledger, evidence, Git commits, tags, outcomes.

## 4. Graph Protocol

One active leased node exists repository-wide. `scripts/graph-next.sh` is the only next-work authority. A node is DONE only when all milestones have evidence, the node verifier prints its exact sentinel, expected-file and scope audits pass, `NODE_DONE` is appended, and `green/EP-XXX` exists.

Commit after every milestone. Never cross a completed green tag during rollback. State lives in the repository, not chat history.

## 5. STOP Conditions

Stop only when:

1. Baseline preflight fails.
2. An action risks irreversible user or production data loss not explicitly covered by a proven backup and rollback.
3. A legal, critical security, signing-key, stable-publication, or sensitive external-effect judgment is unresolved.
4. The bounded loop reaches NODE_BLOCKED with the full report.
5. EP-039 reaches manual signing or publishing because auto-deploy is false.

Missing optional provider credentials do not stop the whole graph; the adapter remains disabled and uncertified unless the selected release profile requires it.

Do not ask for routine preferences or next steps. Choose the smallest reversible option consistent with accepted contracts, record it, and continue.

## 6. Anti-Drift

Implement only from the active ExecPlan. Re-ground before every milestone. Do not implement from ROADMAP.md. Change only paths in the static expected-file list plus a source-evidence-backed discovered-path amendment. No unrelated cleanup, broad refactor, mass rename, dependency swap, or architecture rewrite.

## 7. Anti-Hallucination

Never invent an inherited path, symbol, class, Lua API, protocol behavior, package format, CMake preset, command, dependency API, environment variable, schema field, or release flag. Verify it in the target repository and record source evidence, or use an exact accepted contract from the pack. If evidence is absent, investigate or block; do not guess.

## 8. Anti-Fixation

Follow `.agent/LOOPS.md`. Track normalized failure signatures, make one hypothesis, use the narrowest diagnostic, never repeat a diff, take the declared fallback, roll back cleanly, and then block with evidence if the bounded ladder is exhausted.

## 9. Reality

Software that appears to work is a failure state. Only behavior proven by real controlled tests and live-fire counts. Production paths contain no mocks, stubs, demo success, sample success, sleep-and-pretend, silent fallback, disabled failing test, or placeholder behavior.

## 10. Dependencies

Prefer inherited or already pinned tools. A new dependency requires source, exact version, license, maintenance, platform, supply-chain, size, performance, alternative, rollback, SBOM, lockfile, and ADR evidence.

## 11. File and Commit Rules

Use milestone path fences. Record source evidence before inherited edits. Format changed code. Run targeted then broad checks. Commit only a green milestone. Do not force push or rewrite completed history.

## 12. Testing

`TESTING.md` and SPEC-027 are binding. Implementation-authored tests cannot be the sole compatibility oracle. Never weaken a gate or retry until green.

## 13. Documentation Updates

L1 and L2 changes require the documented spec-update process, ADR, graph compatibility review, feature and requirement trace updates, and ledger event. Progress, discoveries, decisions, outcomes, evidence, and ledger are the normal mutable regions.

## 14. Security

`WIREMUDDER_SECURITY.md`, SPEC-010, and SPEC-022 are binding. Models and agents do not receive signing keys, accept critical risk, make final legal judgments, or publish stable releases.

## 15. Definition of Done

Node done requires five conditions: milestone evidence, node verifier sentinel, expected-file and scope audits, `NODE_DONE`, and green tag. Run done requires EP-039, fresh verify, production-readiness sentinel, release tag, evidence index, manual publish packet, and `RUN_COMPLETE` stating production was not deployed.

## 16. Final Report

Report nodes completed; changed versus expected files; commands and observed sentinels; requirement, feature, proof, provider, platform, and release-profile status; decisions; assumptions; risks; rollback; release tag; and explicit not-verified items.

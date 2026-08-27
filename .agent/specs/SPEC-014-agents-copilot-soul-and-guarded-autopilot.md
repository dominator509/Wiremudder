# SPEC-014: Agents, Copilot, Soul, and Guarded Autopilot

## Status

Accepted blueprint specification.

## Goal

Define the Player Copilot, specialized agents, Soul documents, skills, memory permissions, council reasoning, confidence, explanations, and guarded action flow.

## Canonical Terms

Player Copilot, Guarded Autopilot, Soul.md, Agent Council, Agent Skill Tree, Agent Memory Permission, AI Confidence Meter, Why explanation.

## Required Behavior

WM-SPEC-014-R01: Player Copilot observes approved context and produces suggestions, explanations, citations, uncertainty, and optional Action Proposals without hidden command send.

WM-SPEC-014-R02: Specialized agents include mapper/cartographer, lore/memory curator, quest, tactical, renderer scene, voice companion, help/setup, command safety, token budget, and privacy firewall roles.

WM-SPEC-014-R03: Soul documents define tone, roleplay, boundaries, risk tolerance, preferred and forbidden behaviors, and examples but cannot override security, privacy, routing, package, updater, or emergency-stop policy.

WM-SPEC-014-R04: Soul Studio validates schema, previews compiled prompt, tests conversation in a sandbox, shows policy precedence, and audits changes.

WM-SPEC-014-R05: Agent Skill Tree lists installed skills, source, version, permissions, evaluation status, profile scope, and enable state.

WM-SPEC-014-R06: Agent Memory Permissions define which memory classes each role may read, propose, summarize, share, or never access.

WM-SPEC-014-R07: Agent Council is reserved for tasks whose policy permits multi-agent reasoning and records roles, evidence, disagreements, budget, and final synthesis.

WM-SPEC-014-R08: AI Confidence Meter is calibrated by task and evaluation set and never authorizes an action.

WM-SPEC-014-R09: Why explanations cite observations, memory, policy, uncertainty, and rejected alternatives without exposing hidden chain-of-thought or secrets.

WM-SPEC-014-R10: Guarded Autopilot creates visible, rate-limited, cancellable Action Proposals and pauses when state, command policy, route, or approvals become stale.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- All command-capable output enters SPEC-009.

## Performance

- Complex councils are P2 and cancelable; routine classification uses deterministic or small local logic.

## Non-Goals

- Unrestricted autonomous play
- Soul documents overriding policy
- Hidden inter-agent actions

## Required Tests

- Copilot E2E
- Soul precedence
- Memory permission denial
- Council budget test
- Autopilot stale-state pause

## Acceptance

All requirements for SPEC-014 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-017, EP-018, EP-019, EP-020, EP-022. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.

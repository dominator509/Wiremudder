# Graphlock Adaptation for WireMudder

## Why the Original Template Was Modified

The original Graphlock prompt is designed to support greenfield or current-state projects with strong anti-drift controls. WireMudder is different in three important ways:

1. The product should inherit a large, mature GPL client rather than recreate it.
2. Exact implementation file bodies cannot be prewritten safely before the actual Mudlet fork is inspected.
3. Optional AI, speech, rendering, update, and provider integrations should not require every credential before the classic-client foundation can be built.

These modifications preserve the original goals of fenced scope, verified names and commands, bounded loops, evidence-backed completion, and no fabricated production behavior while making them realistic for a long-lived brownfield fork. The original template requires a complete project-specific pack with zero-drift and anti-fabrication controls. Its purpose and guarantees are the basis of this adaptation.

## Modification 1: Fork-First, Not Greenfield

EP-000 and EP-001 require an attribution-preserving Mudlet repository with verified history, commit, license, build instructions, source layout, and baseline behavior. A complete rewrite is a forbidden move.

## Modification 2: Evidence Before Composition

For a mature codebase, Graphlock's transcription-over-composition rule becomes:

- Transcribe exact schemas, scripts, contracts, configuration, and new isolated modules when the blueprint can provide them safely.
- For edits to inherited source, first record exact repository, commit, path, symbol, surrounding contract, and test evidence.
- Add discovered inherited paths only through `.agent/expected-files/EP-XXX.discovered.txt`, which requires source evidence and a Decision Log entry.
- Compose code only within the approved boundary and only after the active node has locked names, tests, failure behavior, performance budget, and rollback.

This is stricter than allowing an executor to invent source paths and more realistic than pretending a full future implementation can be transcribed before discovery.

## Modification 3: Independent Behavioral Oracles

Compilation and agent-authored tests do not establish parity. Compatibility Lab, Protocol Museum, reference Mudlet runs, protocol standards, sanitized corpora, and explicit product decisions are independent oracles. An implementation agent cannot approve a new oracle that encodes the same assumption it implemented.

## Modification 4: Staged Preflight

Baseline preflight collects every requirement needed for EP-000 through the core local build. Optional providers use node-scoped preflight manifests. Missing optional credentials keep adapters disabled and uncertified. A required core dependency discovered after baseline preflight is a generation defect or BLOCKED condition. Signing keys are never collected into the agent environment.

## Modification 5: Capability Certification Instead of Fake Completion

A provider, platform, import format, asset class, or hardware path has states `declared`, `implemented`, `tested`, `live-fire-certified`, `disabled`, or `blocked`. Compilation never equals certification. Optional disabled capability does not block a release profile that excludes it, but it cannot be advertised as operational.

## Modification 6: Multiple Release Profiles

Core Classic, AI Companion, Immersion, Developer, and Full profiles have separate capability matrices. This permits a real, useful classic client to ship before remote providers or expensive immersion features are certified while keeping every feature in the full graph.

## Modification 7: Maintainer-Controlled Release Authority

Auto-deploy is false. Agents can build, test, package, hash, and prepare release candidates. They cannot access signing keys, publish stable artifacts, make legal license decisions, or accept critical security risk.

## Preserved Graphlock Laws

- Six-layer source-of-truth and edit-permission hierarchy.
- One active leased node.
- Deterministic DAG scheduling.
- Append-only ledger.
- Milestone commits and green tags.
- Bounded retry, fallback, rollback, and terminal BLOCKED state.
- Expected-file scope audit.
- No mocks, stubs, demo success, or placeholder behavior in production paths.
- No gate weakening.
- Live-fire and evidence before DONE.
- Cold resumability without conversation history.

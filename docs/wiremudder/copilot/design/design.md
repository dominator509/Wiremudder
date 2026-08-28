# WireMudder Player Copilot — Design (EP-017 M3)

## Purpose

Suggestion-only Player Copilot (WM-FEAT-0040) with cited Why explanations
(WM-FEAT-0047), calibrated non-authoritative confidence (WM-FEAT-0046),
privacy modes (WM-FEAT-0039), visible disclosures, and optional SPEC-009-
gated Action Proposals. Owning spec: SPEC-014. Depends on EP-008 (command
safety, forward) and EP-016 (provider routing).

## Architecture

```
EP-015 Distiller (wire-context)
        |  ContextCapsule (approved context only)
        v
EP-016 AiRouter (wire-ai-router)  --> RoutingDecision
        |  RoutingInputs (privacy mode, latency, cost, complexity)
        v
EP-017 CopilotEngine (wire-copilot)
        |  ProviderCompletion | CompletionError
        v
CopilotOutcome: Suggestion | NoSuggestion(degraded)
        |
        v
Qt pane CopilotPaneQt (src/wiremudder/ui/copilot/)  [compiled into client]
```

- `wire-copilot` crate: deterministic engine (10 unit tests), zero new
  external dependencies (serde/serde_json + existing wirecore path deps).
- `src/wiremudder/ui/copilot/copilot_boundary.{h,cpp}`: model-side Qt pane,
  passive by construction, compiled into the client via `src/CMakeLists.txt`
  (`mudlet_SRCS` + `mudlet_HDRS`), authorized by discovered-path amendment
  WM-SRC-000118.
- Schemas: `schemas/wiremudder/copilot/{suggestion,soul,why}-v1.json`.

## Behavior

- Suggestion-only: the engine produces a `Suggestion` (text, citations,
  confidence, uncertainty, Why, disclosure) or `NoSuggestion` with a reason.
- Degradation (obligation 6): provider unavailable/timeout/cancel/protocol
  errors map to `NoSuggestion { degraded: true }`; denied routes map to
  `NoSuggestion { degraded: false }`.
- No hidden command send (obligation 1): Action Proposals are explicit,
  visible, `requires_confirmation=true`, and only produced outside combat.
  The engine and pane have no execute path (verified by integration test
  002).
- Why (R09): citations of observations/memory/policy/rejected alternatives;
  secrets redacted (Redactor consumes value tokens after markers).
- Confidence (R08): calibrated per task class and evaluation score; the
  meter's `authorizes()` is always false.
- Disclosures (obligation 5): provider, route, privacy mode, redaction
  pattern count, context bytes, tokens, cost, latency.
- Soul (R03/R04): documents cannot override immutable policy domains;
  Soul Studio validates + audits + sandbox previews (deterministic).

## Commands

```
cargo test --manifest-path wirecore/crates/wire-copilot/Cargo.toml
cargo run --manifest-path wirecore/crates/wire-copilot/Cargo.toml --example e2e_copilot_flow
sh tests/wiremudder/ep017/integration/*.sh
sh tests/wiremudder/ep017/e2e/001-copilot-e2e.sh
cmake . && ninja libmudlet_core.a && ninja mudlet   # client build, rc=0
```

## Observed Behavior (2026-08-28)

- `cargo test` wire-copilot: 10 passed, 0 failed.
- E2E ready: `suggestion=suggest asking the innkeeper about the lost key.
  state=ready`; E2E degraded: `reason=provider is unavailable`.
- C++ pane harness: `E2E copilot pane: ok` (all 8 states, cancel, history).
- Client build: `libmudlet_core.a` linked (rc=0); full executable
  `build-linux-debug-nosan/src/mudlet` 247 MB (rc=0).
- Live provider completion (Ollama local) is NOT claimed until M5 live-fire;
  M3 uses the provider adapter result surface with deterministic values.

## Rollback

- Revert `src/CMakeLists.txt` additions (`wiremudder/ui/copilot/...`),
  delete `src/wiremudder/ui/copilot/`, revert `wirecore/crates/wire-copilot/`,
  revert `schemas/wiremudder/copilot/`, remove tests and docs. Client build
  returns to pre-EP-017 state. Ledger remains append-only.

## Security / Privacy

- No secret access, no remote egress, no routing control, no signing
  capability introduced by this node. Logs and evidence are redacted.
- Optional failure preserves manual text gameplay (pane is passive).

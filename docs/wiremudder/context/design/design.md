# WireMudder Context Distillation and Token Budget (EP-015)

## Design: M3 Real Integration

### 1. Architecture

EP-015 adds two namespaced crates with zero new supply chain (serde only):

- `wirecore/crates/wire-context/` - deterministic typed events
  (WM-FEAT-0196..0206), context capsules with spam removal
  (WM-FEAT-0048, WM-SPEC-013-R02), redaction (SPEC-010).
- `wirecore/crates/wire-token-budget/` - token estimation, routing
  (WM-SPEC-013-R05), degradation (WM-SPEC-013-R06), usage records
  (WM-SPEC-013-R07, WM-FEAT-0049, WM-FEAT-0189), untrusted-output
  validation (WM-SPEC-013-R09).
- `schemas/wiremudder/context/` - event/capsule/usage v1 JSON schemas.
- `compatibility/context/` - locked corpus oracle mapping raw game lines
  to exact typed-event tags.

### 2. Deterministic First Pass (WM-SPEC-013-R01)

`parse_line` applies ordered, hand-rolled grammar rules (no regex crate):
room headers, exits, mobs/animals, players, PKers, combat, items, quest
clues, prompts, health, command results, socials, and private messages
(redacted immediately). Every rule is deterministic: same line, same
events. AI extraction is NOT implemented here; it is a bounded second
pass only when rules cannot resolve required state and stays behind
EP-016 (provider routing). The corpus oracle (`compatibility/context/`)
locks this behavior against drift.

### 3. Context Capsule (WM-SPEC-013-R02)

`Distiller` maintains one capsule: room, exits, entities (bounded at
64), combat, health, mana, prompt, quest clues, command policy, memory
citations, safety evidence, user request. `feed_line_collapsed` removes
repetitive spam via a 64-line window and counts collapses. Private and
social content never enters the capsule.

### 4. Redaction (SPEC-010)

`redact_text` replaces secret-shaped values (password=, token=,
api_key=, secret=, Bearer ) with `[REDACTED]` before any provider sees
content. Private message events carry only the sender.

### 5. Token Budget (WM-SPEC-013-R05/R06/R07)

- `estimate_tokens`: deterministic chars/4 heuristic, no model call.
- `decide_route`: privacy-sensitive or high-risk content always routes
  local-small; remote only when available, approved, policy-allowed,
  complex, and cheap (SPEC-013-R08: no silent remote fallback).
- `degrade`: slow/unavailable -> smaller local; budget/policy ->
  user-visible no-suggestion; cancel -> stronger approved if available.
  Gameplay never waits: all paths return typed results immediately.
- `TokenDashboard`: bounded in-memory usage records with deterministic
  cost estimates (R07). Persistence via EP-014 storage (M3 E2E proof).

### 6. Untrusted Output Validation (WM-SPEC-013-R09)

`validate_output` rejects empty/oversized output, missing citations,
secret leakage, and policy-listed commands before any AI output is used.

### 7. Commands

- Distillation session: `cargo run -p wire-context --example distill_session`
- Budget flow: `cargo run -p wire-token-budget --example budget_flow`
- Corpus oracle: `sh compatibility/context/check.sh`
- Unit: `cargo test -p wire-context` / `cargo test -p wire-token-budget`

Observed behavior (M3 gate): 15 wire-context tests, 10
wire-token-budget tests, 27-case corpus oracle, E2E capsule persisted
and FTS-searchable through the EP-014 storage schema.

### 8. Rollback

Both crates are namespaced; rollback is a pure revert of the node
commits. No inherited path is edited. Never cross a completed green tag.

# WireMudder Command Safety, Emergency Stop, and Human-Tempo — Design

Node: EP-008. Owning specs: SPEC-004, SPEC-009, SPEC-010, SPEC-022.

## 1. Purpose

Every non-manual command source — AI, autopilot, voice, macro, trigger,
script, plugin, headless, and cross-session — enters the same
deterministic Action Proposal gateway (WM-SPEC-009-R02). Manual user
input remains direct (WM-SPEC-009-R01). The gateway verifies
connection, emergency-stop state, source visibility, profile automation
mode, command database, Soul policy, risk tier, confirmation policy,
routing stability, prompt-injection checks, cooldown, pacing, and audit
creation (WM-SPEC-009-R03). No command is sent solely because a model
reports high confidence (WM-SPEC-009-R05).

## 2. Boundaries

| Boundary | Role |
| --- | --- |
| `wirecore/crates/wire-policy/` | Command database (per-world schema, risk tiers, deny/allow, argument validation), Human-Tempo pacing |
| `wirecore/crates/wire-actions/` | Action Proposal gateway, visible queue, global emergency stop, complete audit |
| `src/wiremudder/command-safety/` | Qt layer: `ActionGatewayQt`, `CommandDatabaseQt`, `HumanTempoQt`, `VisibleQueueQt`, `EmergencyStopQt` |
| `schemas/wiremudder/actions/` | action-proposal / action-audit / gate-decision JSON schemas |

No inherited source path is edited (discovered amendment rows=0). The
gateway is a separate boundary from the inherited manual input path
(source evidence WM-SRC-000058..000060): `TCommandLine::commandSubmitted`
and the `TConsole` wiring never touch the gateway, preserving direct
manual send (WM-SPEC-009-R01).

## 3. Data Model

### Command database (schema_version = 1)

Per-world rules: `command`, `tier` (safe/standard/risky/destructive),
`deny`, `allowlisted`, `arg_policy` (`any` | `eq:V` | `min:N` | `max:N`).
Evaluation is deterministic: deny wins, then allowlist, then tier
confirmation. Unknown commands default to standard tier and are never
treated as high-confidence shortcuts; destructive-looking unknown
commands default to risky + confirmation.

### Action proposal (schema_version = 1)

`id, source, original_suggestion, normalized_command, args, risk_tier,
requires_confirmation, created_ms`. Normalization strips a leading
slash and lowercases the command name.

### Gate decision

`approved | needs-confirmation | denied(reason) | paused | queued`.
Reasons: emergency-stop, not-connected, routing-unstable,
injection-flagged, denied-by-policy, automation-disabled, pacing,
queue-full.

## 4. Gateway Semantics (deterministic)

1. `propose(source, suggestion)` — normalize; reject empty, oversized
   (>1024), unavailable command DB, or ambiguous intent
   (WM-SPEC-009-R10 pauses automation rather than guessing).
2. `evaluate(proposal, ctx)` — check in order: emergency stop, connection,
   automation mode, injection flag, routing stability, command policy
   (deny/args), confirmation requirement.
3. `approve_and_send(...)` — approved proposals pass Human-Tempo pacing;
   paced proposals are audited and deferred; sends write a replayable
   audit record.
4. `engageEmergencyStop()` — cancels the visible queue, sets the global
   atomic flag, blocks new proposals; cancellation is audited
   (WM-SPEC-009-R06, WM-SPEC-017-R08). The block check is a single
   boolean read: O(1), never stalls P0 (WM-SPEC-004-R01/R09/R11).
5. Visible queue is bounded; full queue denies with `queue-full`
   (WM-SPEC-009-R08).

## 5. Human-Tempo Pacing (WM-SPEC-009-R07)

Anti-spam and usability control only. Up to `max_burst` sends are
allowed immediately within `burst_window_ms`; once exhausted, sends
wait until the window expires. `min_interval_ms` is the inter-group
cooldown applied to the first send of a new window. It is not
configurable for evasion: it is a rate bound, not an obfuscation tool.

## 6. Verified Behavior (observed 2026-08-27)

- `cargo test` wire-policy: 5/5, wire-actions: 9/9.
- Harness subcommands `policy`, `gateway`, `estop` all print their `ok`
  sentinels against Qt 6.8.2.
- Oracle: C++ and Rust agree on 8 policy entries and 3 shared gate
  scenarios (approved / needs-confirmation / denied).
- E2E: manual path verified direct (no gateway reference in
  TCommandLine/TConsole); audit schema fields present.

## 7. Rollback

All new code lives in the four authorized boundaries. Reversal is a
clean revert of the EP-008 commits. No inherited file is touched, so no
downstream conflict with the Mudlet baseline.

## 8. Design Decisions

- Dual implementation (Rust core + C++ Qt) with oracle cross-check,
  consistent with EP-006/EP-007.
- Emergency stop is a plain atomic boolean (single-read block check) to
  satisfy the 10ms P0 budget without locking.
- Manual input is structurally excluded from the gateway (no manual
  ActionSource variant; inherited input path untouched).
- The gate denies rather than guesses on stale state (R10).

# WireMudder Guarded Autopilot — Design (EP-019 M3)

## Purpose

Opt-in guarded autopilot (WM-FEAT-0041) as visible bounded Action
Proposals, stale-state detection, rate limits, confirmations, pause/cancel,
and audit under the deterministic command gateway (WM-SPEC-014-R10,
WM-SPEC-009-R02/R04). Owning specs: SPEC-009, SPEC-014, SPEC-022. Depends
on EP-008 (deterministic Action Gateway, wire-actions/wire-policy) and
EP-018 (soul/agents precedent).

## Architecture

```
wire-autopilot crate (AutopilotConfig, AutopilotMode, AutopilotEngine,
                     PendingAction, AutopilotAuditEntry, AutopilotError)
  - off by default, profile-scoped (obligation 1)
  - propose() -> visible bounded Action Proposal in the queue (obligation 2)
  - confirm_and_send() / auto_send() -> only send paths, both audited
  - set_stale()/StaleReason -> pause, no guessing (obligation 3, R10)
  - emergency_stop() -> cancels queue + blocks (obligation 4)
  - per-window rate cap -> deterministic (obligation 5)
  - narrow allowlist only in AllowlistAuto mode; no hidden send (obligation 6)
  - owns the EP-008 ActionGateway; approved sends pass through it

src/wiremudder/ui/autopilot/autopilot_boundary.{h,cpp}  [compiled into client]
  - passive Qt pane: status, mode, profile, stale reason, last action,
    pending queue, allowlist; user intent surfaces (confirm/cancel/estop);
    canSendCommand() == false; no authority path

schemas/wiremudder/autopilot/{autopilot-config,autopilot-status}-v1.json
```

## Behavior

- Off by default: `AutopilotConfig::new()` has mode Disabled; propose()
  returns NotEnabled until `enable(profile)` matches the config profile.
- Every action visible before send: propose() enqueues a PendingAction
  (approved-visible or awaiting-confirmation); nothing sends inside
  propose(). Sends only via confirm_and_send() (user-confirmed) or
  auto_send() (narrow allowlist match in AllowlistAuto mode).
- Confirmation (WM-SPEC-009-R04): destructive/social/trade/PvP/account/
  privacy/irreversible actions require confirmation. When the gateway
  approves a proposal, the confirmed send passes through the gateway with
  pacing; when the gateway requires confirmation, the user's explicit
  confirmation makes the send user-approved and it is audited with the
  `confirmed:` marker.
- Stale state pauses (WM-SPEC-009-R10, R10): set_stale() -> Paused; new
  proposals refused; clear_stale() resumes.
- Emergency stop (WM-SPEC-009-R06): cancels the pending queue, engages the
  gateway stop, blocks new proposals; audited.
- Rate limit: max_actions_per_window per window_ms; deterministic.
- No hidden automation: every send is preceded by a visible queue entry and
  recorded in the autopilot audit (proposed -> sent/denied/cancelled/
  paced/emergency-stop).

## Commands

```
cargo test --manifest-path wirecore/crates/wire-autopilot/Cargo.toml
cargo run --manifest-path wirecore/crates/wire-autopilot/Cargo.toml --example e2e_autopilot_flow
sh tests/wiremudder/ep019/integration/*.sh
sh tests/wiremudder/ep019/e2e/001-autopilot-e2e.sh
cmake . && ninja libmudlet_core.a && ninja mudlet   # client build
```

## Observed Behavior (2026-08-28)

- wire-autopilot: 11 tests passed.
- E2E Rust: `E2E autopilot: ok` (visible before send, confirmation path,
  cancel, stale pause, emergency stop, complete audit, no hidden send).
- C++ pane harness: `E2E autopilot pane: ok` (all states, status surface,
  pending queue, allowlist, user-intent requests, no command path).
- Client build: autopilot_boundary.cpp compiled into libmudlet_core.a
  (rc=0); autopilot_boundary.h in mudlet_HDRS.

## Rollback

- Revert `src/CMakeLists.txt` additions (`wiremudder/ui/autopilot/...`),
  delete `src/wiremudder/ui/autopilot/`, revert
  `wirecore/crates/wire-autopilot/`, revert `schemas/wiremudder/autopilot/`,
  remove tests and docs. Client build returns to pre-EP-019 state.

## Security / Privacy

- No secret access, no remote egress, no routing control, no signing
  capability. Confirmation is never bypassable by a model; the narrow
  allowlist is the only auto-send path. The pane is passive with no command
  path (SPEC-022 least privilege, no hidden auto-send).

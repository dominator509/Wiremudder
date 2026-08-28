# EP-023 M4 Operations: Multi-Session, Headless CLI, and Supervisor

## Health

- `wire-headless` crate surfaces are in-memory deterministic state
  (SessionScheduler sessions/queues/audit, Supervisor risk queue).
- Session states follow SPEC-025: Loading, Ready, Disabled, Denied,
  Degraded, Canceled, Unavailable, Error. Non-ready sessions cannot
  enqueue.

## Readiness

- A session is Ready only after explicit `set_state(Ready)`. Enqueue is
  denied (`DeniedPolicy`) until then.
- The supervisor CLI (`tools/wiremudder-supervisor/`) reports session
  state, room, last command, AI/autopilot state, risk queue, route label,
  token spend, health, and queue length on every snapshot.

## Disable

- Headless mode disables UI, renderer, audio, and voice by default
  (WM-SPEC-017-R04 lower overhead). Manual text gameplay is unaffected.
- The supervisor is a passive observer; disabling it removes only the
  dashboard view.

## Recovery

- A denied enqueue consumes no queue slot and records no partial command.
- A failed scenario validation rejects the whole scenario before any
  step executes.
- Restarting the headless runtime re-creates sessions through their
  normal creation flow; the audit trail starts fresh (in-memory).

## Backup / Restore

- Session state is ephemeral by design. No secrets or private content are
  persisted; JSONL events carry privacy scope and redaction flags, never
  raw credentials (WM-SPEC-006-R10).

## Upgrade / Rollback

- Upgrade: rebuild `wirecore/crates/wire-headless/` and
  `tools/wiremudder-supervisor/`; schemas under `schemas/wiremudder/headless/`
  are versioned (v1) and validated as JSON.
- Rollback: delete `tools/wiremudder-supervisor/`,
  `wirecore/crates/wire-headless/`, and `schemas/wiremudder/headless/`.
  No inherited path is modified by this node, so the client returns to
  the pre-EP-023 state.

## Monitoring

- The scheduler audit trail records session-create, session-enqueue, and
  the global emergency stop (explicit, audited cross-session rules).
- JSONL events carry the full SPEC-026-R01 field set (time, severity,
  subsystem, priority, app version, platform, session, correlation,
  event, error, latency, queue, drop/coalesce, feature, privacy,
  redaction).

## Bounded Recovery Runbook

1. Health: run `sh scripts/node-verifiers/EP-023.sh M4` — all M4 checks
   must pass (failure, security, performance).
2. If a check fails, read the typed denial in the evidence log; the crate
   returns `HeadlessDenial` variants (EmergencyStop,
   UnavailableDependency, Timeout, Cancelled, MalformedInput,
   DuplicateRequest, DeniedPolicy, QueueFull, OversizedInput,
   TooManySessions), never silent success.
3. Apply the smallest fix inside the EP-023 fences, re-run the failing
   check, then re-run the full M4 verifier.
4. Do not weaken a gate: fairness, bounds, denials, emergency stop, and
   redaction are binding.

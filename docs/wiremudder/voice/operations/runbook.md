# WireMudder Voice Companion — Operations Runbook (EP-024 M4)

## Health and readiness

- The voice companion exposes a `VoiceSnapshot` (state, mic, activation,
  wake phrase, queue length, load shed, combat suppress, remote
  configured, local only, style/macro counts) through
  `VoiceCompanion::snapshot()`. The UI boundary mirrors it
  (`VoicePaneQt`).
- Ready: `VoiceState::Ready`, mic `off`, queue length 0.
- Degraded: worker crash or provider outage — speech degraded to text;
  terminal/input/connection are never blocked (WM-SPEC-015-R10).
- Disabled: voice off; mic state shows `disabled`; text gameplay fully
  independent.
- Denied: policy/consent denial (e.g., remote speech under Local Only
  Lockdown, wake phrase without consent).

## Disable and emergency stop

- `set_disabled()` — voice off, queue cleared, mic shows disabled.
- `emergency_stop()` — cancels every queued job, denies new work,
  state `canceled`, mic `off`. Manual text gameplay and connection
  controls are preserved (SPEC-009).
- Remote speech is blocked by default (`local_only: true`); Local Only
  Lockdown covers voice egress (SPEC-010-R04).

## Recovery

- After a worker crash: the companion is `degraded`; text continues.
  Re-enable by constructing a fresh companion and calling `set_ready()`;
  transcripts already recorded are preserved (bounded retention).
- After an emergency stop: no automatic resume; the user must create a
  new ready companion. This is intentional (SPEC-009 fail-closed).
- Consent revocation: revoke the receipt (`revoked: true`); the next
  remote request is denied (WM-SPEC-010-R09).

## Backup and restore

- Voice configuration is declarative: `config/wiremudder/voice/voice.yaml`
  and the schemas under `schemas/wiremudder/voice/`. Backup = copy these
  files; restore = replace them and reload. No cloud account required
  (WM-SPEC-010-R10).
- Transcripts are bounded (retention config, max 512) and private
  content is suppressed by default; export honors the same privacy rule.

## Upgrade and rollback

- Upgrade: build the new crate, keep schemas versioned (v1).
- Rollback: `git checkout -- src/CMakeLists.txt` reverts the single
  inherited edit; delete `src/wiremudder/ui/voice/`,
  `wirecore/crates/wire-voice/`, `schemas/wiremudder/voice/`,
  `config/wiremudder/voice/` to remove the node's code. No migration or
  external provider state is touched (EP-024 fallback: ship voice
  disabled or with one certified local push-to-talk provider).

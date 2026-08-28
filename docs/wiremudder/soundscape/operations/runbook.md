# Soundscape Engine and Audio Studio — Operations (EP-026)

## Health and Readiness

- Health: the soundscape engine is healthy when `failed == false` and
  `stopped == false`. Observable via `metrics()` (queue_len, current,
  transition_active, dropped, coalesced, failed, stopped).
- Readiness: ready when at least one binding is registered and mode is
  not Disabled. The UI boundary exposes state labels (ready, disabled,
  degraded, unavailable, error) for the client status line.
- The bounded audit trail (MAX_AUDIT=1024) records asset registration,
  profile changes, transitions, load shedding, emergency stop, and
  failure events — never user text.

## Disable

Two independent disable paths (fail-closed):

1. Per-profile disable: `set_profile_controls(profile, volume, true)`
   denies all playback for that profile (Denial::Disabled).
2. Per-binding disable: `set_binding_enabled(kind, false)` denies that
   binding only.
3. Studio mode Disabled or Muted stops playback and denies new jobs.
4. `degrade_to_text()` clears the queue and sets mode Disabled.

## Recovery

- Audio worker failure: `fail_audio()` clears queue/current/transition
  and denies with UnavailableDependency. On worker restart call
  `reset()`; re-request playback.
- Emergency stop: `emergency_stop()` clears all playback and denies
  with EmergencyStop. `reset()` clears the stop and resumes.
- Transition overrun: tick advances beyond MAX_TRANSITION_MS; the
  transition completes or drops to silence/current loop — never hangs.
- Queue exhaustion: noncritical P3 jobs are dropped (load shedding);
  critical jobs are bounded by MAX_AUDIO_QUEUE + 16 hard cap.

## Backup and Restore

- Configuration: profile volume/disable and binding table are recreated
  from `assets/wiremudder/audio/manifest.json` + studio config (schema
  `schemas/wiremudder/audio/studio-config-v1.json`). Keep both files in
  version control; restore by reapplying them.
- No user data is stored by the engine; the bounded queue and
  transitions are transient and drain on restart (idempotent).

## Upgrade

- Schema versions are stable (`SOUNDSCAPE_SCHEMA_VERSION = 1`).
  Upgrade by adding a new schema version; the engine validates assets
  against the manifest and rejects malformed entries (MalformedInput)
  instead of guessing.
- Rollback: `git checkout -- src/CMakeLists.txt` removes the boundary
  from the client build (discovered amendment rollback). The crate,
  schemas, and assets are additive and reversible by deletion.

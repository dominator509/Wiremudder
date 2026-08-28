# Soundscape Engine and Audio Studio — Design (EP-026)

## Overview

EP-026 adds an optional, provenance-aware soundscape layer to WireMudder:
room, area, combat, boss, weather, death, victory, ambience, and
user-authored bindings (WM-SPEC-016-R08), local asset packs
(WM-SPEC-016-R09), studio controls (profile-scoped volume/disable),
bounded cancelable transitions, load shedding, and text-preserving
degradation (WM-SPEC-016-R10). Soundscapes are P3 (SPEC-004): they may
drop, coalesce, freeze, cancel, or disable and never hide or delay text
gameplay.

## Architecture

- `wirecore/crates/wire-soundscape/` — deterministic core engine
  (`SoundscapeEngine`): bindings, profile-scoped studio controls,
  bounded queue with load shedding and coalescing, bounded cancelable
  transitions, provenance gate, emergency stop, audio-failure degrade.
- `schemas/wiremudder/audio/` — binding, asset-pack, soundscape-state,
  studio-config, and transition v1 schemas.
- `assets/wiremudder/audio/` — original CC0 procedural audio manifest
  with license/provenance/hash; user-local loops are the trusted
  fallback.
- `src/wiremudder/ui/soundscape/soundscape_boundary.{h,cpp}` — passive
  model-side Qt6 boundary compiled into the Mudlet-derived client
  (authorized by discovered amendment WM-SRC-000178 for
  `src/CMakeLists.txt`).

## Data Scope and Privacy

The engine stores only binding configuration, profile volume/disable,
asset metadata (id, license, provenance, hash), and bounded audit
events (MAX_AUDIT=1024). No user text, transcripts, or room content is
stored or transmitted. No remote egress exists: remote unsigned packs
are rejected; the only trusted sources are signed packs and user-local
loops.

## Action Authority

The soundscape boundary is passive (`isPassive() = true`,
`canSendCommand() = false`). It records user-intent request flags
(volume, enable, transition start/cancel) that the owning service
applies through the deterministic engine; it never sends commands,
never grants scopes, and cannot edit gates.

## Audit and Health

The engine keeps a bounded audit trail and `metrics()` exposing queue
length, current soundscape, transition state, dropped/coalesced
counters, failure, and stop state. Health = engine not failed and not
emergency-stopped; readiness = at least one binding registered and mode
not Disabled.

## Restart Behavior

The engine is pure state: cold restart re-registers assets and bindings
from the manifest and profile config; the bounded queue and transitions
are transient and drain on restart. Audio failure (`fail_audio`) clears
playback and denies until `reset()`; text gameplay is unaffected.

## Fallback

User-local ambience loops with manual room binding; automatic
transitions and remote assets disabled (node contract fallback).

## Rollback

`git checkout -- src/CMakeLists.txt` removes the boundary from the
client build (discovered amendment rollback). The crate, schemas, and
assets are additive and reversible by deletion.

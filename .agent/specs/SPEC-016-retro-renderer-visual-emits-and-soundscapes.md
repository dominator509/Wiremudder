# SPEC-016: Retro Renderer, Visual Emits, and Soundscapes

## Status

Accepted blueprint specification.

## Goal

Add an original, optional, provenance-aware retro visual and audio layer that never hides or delays text gameplay and degrades predictably.

## Canonical Terms

retro renderer, room backdrop, visual emit, diorama, sprite overlay, soundscape, asset provenance.

## Required Behavior

WM-SPEC-016-R01: The renderer uses original tile, sprite, diorama, or equivalent retro presentation and does not copy protected Nintendo, Zelda, Mario, or other third-party assets, sounds, trade dress, characters, or proprietary style sheets.

WM-SPEC-016-R02: Persistent room backdrops and style capsules derive from user-owned assets and World Bible continuity rules.

WM-SPEC-016-R03: Visual emits cover NPCs, mobs, animals, players, PvP-visible events, items, spells, combat, movement, doors, weather, ambience, and room events with visible confidence when inferred.

WM-SPEC-016-R04: Raw text remains visible and authoritative and clickable exits or overlays cannot spoof trusted commands.

WM-SPEC-016-R05: Renderer modes include disabled, static, low-power, no-animation, animated, and text-only fallback.

WM-SPEC-016-R06: Frame-budgeted queues drop or coalesce noncritical emits and freeze to static imagery before terminal performance degrades.

WM-SPEC-016-R07: No live art generation occurs in combat or the hot path; asset generation and downloads are out of band and consented.

WM-SPEC-016-R08: Soundscapes support room, area, combat, boss, weather, death, victory, ambience, and user-authored bindings with independent volume and disable controls.

WM-SPEC-016-R09: Audio and visual packs carry license, provenance, hash, signature or user-local source, and permissions.

WM-SPEC-016-R10: Renderer or audio worker failure disables immersion and preserves text gameplay.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Untrusted asset metadata cannot execute code or escape its package directory.

## Performance

- Renderer target work is measured within a 4-6 ms frame budget and may drop P3 events.

## Non-Goals

- Copying protected assets or recognizable proprietary styles
- Visual-only state

## Required Tests

- Emit burst benchmark
- Static fallback
- Text authority
- Asset provenance rejection
- Audio load shedding

## Acceptance

All requirements for SPEC-016 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-021, EP-025, EP-026, EP-030, EP-032, EP-033. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.

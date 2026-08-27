# SPEC-012: Mapper, World Brain, World Bible, and Memory

## Status

Accepted blueprint specification.

## Goal

Combine inherited mapping with a provenance-aware memory graph, hot current-state cache, quest/tactical support, visual/audio continuity, user correction, and Time Machine snapshots.

## Canonical Terms

World Brain, World Bible, room identity confidence, Time Machine Memory, Quest Compass, Tactical HUD, memory fact.

## Required Behavior

WM-SPEC-012-R01: World Brain models rooms, exits, zones, NPCs, mobs, animals, players, PvP-visible characters, items, quests, commands, observations, corrections, renderer facts, and soundscape bindings.

WM-SPEC-012-R02: Every derived fact records source event, time, profile/world scope, confidence, sensitivity, model or rule version, and supersession state.

WM-SPEC-012-R03: Current room, exits, entities, combat, and prompt state use a hot in-memory cache; durable writes are asynchronous.

WM-SPEC-012-R04: Mapper integration preserves inherited rooms, coordinates, labels, areas, doors, locks, one-way, hidden, custom, portal, weighted, and timed exits plus A-star routing and speedwalk generation.

WM-SPEC-012-R05: Ambiguous room identity remains uncertain and asks for correction rather than silently merging rooms.

WM-SPEC-012-R06: Quest Compass cites clues and distinguishes observed, inferred, completed, failed, and user-corrected state.

WM-SPEC-012-R07: Tactical HUD consumes bounded current state and cannot send commands by itself.

WM-SPEC-012-R08: World Bible stores region palettes, terrain, lighting, factions, silhouettes, architecture motifs, sound rules, roleplay tone, and continuity constraints without copying protected assets.

WM-SPEC-012-R09: Time Machine snapshots are background, compacted, exportable, and reversible to user-approved checkpoints.

WM-SPEC-012-R10: User corrections supersede derived facts while preserving history and can be exported or deleted.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Private social content is not promoted into shared world memory by default.

## Performance

- Deep retrieval and vector indexing are P4; current-state reads use hot snapshots.

## Non-Goals

- Replacing the inherited mapper before parity
- Treating model inference as canonical truth

## Required Tests

- Map import/export round trip
- Pathfinding benchmark
- Ambiguous-room correction
- Quest citation test
- Snapshot restore

## Acceptance

All requirements for SPEC-012 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-013, EP-014, EP-020, EP-021, EP-025, EP-026. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.

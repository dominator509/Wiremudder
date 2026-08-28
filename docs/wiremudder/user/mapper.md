# Mapper and Profiles

## Mapper

The mapper visualizes your world: rooms, exits, and areas. It preserves the
mapping behavior inherited from Mudlet (WM-FEAT-0057) and adds evidence
for map data integrity.

- Rooms and exits are stored in your profile.
- Map updates come from your play and from packages you approved.
- A package cannot silently rewrite your map without a declared map
  permission.

## Profiles

Profiles group a world's settings, automation, and data. The Core Classic
profile preserves connection, terminal, scripting, automation, mapping,
profile, package, and accessibility behavior inherited from Mudlet
(SPEC-000-R03).

- **Core Classic** — the full classic client, no optional systems.
- **AI Companion** — adds local-first memory, context, provider routing,
  copilot, explanation, and guarded actions.
- **Immersion** — adds voice, renderer, visual emits, and soundscapes.
- **Developer** — adds headless operation, replay, Compatibility Lab,
  Protocol Museum, diagnostics, package tooling, and bug automation.
- **Full** — every required feature whose dependencies can be certified.
  Unavailable external providers remain visibly disabled and unadvertised
  (SPEC-000-R07).

## Profile Data

Profiles are local. They are backed up and restored with the operations
runbooks (WM-FEAT-0243). See [Operations](operations.md).

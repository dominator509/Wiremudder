# Renderer and Soundscapes

The retro renderer and soundscape systems are optional immersion features
(SPEC-000-R05). They degrade gracefully — if they fail or are disabled,
the text terminal keeps working.

## Retro Renderer

The retro renderer draws the terminal in a pixel-styled display
(WM-FEAT-0152). It supports visual emits (WM-FEAT-0153) and renderer asset
packs. The renderer is optional and can be disabled at any time.

## Soundscapes

Soundscapes add ambient audio to your world (WM-FEAT-0144). Audio assets
are local packs; the audio layer respects the audio permission
(WM-SPEC-008-R04).

## What These Systems Cannot Do

- They cannot affect your connection or your manual input.
- They cannot send audio anywhere.
- They are P2-P4 optional subsystems; the Core Classic profile is
  releasable with every optional subsystem disabled (SPEC-000-R03).

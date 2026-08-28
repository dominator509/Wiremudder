# Accessibility

WireMudder preserves and extends the accessibility behavior inherited from
Mudlet. Accessibility is a first-class surface, not an add-on.

## Screen Reader Support

The client exposes the terminal and UI through the accessibility tree so
screen readers can announce game output (WM-FEAT-0143). Colorblind users
can adjust ANSI color handling.

## Keyboard Operation

Every feature is reachable by keyboard. The input line, toolbar, profile
chooser, and editor respect standard keyboard navigation.

## Visual Adjustments

- Font size, scaling, and line spacing are adjustable.
- Colors can be remapped for contrast.
- The retro renderer is optional and can be disabled for readability.

## Performance and Accessibility

Accessibility never depends on optional systems. The Core Classic profile
preserves accessibility behavior inherited from Mudlet (SPEC-000-R03).

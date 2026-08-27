# WireMudder Release Profiles

## Rules

A profile includes only capabilities with required nodes DONE and required provider or platform certifications green. Disabled optional capability is acceptable only when the profile excludes it or explicitly permits a disabled adapter. Release notes and UI must match the capability matrix exactly.

## Core Classic

Required through EP-014 plus EP-028, EP-031, EP-032, EP-033, EP-035, EP-036, EP-037, EP-038, and EP-039 as scoped to core. AI, remote providers, voice, renderer, soundscapes, autonomous bug patching, and optional import formats may remain disabled.

## AI Companion

Adds EP-015 through EP-022. At least one real approved model route is required or AI remains disabled. Model confidence never grants command authority.

## Immersion

Adds EP-024 through EP-026. Voice, visual, and audio providers or assets require separate certification and provenance. Text-only fallback remains mandatory.

## Developer

Adds EP-023, EP-027 through EP-030, and developer/package tooling in EP-037. Controlled fake MUD servers and sanitized fixtures are valid test dependencies, not production simulations.

## Full

Includes all graph nodes. External optional providers may remain disabled when no credential or legal certification exists, but the underlying provider-neutral capability, settings, disabled state, tests, and documentation must be complete.

## Capability States

`declared`, `implemented`, `tested`, `live-fire-certified`, `disabled`, and `blocked` are the only valid states. A build, import, or adapter that merely compiles is not certified.

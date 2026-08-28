# Help

WireMudder provides contextual help, a Setup Coach, and an optional AI
explanations feature.

## Help Bubbles

Circular help controls appear beside fields, feature cards, wizard steps,
and advanced controls. They provide safe defaults, validation hints,
privacy notes, and documentation links (SPEC-018-R01).

## Setup Coach

The Setup Coach explains and proposes steps — it **cannot** change settings,
enable telemetry or autopilot, change routing, install packages, send
commands, edit Soul documents, edit command packs, or access secrets
(SPEC-018-R06). It has no mutation authority.

## Help Knowledge Index

The Help Knowledge Index is generated reproducibly from accepted docs, UI
schemas, the command catalog, configuration schemas, ADRs, and sanitized
source references (SPEC-018-R04). It is rebuilt from the same inputs, so
the same version of the app produces the same index.

## Ask WireMudder AI

When enabled, Ask WireMudder AI receives only the active field ID, sanitized
UI state, the validation error, approved docs, schemas, the command
catalog, ADRs, and cited source references (SPEC-018-R02). It never
receives your world data, secrets, or full profile.

## Help Modes

Help modes are local-only and remote-redacted or disabled according to the
privacy policy (SPEC-018-R03). Help requests never block settings
interaction or gameplay (SPEC-018-R10). Headless and CLI users receive
equivalent command and configuration help (SPEC-018-R07).

## Source Index (Optional)

Optional source checkout indexing is opt-in, local-first, idle-only,
secret-aware, ignore-file-aware, resumable, and removable (SPEC-018-R05).
It never indexes secrets, ignored files, user profiles, or generated
sensitive artifacts.

# WireMudder Operations

## Local Operations

Use `COMMANDS.md` wrappers. The inherited client, WireCore, storage, voice, renderer, and other workers expose separate health. An optional worker may be disabled or restarted without ending active text gameplay.

## Health States

`starting`, `ready`, `degraded`, `disabled`, `unavailable`, `quarantined`, and `failed` are distinct. Ready means the declared capability can accept work and its policy dependencies are valid.

## Common Incidents

| Incident | Immediate Safe Action | Diagnostic |
| --- | --- | --- |
| WireCore unavailable | Preserve manual gameplay and disable optional docks. | Bridge and process health, bounded logs. |
| Terminal lag | Disable P2-P4 features and run text-flood fixture. | P0/P1 latency and queue depths. |
| Unexpected automated command | Trigger emergency stop and preserve audit. | Action Proposal, policy, source, approvals, send trace. |
| Privacy concern | Enable Local Only Lockdown and stop remote workers. | Privacy event and context preview. |
| Routing failure | Stop connection or prompt; never direct fallback. | Route health and audit. |
| Package or import issue | Disable or roll back package; do not execute automation. | Manifest, permissions, source hash, migration report. |
| Update failure | Quarantine artifact and restore previous release. | Signature, hash, migration, startup health. |
| Renderer or voice failure | Disable immersion and preserve text. | Worker logs and queue metrics. |

## Backup and Restore

Profile, WireCore data, transcripts, maps, packages, user assets, and configuration have documented backup scopes. Secrets are exported only through a separately encrypted user-controlled flow. Restore is proven before stable release.

## Incident Process

Detect, preserve evidence, protect gameplay and data, contain optional systems, classify severity, diagnose with redacted evidence, mitigate reversibly, verify, communicate, document, add regression proof, and update known risks.

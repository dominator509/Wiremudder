# SPEC-006: Network, Protocol, and Routing

## Status

Accepted blueprint specification.

## Goal

Preserve inherited Telnet behavior, expand protocol support through fixtures, and provide user-controlled, auditable routing profiles without abuse or silent fallback.

## Canonical Terms

Telnet, TLS, MCCP, GMCP, MSDP, MSSP, MXP, MSP, MCP, NAWS, CHARSET, EOR, routing profile.

## Required Behavior

WM-SPEC-006-R01: The compatibility matrix covers Telnet negotiation, optional TLS/telnets, encodings, ANSI, MCCP, GMCP, MSDP, MSSP, MXP, MSP, NAWS, CHARSET, and EOR.

WM-SPEC-006-R02: MCP/simpleedit, Pueblo, and Simutronics/GSL are research tracks that end in an evidence-backed implement, defer, or reject decision.

WM-SPEC-006-R03: Protocol parsers consume bounded input, reject malformed frames safely, and expose normalized events without blocking the inherited socket path.

WM-SPEC-006-R04: Direct/system, user-supplied SOCKS5, HTTP CONNECT where compatible, SOCKS4a, local Tor SOCKS, SSH dynamic forward for authorized hosts, and external VPN metadata profiles are represented as explicit user-owned profiles.

WM-SPEC-006-R05: Future interface binding, VM/container/network namespace, and authenticated self-hosted relay profiles remain in the graph with contracts and research gates.

WM-SPEC-006-R06: A missing or failed selected routing profile blocks or prompts; WireMudder never silently falls back to direct networking.

WM-SPEC-006-R07: Egress verification is explicit and user-triggered, never a silent phone-home check.

WM-SPEC-006-R08: AI, autopilot, scripts, packages, and plugins cannot create, rotate, select, modify, or overwrite routing profiles or profile routing defaults.

WM-SPEC-006-R09: Routing features do not procure proxies, rotate identities, spoof fingerprints, automate accounts, or facilitate ban or terms-of-service evasion.

WM-SPEC-006-R10: Per-session route label, latency, health, and audit events are visible without exposing credentials.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Credentials are held in the Secrets Vault and never enter logs, AI context, or plugin access.

## Performance

- Routing validation occurs at setup/connect time; continuous background checks are forbidden.

## Non-Goals

- Proxy marketplace
- Automatic identity rotation
- Fingerprint spoofing

## Required Tests

- Protocol Museum negotiation corpus
- Malformed frame fuzzing
- Route failure test
- No-silent-fallback proof

## Acceptance

All requirements for SPEC-006 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-003, EP-007, EP-011, EP-023, EP-033, EP-036. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.

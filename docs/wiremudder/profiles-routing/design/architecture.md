# WireMudder Character Profiles and Network Routing — Design

Node: EP-007. Owning specs: SPEC-006, SPEC-010, SPEC-017, SPEC-023.

## 1. Purpose

Every character tab attaches to one persistent Character Memory Profile
carrying world, memory, routing, AI, voice, renderer, soundscape,
automation-pack, Soul, and command-database defaults (WM-SPEC-010-R01).
Network routing is expressed as explicit user-owned routing profiles
(direct/system, SOCKS5, SOCKS4a, HTTP CONNECT, Tor local SOCKS, SSH
dynamic forward, external VPN metadata) that validate at connect time
and never silently fall back to direct (WM-SPEC-006-R06).

## 2. Boundaries

| Boundary | Role |
| --- | --- |
| `wirecore/crates/wire-profiles/` | Rust core: versioned character profiles, sensitive-default actor rules, export/import, audit |
| `wirecore/crates/wire-routing/` | Rust core: route taxonomy, kind validation, no-silent-fallback, egress verification, routing audit |
| `src/wiremudder/profiles/` | Qt layer: `CharacterProfile` / `ProfileStoreQt` (JSON persistence, actor rules, audit) |
| `src/wiremudder/routing/` | Qt layer: `RouteProfile` / `RoutingStoreQt` / `RouterQt` (QNetworkProxy mapping, connect-time validation) |

No inherited source path is edited (discovered amendment rows=0). The Qt
routing layer emits `QNetworkProxy` objects that the inherited
`Host::getConnectionProxy()` / `cTelnet` socket assignment code can
consume unchanged (source evidence WM-SRC-000055..000057).

## 3. Data Model

### Character Memory Profile (schema_version = 1)

```
id, name, schema_version, created_at, updated_at
defaults: { world, memory, routing_profile, ai_provider, voice,
            renderer, soundscape, automation_pack, soul_document,
            command_database }
```

Ten default domains (WM-SPEC-010-R01). Two are sensitive — `routing` and
`ai` — meaning AI, autopilot, scripts, packages, and plugins cannot
create profiles or change those defaults (WM-SPEC-006-R08); every
sensitive change by a user is audited with the value redacted
(WM-FEAT-0173).

### Routing Profile (schema_version = 1)

```
id, name, kind, host, port, username
kind ∈ { direct, system, socks5, socks4a, http-connect,
         tor-local-socks, ssh-dynamic-forward, vpn-metadata,
         interface-binding (future), vm-netns (future),
         self-hosted-relay (future) }
```

Future kinds are exposed in the taxonomy but disabled and research-gated
(WM-SPEC-006-R05, WM-FEAT-0088..0090). Audit records carry a redacted
route view — the `username` field never appears in any audit or decision
serialization (WM-FEAT-0092).

## 4. Routing Semantics (no silent fallback)

1. A routing profile must be explicitly selected by the user.
2. Selection validates kind-specific required fields.
3. Connect-time `decision()` returns a typed decision or a typed error
   (`NoRouteSelected`, `SelectedRouteUnavailable`, kind errors).
4. A failed or missing selected route BLOCKS the connection; WireMudder
   never substitutes direct networking (WM-SPEC-006-R06).
5. Direct/system is used only when the user explicitly selected it.
6. Egress verification is user-triggered (WM-FEAT-0091); the probe is a
   real controlled TCP connect through the selected route's endpoint.
7. No abuse-oriented routing: no identity rotation, fingerprint
   spoofing, account automation, or ToS-evasion features exist
   (WM-SPEC-006-R09).

## 5. Qt Integration Surface

`RouterQt::toNetworkProxy(RouteDecision)` maps:

| Decision kind | QNetworkProxy |
| --- | --- |
| Direct / System | `NoProxy` (explicit user choice) |
| Socks5 / Tor local / SSH dynamic | `Socks5Proxy` (host, port) |
| HttpConnect | `HttpProxy` (host, port) |
| Socks4a | `Socks5Proxy` at the declared relay endpoint |
| VpnMetadata / future | no socket proxy; connection blocks |

`RouterQt::connectViaDecision()` applies the decision to a real
`QTcpSocket` and validates the connection; a missing decision or
disabled kind returns an error before any connect attempt.

## 6. Verified Behavior (observed 2026-08-27)

- `cargo test` wire-profiles: 5/5, wire-routing: 7/7.
- Harness subcommands `profiles`, `routing`, `router` all print their
  `ok` sentinels against Qt 6.8.2.
- Oracle: Rust and C++ agree on all 12 route-validation entries and all
  10 profile domains / actor rules.
- E2E: a QTcpSocket configured with a SOCKS5 route provably traversed a
  real local SOCKS5 relay (fixture, SIMULATION) to a local echo server;
  killing the relay made the same connect BLOCK; the direct route still
  connected (manual gameplay preserved).

## 7. Rollback

All new code lives in the four authorized boundaries. Reversal is a
clean revert of the EP-007 commits (`git revert` or `git checkout` of
the lease base) — no inherited file is touched, so no downstream
conflict with the Mudlet baseline. Persisted data lives under the
profile/routing stores' own directories and is local-first JSON;
removing those directories restores a clean slate.

## 8. Design Decisions

- Dual implementation (Rust core + C++ Qt) with an oracle cross-check
  test, consistent with EP-006.
- Schema versions are Rust/`constexpr` constants; JSON schema documents
  under `schemas/` are outside EP-007's static fence and were not
  modified.
- No new crate dependencies beyond serde/serde_json (already cached).
- No inherited source edits; the discovered amendment remains empty.

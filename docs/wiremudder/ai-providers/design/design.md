# WireMudder AI Provider Router and Adapters - Design

EP-016 (WM-FEAT-0037, WM-FEAT-0038; SPEC-010, SPEC-013, SPEC-022,
SPEC-025, SPEC-026).

## Architecture

Two standalone crates behind the WireCore boundary:

- `wirecore/crates/wire-provider-adapters/` - WM-FEAT-0037. One versioned
  adapter interface (`ProviderAdapter`) that normalizes streaming,
  cancellation, usage, errors, health, and capability metadata for local
  and remote models (WM-SPEC-013-R04). Ships a real local HTTP/1.1 client
  (std `TcpStream`, no TLS needed for loopback) for the certified local
  path (Ollama at `127.0.0.1:11434`), a request redactor (WM-SPEC-013-R03),
  and a policy-denying disabled remote adapter (acceptance obligation 6).
- `wirecore/crates/wire-ai-router/` - WM-FEAT-0038. Deterministic routing
  from declared inputs (WM-SPEC-013-R05): task, complexity, privacy mode,
  risk, latency budget, cost budget, locality, availability, context size,
  and user policy. Remote calls require active privacy mode plus explicit
  provider configuration (WM-SPEC-013-R08); there is no silent remote
  fallback. Degradation to local is explicit and marked `degraded`
  (WM-SPEC-013-R06). Evaluation fixtures gate certification
  (WM-SPEC-013-R10).

Dependencies: `wire-privacy` (path) supplies `PrivacyMode`,
`RedactionEngine`, and `RedactionPattern`; serde/serde_json/regex are
already pinned in the repository (regex 1.13.1 used by wire-privacy).
No new supply chain.

## Provider states

| State | Meaning |
|-------|---------|
| disabled | Uncertified or unconfigured adapter; router never selects it (acceptance #6) |
| denied | Router denial: privacy blocks remote or route policy unmet (R08) |
| degraded | Explicit local fallback when remote is blocked; `degraded=true` (R06) |
| unavailable | Provider down; typed `AdapterError::Unavailable`, no hang |
| canceled | Distinct from failure; typed `AdapterError::Cancelled` (R07) |
| error | Corrupt payloads produce typed `AdapterError::Corrupt` |

## Observed provider behavior (real, 2026-08-27)

`POST http://127.0.0.1:11434/api/chat` with
`{"model":"tinyllama","messages":[...],"stream":false,"options":{"num_predict":10}}`
returned:
`message.content` (text), `prompt_eval_count` (39), `eval_count` (10),
`total_duration` (2255075379 ns). The adapter parses `message.content`,
`prompt_eval_count`, `eval_count`; latency is wall-clock measured.
Health uses `GET /api/tags` (`models` array non-empty = healthy).
Streaming uses `stream:true` and NDJSON lines with `message.content` and
`done` fields.

## Commands

- Unit: `cargo test --manifest-path wirecore/crates/wire-provider-adapters/Cargo.toml`
- Unit: `cargo test --manifest-path wirecore/crates/wire-ai-router/Cargo.toml`
- Integration: `cargo run --manifest-path wirecore/crates/wire-ai-router/Cargo.toml --example integration_flow`
- E2E: `cargo run --manifest-path wirecore/crates/wire-ai-router/Cargo.toml --example e2e_provider_flow`
- Live-fire: `tests/live-fire/LF-016-provider-routing-fallback.sh` (M5)

All cargo invocations use `CARGO_TARGET_DIR="$PWD/wirecore/target"`.

## Privacy

Requests are redacted before any provider sees them (WM-SPEC-013-R03):
credentials, API keys, login commands, routing secrets, private-message
lines, and unapproved voice content are replaced with `[REDACTED:class]`
markers. The redactor is fail-closed: a raw engine with no patterns refuses
to send. User-facing errors expose no stack traces, paths, credentials,
private text, provider payloads, or signing metadata (WM-SPEC-025-R09).

## Certification and rollback

A route becomes `certified=true` only after LF-016 live-fire evidence and
evaluation fixtures pass (WM-SPEC-013-R10). Until then the shipped config
(`config/wiremudder/providers/`) keeps every route uncertified, so AI is
disabled by default. Rollback: restore `config/wiremudder/providers/*.json`
from git; the router then denies or returns no-suggestion and manual text
gameplay is never blocked.

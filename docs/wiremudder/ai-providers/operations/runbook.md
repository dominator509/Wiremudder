# WireMudder AI Provider Router and Adapters - Operations Runbook

EP-016 (WM-FEAT-0037, WM-FEAT-0038).

## Health

- Adapter health: `GET http://127.0.0.1:11434/api/tags` must return 200 with
  a non-empty `models` array. The `OllamaAdapter::health()` method performs
  this probe and reports `HealthStatus { healthy, latency_ms, detail }`.
- Router readiness: `AiRouter::route()` with the shipped
  `config/wiremudder/providers/routing-policy.example.json` must return
  NoSuggestion/Denied while every route is uncertified. A Selected decision
  before LF-016 evidence means the config was modified incorrectly.

## Readiness

The AI subsystem is optional. Manual text gameplay is fully independent;
provider failure returns a typed error within the timeout budget and the
next player command still executes (proven by the E2E flow). AI is "ready"
only when (a) the local provider is healthy, (b) a route is certified by
LF-016 evidence, and (c) privacy mode permits the route.

## Disable

Set every route `certified=false` in
`config/wiremudder/providers/routing-policy.example.json` (the shipped
default). The router then never selects a provider. To hard-disable the
local provider path entirely, stop Ollama
(`systemctl stop ollama`) and the adapter reports `Unavailable`.

## Recovery

- Provider crash: restart Ollama; the adapter reconnects per request (no
  persistent state). Health returns to ready on the next probe.
- Adapter error: typed errors are user-safe (no secrets/paths/stack traces);
  retries are caller-bounded; the router never retries a Denied or Policy
  decision.
- Partial effect compensation: usage records are written only for completed
  requests; cancelled or failed requests leave no usage record (proven by
  the failure matrix duplicate/cancel cases).

## Backup and restore

The only mutable AI configuration is
`config/wiremudder/providers/*.json`. Backup: copy those files (or use git).
Restore: replace them from the backup; the router re-reads them on the next
call. There is no AI database of its own in EP-016.

## Upgrade

Crates are standalone (`wire-ai-router`, `wire-provider-adapters`). Rebuild
with `CARGO_TARGET_DIR="$PWD/wirecore/target" cargo build --release
--manifest-path wirecore/crates/wire-ai-router/Cargo.toml`. Schema versions
are stable (`ADAPTER_SCHEMA_VERSION=1`, `ROUTER_SCHEMA_VERSION=1`); bumping
them requires the documented spec-update process.

## Rollback

Restore `config/wiremudder/providers/*.json` from git to disable all AI
provider routing. Roll back crate code by checking out the previous commit;
never cross a completed green tag. Manual text gameplay is unaffected in
every state.

## Metrics and audit

- `OllamaAdapter::usage()` returns the normalized `UsageRecord` list
  (provider, model, feature, prompt/completion tokens, latency, request id).
- Evaluation fixtures (`evaluate_fixture`) produce the certification
  `EvaluationReport`; a route is certifiable only when every dimension
  passes (WM-SPEC-013-R10).

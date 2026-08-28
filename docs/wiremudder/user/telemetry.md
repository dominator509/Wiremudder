# Telemetry and Diagnostics

WireMudder records structured logs, metrics, health, and traces locally.
Nothing is sent anywhere by default (SPEC-026-R08).

## Structured Logs

Logs use time, severity, subsystem, priority, app version, platform,
session/profile hashes, correlation, event, error, latency, queue,
drop/coalesce, feature, privacy, and redaction fields (SPEC-026-R01).
Severity classes are critical, error, warning, info, and debug
(WM-FEAT-0235).

## Health and Readiness

Health distinguishes the Mudlet core, bridge, WireCore, storage, provider,
voice, renderer, updater, and optional worker states (SPEC-026-R02).
Readiness means a component can accept its declared capability — not merely
that a process exists (SPEC-026-R03).

## Metrics

Metrics cover P0/P1 latency, queue depth, trigger/script runtime, storage
delay, token/cost, provider latency, speech timing, renderer frame time,
drops, cancellations, crashes, updates, and package policy (SPEC-026-R04).

## Support Bundles

A diagnostic bundle collects logs, metrics, and configuration into a
content-addressed archive (SPEC-026-R07). Bundles are:

- **Previewable** — inspect before sharing.
- **Redacted** — secrets and private content are removed.
- **Reproducible** — the same inputs produce the same bundle.
- **Content-addressed** — the bundle is named by its hash.

The telemetry layer also deduplicates diagnostics without including private
content (WM-FEAT-0237) and routes root-cause analysis by subsystem and
priority ring (WM-FEAT-0238).

## Tracing

Tracing is bounded, local by default, sampled, and redacted. It is disabled
if its cost would threaten gameplay (SPEC-026-R05).

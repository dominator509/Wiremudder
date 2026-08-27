# WireMudder Observability

## Default

Local-only, bounded, redacted, and opt-in for external submission.

## Structured Fields

Timestamp, app version, platform, subsystem, priority ring, severity, fingerprint, correlation, causation, pseudonymous session/profile/world references, feature flags, privacy mode, error code, latency, queue depth, drops, coalesces, cancellations, token estimate, provider family, voice state, renderer state, and redaction status.

## Metrics

- Manual input, terminal append, outbound send, emergency stop.
- Protocol and trigger runtime.
- Queue depth, age, overflow, drops, coalesces, and fairness.
- Storage lag, transcript persistence, FTS, vector, backup, and migration.
- Model latency, token, cost, cache when provider-reported, cancellation, and failure.
- Voice recognition and synthesis timing and queue shedding.
- Renderer frame work and emit drops.
- Package, import, update, and diagnostic outcomes.

## Logs and Traces

Hot paths use counters and ring-buffer events only. Full traces are bounded, sampled, local, and redacted. Logs never contain secrets or unapproved private content.

## Diagnostic Bundles

Bundles are previewed before export, content-addressed, tied to a known schema, and list every redaction and included source. The preview and exported bytes must hash to the same manifest.

## Acceptance

EP-028 and EP-032 prove bounded overhead, redaction, replay, health, bundle preview, and failure diagnostics. EP-038 verifies release evidence.

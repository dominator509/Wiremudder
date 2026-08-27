# WireMudder Performance Constitution

## Prime Directive

Raw MUD text, manual input, connection health, command send, and emergency stop are sacred. Everything else is asynchronous, bounded, cancelable, optional, measurable, and degradable.

## Mandatory Rules

1. P0 never waits on WireCore, storage, AI, voice, renderer, audio, packages, updates, indexing, diagnostics, or remote services.
2. P1 work is budgeted and a slow trigger, regex, script, parser, or plugin hook is diagnosed and quarantined.
3. Every subscriber queue has finite capacity and one declared overflow behavior: process, coalesce, drop, defer, pause, disable, or quarantine.
4. P2, P3, and P4 backpressure never propagates into P0.
5. One session cannot starve another.
6. No AI request is synchronous with manual play.
7. No durable write is synchronous with network or terminal delivery.
8. No voice job is synchronous with input.
9. No renderer frame hides or delays text.
10. No package or update check runs during active play without explicit user request.
11. No art or asset generation occurs in combat or the live gameplay path.
12. No vector indexing occurs for every raw line.
13. Performance degradation cannot disable privacy, safety, consent, signatures, or audit.
14. Every feature has a benchmark and text-preserving fallback.

## Target Goals

| Metric | Initial Goal |
| --- | --- |
| Manual command accepted | Under 5 ms app-side under normal load. |
| Command queued for send | Under 10 ms app-side under normal load. |
| Incoming text appended | Under 10 ms app-side under normal load. |
| Visible terminal update | Next appropriate UI frame under normal load. |
| Emergency stop propagation | Under 10 ms app-side. |
| Renderer optional work | Measured within 4-6 ms per enabled frame or degraded. |
| Headless session | Lower CPU and memory than equivalent desktop session. |

These are target goals until EP-032 records hardware, workload, distributions, and accepted thresholds. A target may change only by ADR with evidence and cannot be loosened silently.

## Required Fixtures

Text flood, ANSI spam, trigger storm, pathological regex, mapper pathfinding, bridge saturation, storage pressure, provider timeout, provider cancellation, voice STT and TTS, renderer emit burst, soundscape transitions, multi-session fairness, headless throughput, package and plugin abuse, update deferral, large profile cold start, FTS and vector rebuild, and emergency stop under load.

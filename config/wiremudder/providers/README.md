# WireMudder AI Provider Configuration

Provider registry and routing policy live here (EP-016, SPEC-013).

## Files

- `providers.example.json` - adapter registry. The local Ollama path is real
  on this host (`127.0.0.1:11434`, Ollama 0.32.4, tinyllama). Remote adapters
  are **disabled by default**: `certified=false`, `configured=false`. No
  silent remote fallback exists (WM-SPEC-013-R08).
- `routing-policy.example.json` - route table consumed by `wire-ai-router`.
  Routing is deterministic from declared inputs (task, complexity, privacy
  mode, risk, latency, cost, locality, availability, context size, user
  policy). Uncertified routes are never selected.

## Certification

A provider route becomes `certified=true` only after live-fire evidence
(`LF-016 provider-routing-fallback`) and evaluation fixtures
(WM-SPEC-013-R10) pass. Until then the adapter stays disabled and
unadvertised (acceptance obligation 6).

## Privacy

Remote calls require an active privacy mode that permits egress and explicit
provider configuration (WM-SPEC-013-R08). Privacy modes are defined by
`wire-privacy` (SPEC-010). Requests are redacted before any provider sees
them (WM-SPEC-013-R03).

## Rollback

Restore `providers.example.json` and `routing-policy.example.json` from git
to disable all AI provider routing. The router never degrades gameplay.

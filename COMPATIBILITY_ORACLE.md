# WireMudder Compatibility Oracle

## Purpose

Prevent a generator and its tests from agreeing on the same wrong interpretation.

## Sources of Truth

1. Accepted WireMudder product decisions and specifications.
2. Observable behavior of the pinned Mudlet reference build.
3. Published protocol standards and official upstream documentation.
4. Sanitized real-format profile, package, map, and automation corpora.
5. Controlled Protocol Museum servers and deterministic byte streams.
6. Explicitly documented intentional incompatibilities.

## Trace Types

Network bytes and negotiation, normalized protocol events, terminal cell and style state, command and automation order, Lua return values and side effects, profile and package normalized state, mapper graph and routes, accessibility state, UI model state, storage/export state, resource and latency measurements, and failure/recovery state.

## Verdicts

Equivalent, intentionally different, reference defect, candidate defect, oracle defect, unsupported, and unresolved. Unresolved never passes.

## Independence

The implementation worker may not unilaterally change an oracle. Oracle changes require source evidence, owning spec review, a test showing the prior oracle problem, Decision Log entry, and independent reviewer.

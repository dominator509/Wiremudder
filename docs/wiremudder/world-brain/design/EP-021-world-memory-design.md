# WireMudder World Brain, World Bible, Time Machine: Design (EP-021 M3)

## Purpose

Provenance-aware world memory (World Brain), region continuity metadata
(World Bible), and reversible checkpoints (Time Machine) that respect
privacy, preserve history, and never send commands by themselves.

## Architecture

- `wirecore/crates/wire-world-brain/` — bounded, provenance-aware memory
  facts with confidence, sensitivity, supersession, and user corrections
  (SPEC-012-R01/R02/R10, SPEC-023-R02/R03).
- `wirecore/crates/wire-world-bible/` — region palettes, terrain,
  lighting, factions, silhouettes, architecture motifs, sound rules,
  roleplay tone, and continuity constraints as text metadata only; no
  protected assets (SPEC-012-R08, SPEC-016-R02).
- `wirecore/crates/wire-time-machine/` — background, compacted,
  exportable snapshots reversible only to user-approved checkpoints
  (SPEC-012-R09).
- `schemas/wiremudder/memory/` — canonical memory schemas
  (world-brain-fact-v1, world-bible-region-v1, time-machine-snapshot-v1).

## User-Visible Flow

1. World Brain observes a room fact with provenance (source event, time,
   scope, confidence, version, sensitivity, hash).
2. A newer observation supersedes the prior fact (history preserved).
3. The player corrects a fact; the correction supersedes the derived fact
   and records the note — nothing is erased.
4. World Bible holds continuity metadata for the region and exports a
   deterministic checksummed document.
5. Time Machine snapshots the compacted view; restore is denied until the
   player approves the checkpoint; restore then returns the view without
   touching durable history.

## States (SPEC-025)

Each crate exposes typed errors (Validation, NotFound, Exhaustion;
Time Machine adds NotApproved). Non-ready conditions fail closed: restore
without approval is denied, malformed or oversized input is rejected.

## Privacy

- Facts carry sensitivity classes (public/private/secret/diagnostic).
- World Bible stores text metadata only; no protected asset bytes.
- Snapshots are exported as deterministic JSON with schema version.

## Failure Behavior

Optional world-memory failure preserves manual text gameplay. Every
surface is an observer (`can_send_command() == false`); nothing in the
memory stack can send a command.

## Rollback

- Delete `wirecore/crates/wire-world-brain|wire-world-bible|wire-time-machine/`.
- Delete `schemas/wiremudder/memory/`.
- Durable world state returns to pre-EP-021 behavior; gameplay is
  unaffected at every step.

## Observed Commands

- `sh scripts/node-verifiers/EP-021.sh M3` -> `EP-021 M3: ok`
- `cargo run --example e2e_world_memory_flow` -> `E2E world memory: ok`
- `sh scripts/scope-audit.sh EP-021` -> `scope audit EP-021: ok`

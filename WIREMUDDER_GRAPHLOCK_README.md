# WireMudder Graphlock Blueprint Pack

## Purpose

This pack replaces the first-generation greenfield WireMudder blueprint with a brownfield, fork-first, evidence-driven 6LAYER Graphlock system. WireMudder begins from the mature Mudlet Qt6, C++20, and Lua 5.1 codebase, preserves inherited classic-client functionality, and adds new capabilities through a minimal native bridge and an isolated Rust WireCore process.

The pack contains 40 deterministic graph nodes, 29 accepted specifications, 244 individually traced features, 292 numbered specification requirements, 40 live-fire proofs, source-document coverage, compatibility-oracle requirements, expected-file fences, bounded repair loops, release-profile rules, and self-validation tooling.

## Non-Negotiable Product Decision

WireMudder is not authorized as a complete from-scratch rewrite. A mature inherited component is replaced only when a dedicated node proves behavioral compatibility, security, performance, migration, rollback, and upstream synchronization. The inherited implementation remains available behind a reversible switch through at least one stable release after replacement.

## Start Here

1. Read `HOW_TO_USE.md`.
2. Read `GRAPHLOCK_ADAPTATION.md`.
3. Read `PROJECT_BRIEF.md`, `ARCHITECTURE.md`, and `FEATURE_CATALOG.md`.
4. Overlay this pack onto a Git clone or fork of Mudlet at the commit recorded in `UPSTREAM.lock.yaml`.
5. Run `sh scripts/validate-blueprint.sh`.
6. Run `sh scripts/preflight.sh`.
7. Give the contents of `.agent/prompts/run-graph.md` to Codex, Claude Code, Gemini CLI, Hermes, OpenClaw, or another terminal coding agent.

## Truth Boundary

The documents in this pack are implementation contracts, not claims that runtime behavior already exists. Runtime completion is established only by observed test and live-fire evidence, node verification, expected-file audit, ledger `NODE_DONE`, and a `green/EP-XXX` tag.

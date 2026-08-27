# WireMudder Data Model Overview

Canonical schemas live under `schemas/wiremudder/` and are implemented in EP-004 and EP-014. This document is a human index.

## Identity and Scope

Local app identity, world, session, Character Memory Profile, routing profile, profile default binding, consent receipt, feature flag, capability grant, provider configuration reference, and audit principal.

## Classic and Automation

Alias, trigger, timer, macro, key binding, voice macro, variable table, script, package, module, package permission, command database, Soul document, and import record.

## World and Memory

Room, exit, zone, entity, player observation, mob, animal, item, quest, clue, combat snapshot, memory fact, correction, World Bible rule, Time Machine snapshot, renderer fact, and soundscape binding.

## Content and Indexing

Transcript chunk, transcript offset, note, bookmark, FTS record, vector record, embedding version, help index record, source index record, and replay fixture.

## AI and Assistance

Context capsule, provider request, provider response metadata, token budget event, Copilot suggestion, Why explanation, confidence record, Agent Skill, Agent Council run, Action Proposal, command policy decision, and autopilot state.

## Voice and Immersion

Voice profile, voice style, speech job, subtitle, renderer asset, renderer emit, room backdrop, soundscape asset, transition, and provenance record.

## Operations

Telemetry event, crash event, diagnostic bundle, bug case, update manifest, update event, release evidence, migration, backup, restore, and incident.

Every record follows SPEC-023 ownership, provenance, sensitivity, retention, export, deletion, and migration rules.

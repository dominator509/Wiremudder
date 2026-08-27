# WireMudder Testing and Evidence Standard

## Principle

A passing build proves compilation only. WireMudder correctness is established through independent behavioral oracles, deterministic contracts, real controlled integrations, failure tests, performance evidence, accessibility checks, and live-fire user outcomes.

## Test Layers

| Layer | Purpose | Rule |
| --- | --- | --- |
| Unit | Pure transformations and policy | No network, process, database, UI, or provider. |
| Contract | Schemas and generated bindings | Round trip, version, unknown field, size, and malformed input. |
| Integration | Real local component boundaries | Use real SQLite, local IPC, WireCore process, controlled server, and actual parser or adapter under test. |
| Compatibility | Reference Mudlet versus WireMudder | Compare normalized semantic traces from independent fixtures. |
| E2E | Real desktop or headless entry point | Exercise user flow, settings, errors, and persistence. |
| Live-fire | Ship criteria | Execute declared outcome and assert a real observable effect. |
| Security | Denial and abuse cases | Prompt injection, permissions, secrets, packages, imports, updates, and resource exhaustion. |
| Performance | Priority and degradation | Record hardware, workload, repetitions, distributions, thresholds, and raw artifacts. |
| Accessibility | Inclusive operation | Keyboard, focus, semantics, non-color state, large text, reduced motion, subtitles, raw text. |
| Platform | Release support | Clean Windows, macOS, and Linux build, install, upgrade, rollback, and smoke. |

## Independent Oracle Rule

The implementation agent may add regression tests, but those tests cannot establish a new compatibility expectation alone. Reference Mudlet runs, protocol standards, controlled fixtures, source evidence, and accepted product decisions approve the oracle.

## Test Double Zones

Mocks, fakes, and fixtures are legal only under:

- `tests/wiremudder/`
- `compatibility/`
- `tools/protocol-museum/`
- `tools/update-fixtures/`
- `tests/live-fire/` when the fake server is the controlled external dependency and the production client path remains real.

No test-mode, demo-mode, fake-success, or sample-data branch is permitted in production paths.

## Required Fixture Families

- Controlled Telnet and protocol servers.
- ANSI and terminal streams.
- Lua, alias, trigger, timer, macro, package, profile, and map corpora.
- IPC and schema frames.
- Context, privacy, prompt-injection, provider failure, and budget corpora.
- Voice, renderer, soundscape, import, update, and diagnostic assets with lawful provenance.
- Text flood, trigger storm, pathfinding, multi-session, storage, and cold-start benchmarks.

## Evidence

A gate passes only when run in the current session and its sentinel is observed. `scripts/record-evidence.sh` runs the command, captures exit code, hashes output, verifies the sentinel, and writes machine-readable evidence. Reading a script or citing an earlier run is not evidence.

## Flaky Tests

A flaky test is a defect. Fix it, or remove it only by ADR with replacement evidence. Retrying until green is forbidden.

## Validation Matrix

The machine authority is `.agent/requirements/VALIDATION_MATRIX.tsv`. Every numbered specification behavior has an owner, expected test path, verification class, and live-fire proof.

## Definition of Test Done

Tests are done when the active node's requirements are mapped, tests fail before or independently expose the defect when practical, tests use the real implementation boundary, failure and cancellation are covered, raw evidence is stored, no gate is weakened, and the node verifier and live-fire proof pass.

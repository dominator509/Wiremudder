# WireMudder Canonical Commands

## Rule

Coding agents must not invent commands. If a wrapper is missing or stale, update this file and the wrapper from repository evidence through the active ExecPlan and Decision Log before running a replacement.

## Working Directory and Environment

Run from the repository root.

```sh
export CI=true
export GIT_TERMINAL_PROMPT=0
export GIT_PAGER=cat
export PAGER=cat
export DEBIAN_FRONTEND=noninteractive
```

## Blueprint and Graph

| Purpose | Command | Sentinel |
| --- | --- | --- |
| Validate blueprint | `sh scripts/validate-blueprint.sh` | `blueprint validation: ok` |
| Authority integrity | `sh scripts/authority-check.sh` | `authority check: ok` |
| Baseline preflight | `sh scripts/preflight.sh` | `preflight: ok` |
| Validate graph | `sh scripts/graph-validate.sh` | `graph validation: ok` |
| Next node | `sh scripts/graph-next.sh` | One dispatch line. |
| Feature coverage | `sh scripts/feature-coverage-check.sh` | `feature coverage: ok` |
| Spec trace | `sh scripts/spec-trace-check.sh` | `spec trace: ok` |
| Adapter parity | `sh scripts/adapter-parity-check.sh` | `adapter parity: ok` |
| Manifest | `sh scripts/manifest-check.sh` | `manifest check: ok` |
| Source coverage | `sh scripts/source-coverage-check.sh` | `source coverage: ok` |
| Upstream lock | `sh scripts/upstream-lock-check.sh` | `upstream lock: ok` |
| Node verify | `sh scripts/node-verify.sh EP-XXX` | `node verify EP-XXX: ok` |
| Scope audit | `sh scripts/scope-audit.sh EP-XXX` | `scope audit EP-XXX: ok` |
| Expected outputs | `sh scripts/expected-files-audit.sh EP-XXX` | `expected files audit EP-XXX: ok` |
| Source evidence integrity | `sh scripts/source-evidence-check.sh` | `source evidence check: ok` |
| Add discovered inherited path | `sh scripts/discovered-path-add.sh EP-XXX EVIDENCE_ID PATH RATIONALE TEST_PATH ROLLBACK` | `discovered path add EP-XXX: ok` |
| Validate discovered inherited paths | `sh scripts/discovered-path-check.sh EP-XXX` | `discovered path check EP-XXX: ok` |
| Command lock integrity | `sh scripts/command-lock-check.sh` | `command lock check: ok` |

## Build and Test Wrappers

EP-000 verifies the underlying CMake presets and tool paths before these wrappers are treated as runtime evidence.

| Purpose | Command | Sentinel |
| --- | --- | --- |
| Configure/install | `sh scripts/install.sh` | `install: ok` |
| Format check | `sh scripts/format-check.sh` | `format check: ok` |
| Lint/static analysis | `sh scripts/lint.sh` | `lint: ok` |
| Type and compile check | `sh scripts/typecheck.sh` | `typecheck: ok` |
| Unit tests | `sh scripts/test-unit.sh` | `unit tests: ok` |
| Integration tests | `sh scripts/test-integration.sh` | `integration tests: ok` |
| E2E tests | `sh scripts/test-e2e.sh` | `e2e tests: ok` |
| Build | `sh scripts/build.sh` | `build: ok` |
| Security | `sh scripts/security-check.sh` | `security check: ok` |
| Dependency and license audit | `sh scripts/dependency-audit.sh` | `dependency audit: ok` |
| Reality gate | `sh scripts/reality-gate.sh` | `reality gate: ok` |
| Smoke | `sh scripts/smoke-test.sh` | `smoke test: ok` |
| Live-fire | `sh scripts/live-fire.sh` | `live-fire: ok` |
| Full verify | `sh scripts/verify.sh` | `verify: ok` |
| Production readiness | `sh scripts/production-readiness-check.sh` | `production readiness: ok` |

## Upstream-Verified Default Build Pattern

The current evidence snapshot says to read `.agents/skills/build-mudlet/SKILL.md`, list presets, then configure, build, and test with the same selected preset. The wrappers use `WIREMUDDER_CMAKE_PRESET` and fail when it is absent or invalid.

## Forbidden Commands

- Interactive editors or REPLs inside autonomous runs.
- Foreground watch servers without a bounded readiness and kill plan.
- Bare unbounded parallel builds.
- Forced pushes, history rewrites, or destructive resets across a completed green tag.
- Destructive database or profile operations outside a backed-up migration plan.
- Direct package, provider, update, or release publication outside the active node and maintainer authority.

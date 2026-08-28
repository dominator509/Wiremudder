# Developer Guide

This guide is for developers and contributors working on WireMudder. It
preserves the upstream Mudlet rules and adds the WireMudder Graphlock
controls.

## Repository Layout

- `src/` — the Mudlet-derived Qt/C++ client.
- `wirecore/` — isolated WireMudder Rust services (bridge, agents, packages,
  updater, release, security, help, and more).
- `schemas/wiremudder/` — canonical JSON schemas.
- `docs/wiremudder/` — WireMudder design and operations documentation.
- `tests/` — contract, unit, integration, e2e, failure, security, and
  performance tests per node.
- `.agent/` — the Graphlock control plane (graph, specs, fences, ledger,
  evidence).

## Build

The client builds with the pinned CMake presets. The upstream build
instructions are in `docs/platform-builds.md` (inherited). The locked
commands are:

```
sh scripts/build.sh          # configure + build via the locked preset
sh scripts/run-locked-command.sh configure
sh scripts/run-locked-command.sh unit
```

The locked preset is `linux-debug-nosan` on Linux (see
`.agent/state/COMMANDS.lock.tsv`). On other platforms use the matching
preset from `docs/platform-builds.md`:

```
cmake --preset macos-debug
cmake --build --preset macos-debug
```

**Do not use `cmake --build . --parallel` without a job count in a
Makefiles build tree** — a bare `--parallel` can exhaust RAM and swap.
Ninja presets default to a bounded job count.

## Contribution Rules (Upstream Preserved)

The inherited contribution rules at the repository root (`CONTRIBUTING.md`,
`docs/CONTRIBUTING.md`, `docs/README.md`) remain authoritative. Key rules:

1. Read `AGENTS.md`, the active ExecPlan, the current upstream instructions,
   and the relevant upstream skill before editing.
2. Use one Graphlock node and one milestone at a time. Commit format is
   `[EP-XXX][Mk] imperative summary`. Do not force push.
3. Change only static expected paths and approved discovered paths.
4. Follow current Mudlet Qt/C++ conventions in inherited integration code.
5. Keep the bridge minimal; Rust code follows repository-pinned formatting,
   lint, error, and unsafe-code policy.
6. Update feature and requirement traceability; add independent tests; run
   targeted then broad gates; document failure and rollback.
7. AI-assisted upstream contributions follow the currently verified Mudlet
   policy and require human testing and sign-off. An agent never fabricates
   a sign-off.

## Adding Code

New behavior lives in a namespaced boundary: a new Rust crate under
`wirecore/crates/`, a new schema under `schemas/wiremudder/`, and — only
with source evidence — a small boundary header under `src/wiremudder/`.
Inherited source paths may be edited only after exact source evidence and a
discovered-path amendment (AGENTS.md §7).

## Testing

Run the node verifier and the broad gates before committing:

```
sh scripts/node-verify.sh EP-XXX
sh scripts/verify.sh
```

Every milestone requires evidence, a ledger event, and a commit.

## Dependencies

A new dependency requires source, exact version, license, maintenance,
platform, supply-chain, size, performance, alternative, rollback, SBOM,
lockfile, and ADR evidence (AGENTS.md §10). Prefer inherited or already
pinned tools.

## Documentation

User-facing behavior is documented in the [User Guide](../user/README.md).
Design and operations live under `docs/wiremudder/`. Claims must be backed
by machine-readable evidence (SPEC-000-R08) — never document a capability
as working unless a test proves it.

## Security

Read `WIREMUDDER_SECURITY.md` before touching anything that handles input,
secrets, permissions, routing, or updates. Default deny. Redact logs and
evidence.

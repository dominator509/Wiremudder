# Wiremudder

A modern MUD client and agent-ready desktop shell, derived from the mature
[Mudlet](https://github.com/Mudlet/Mudlet) codebase and extended with a Rust
"wirecore" systems plane.

Wiremudder preserves the battle-tested Mudlet Qt client as its foundation and
adds new capability through narrow, evidence-backed boundaries rather than a
greenfield rewrite. See [LICENSE_STRATEGY.md](LICENSE_STRATEGY.md) for the
attribution and licensing model.

## Status

- **Upstream:** Mudlet, pinned at commit `77086c295f4adf59197e586e689d19bdde8e1008`
- **License:** GPL-2.0 (see [COPYING](COPYING))
- **Default branch:** `wire/development`
- **Release track:** `release/wiremudder-0.9.0-canary` (canary; nothing has been
  published for general distribution)

The inherited client remains fully functional. New systems are added
incrementally and are only advertised as operational when proven by real
controlled tests and live-fire.

## Repository layout

- `src/` — inherited Mudlet-derived Qt/C++ client (`mudlet` executable)
- `wirecore/crates/` — Rust systems plane, one crate per bounded system
  (wire-soul, wire-agents, wire-copilot, wire-quest, wire-tactical,
  wire-routing, wire-world-brain, wire-world-graph, wire-storage,
  wire-telemetry, wire-privacy, wire-secrets, wire-renderer, and more)
- `schemas/wiremudder/` — canonical schemas for the wire systems
- `tests/wiremudder/` — per-system test batteries and gate scripts
- `compatibility/` — upstream compatibility oracles
- `docs/` — developer and contributor documentation
- `scripts/` — control-plane and maintenance scripts

## The agent plane

The wirecore plane implements policy-first agent systems on top of the client:

- **wire-soul / wire-agents** — soul documents, role councils, permission
  matrices, skill provenance, and audit; validated by failure, security, and
  performance matrices.
- **wire-copilot** — an in-client player copilot (explanations, confidence,
  citations) compiled into the client and certified in live-fire against a
  real local model (Ollama / tinyllama), with zero privacy leaks observed.
- **wire-quest / wire-tactical / wire-routing / wire-renderer** — task
  framing, tactical execution, model routing, and rendering systems under
  active development behind their gates.

Systems that are not yet live-fire certified are documented as such; optional
providers stay disabled until real certification.

## Building

The client uses CMake presets. Configure with a platform preset such as
`linux-debug` or `windows-debug`:

```
cmake --preset linux-debug
cmake --build --preset linux-debug
```

Platform-specific guidance lives in [docs/platform-builds.md](docs/platform-builds.md);
CI configurations are under `.github/workflows/` (`build-mudlet.yml`,
`build-mudlet-win.yml`, `build-mudlet-pr.yml`).

## Contributing

See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) and
[docs/AI-ASSISTANTS.md](docs/AI-ASSISTANTS.md).

## License

Wiremudder is an attribution-preserving derivative of Mudlet, licensed under
the GNU General Public License version 2 (see [COPYING](COPYING)). Upstream
copyright notices and third-party license notices are preserved in
`licenses/`; combined-distribution obligations are tracked in
[LICENSE_STRATEGY.md](LICENSE_STRATEGY.md).

# Decisions and ADR Index

| ADR | Decision | Status | Summary |
| --- | --- | --- | --- |
| `ADR-0001` | Fork Mudlet Instead of Rebuilding the Client | Accepted | Preserve the mature Qt/C++/Lua codebase and Git history. Reject a greenfield rewrite. |
| `ADR-0002` | Keep Qt as the Initial Desktop Shell | Accepted | Add WireMudder Qt surfaces and avoid Tauri/React until an alternate-client node is justified. |
| `ADR-0003` | Use an Isolated Rust WireCore Sidecar | Accepted with EP-005 validation | Place new AI, memory, voice, renderer coordination, storage, and diagnostics outside the Mudlet process. |
| `ADR-0004` | Require Independent Behavioral Oracles | Accepted | Reference behavior, controlled servers, corpora, and product decisions approve compatibility, not implementation-authored tests alone. |
| `ADR-0005` | Make Feature Coverage Machine-Checked | Accepted | Every feature maps to specification, node, test, proof, source, profile, and status. |
| `ADR-0006` | Use Staged Node Preflight | Accepted | Core development is not blocked by missing optional provider credentials; uncertified adapters remain disabled. |
| `ADR-0007` | Use Capability Certification States | Accepted | Declared, implemented, tested, live-fire-certified, disabled, and blocked are distinct. |
| `ADR-0008` | Permit Evidence-Backed Brownfield Path Amendments | Accepted | Inherited paths discovered after EP-000 require a source-evidence file and expected-path amendment. |
| `ADR-0009` | Use Release Profiles | Accepted | Core, AI, immersion, developer, and full releases have honest capability matrices. |
| `ADR-0010` | Minimize Upstream Divergence | Accepted | No mass rename; classify patches and contribute generic fixes when practical. |
| `ADR-0011` | Default to Compatible Open-Source Distribution | Accepted pending EP-000 legal inventory | Preserve source and attribution; stop for unresolved license judgment. |
| `ADR-0012` | Disable Auto-Deploy and Agent Signing | Accepted | Agents prepare release artifacts; maintainers sign and publish manually. |
| `ADR-0013` | Use Local-First Storage and Export | Accepted pending EP-014 benchmark | SQLite is the default candidate; append-only transcripts and rebuildable indexes are mandatory. |
| `ADR-0014` | Bind All Work to the Performance Constitution | Accepted | P0/P1 budgets and optional degradation are release gates. |
| `ADR-0015` | Keep Inherited Replacements Reversible | Accepted | Any strangler replacement retains the old implementation through at least one stable release. |

## Decision Rule

A material architecture, security, data, dependency, license, compatibility, performance, provider, or release fork requires an ADR. The ADR records evidence, alternatives, consequences, reversal, affected features, specifications, nodes, and tests. Conversation history is never the decision ledger.

## ADR Files

Individual ADRs live under `docs/adr/`.

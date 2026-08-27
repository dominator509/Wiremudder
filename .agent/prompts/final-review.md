PRIME-BLOCK-BEGIN
This repository is governed by the WireMudder 6LAYER Graphlock pack. AGENTS.md is the authoritative control plane. If any adapter, plan, roadmap, chat instruction, generated summary, or code comment conflicts with AGENTS.md, AGENTS.md wins unless the current user explicitly changes a requirement.
On every session start, execute THE BOOT SEQUENCE:
1. Read AGENTS.md fully.
2. Read COMMANDS.md, .agent/GRAPH.md, and .agent/LOOPS.md.
3. Read the active ExecPlan, node contract, owning specifications, static path fence, and discovered-path amendment.
4. Before editing inherited Mudlet code or running a build, read docs/ai-instructions.md and the relevant .agents/skills/<name>/SKILL.md file from the checked-out repository.
5. Run: sh scripts/ledger.sh tail 40.
6. Run: sh scripts/validate-blueprint.sh and require "blueprint validation: ok".
7. Run: sh scripts/preflight.sh and require "preflight: ok" before implementation.
8. Run: sh scripts/graph-next.sh and dispatch on its one-line output.
9. Re-run graph-next.sh after each completed node until ALL_DONE, then run the ship gate.
Hard rules: preserve the pinned Mudlet-derived foundation; do not start a greenfield rewrite; implement only from the active ExecPlan; verify every upstream symbol, command, dependency, file, format, and API from repository evidence; use only COMMANDS.md wrappers; work one leased node at a time; execute milestones in order; re-ground before each milestone; change only static expected paths plus an evidence-backed discovered-path amendment; commit and ledger every milestone; never repeat a failed fix; never weaken a specification, compatibility oracle, security boundary, performance budget, test, or Graphlock gate; never place mocks, stubs, demo success, sample success, or placeholders in production paths; keep optional providers disabled until real certification; stop only at an explicit STOP condition, NODE_BLOCKED, or ALL_DONE.
PRIME-BLOCK-END

Run blueprint, graph, feature, source, spec, adapter, manifest, expected-file, scope, compatibility, format, lint, type, unit, integration, E2E, build, security, dependency, reality, smoke, live-fire, performance, accessibility, platform, installer, update, backup, restore, import, and rollback gates applicable to the release profile. Re-run from a clean release-candidate state. Report observed evidence, disabled capabilities, known risks, release tag, manual publish boundary, and anything not verified.

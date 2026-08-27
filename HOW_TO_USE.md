# How to Use the WireMudder Graphlock Blueprint Pack

## 1. Preserve the Mudlet Foundation

Create a fork or clone that preserves Mudlet history. Do not copy Mudlet files into an unrelated empty repository.

```sh
git clone https://github.com/Mudlet/Mudlet.git WireMudder
cd WireMudder
git switch -c wire/development 77086c295f4adf59197e586e689d19bdde8e1008
git remote rename origin upstream
git remote add origin YOUR_WIREMUDDER_REPOSITORY_URL
```

The repository URL for `origin` is the only value in this guide that the operator must provide. Do not let an agent invent it.

## 2. Overlay This Pack

Extract this ZIP into the WireMudder repository root. Read `UPSTREAM_COLLISION_POLICY.md` first. The overlay intentionally replaces `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md` with Graphlock control adapters while preserving `docs/ai-instructions.md` and `.agents/skills`; `.gitignore` is a merged superset of the pinned upstream file. The pack uses `.agent/` for Graphlock while Mudlet task skills use `.agents/`, so both are retained.

Run:

```sh
sh scripts/validate-blueprint.sh
```

Expected output:

```text
blueprint validation: ok
```

## 3. Bootstrap the Governance Commit

```sh
git add -A
git commit -m "[6LAYER] bootstrap WireMudder Graphlock blueprint"
```

Do not create a green node tag at bootstrap. The first green tag is created only after EP-000 passes.

## 4. Complete Baseline Preflight

Copy `.env.example` to `.env`, use the pinned defaults, select the correct CMake preset for the current platform, and run:

```sh
sh scripts/preflight.sh
```

Baseline preflight intentionally requires the Mudlet-derived source tree. Provider credentials are node-scoped and optional; missing optional credentials keep those adapters disabled and uncertified rather than blocking core development.

## 5. Launch the Graph

Use `.agent/prompts/run-graph.md` as the one standing task. The repository, not chat history, is the coordination bus.

Codex CLI example:

```sh
codex --cd . --ask-for-approval never --sandbox workspace-write "$(cat .agent/prompts/run-graph.md)"
```

Claude Code example:

```sh
claude -p "$(cat .agent/prompts/run-graph.md)"
```

Use the current runner's documented noninteractive setting. Never copy an unverified flag from this document into a newer runner without checking its official documentation.

## 6. Observe and Resume

```sh
tail -f .agent/state/LEDGER.md
git log --oneline --decorate -30
sh scripts/graph-next.sh
```

A stopped agent releases its lease. A new agent runs the same boot sequence, reads the active ExecPlan, re-runs the last completed milestone sentinel, and continues at the first unchecked milestone.

## 7. Handle a Blocked Node

When the scheduler prints `BLOCKED EP-XXX`, read the structured report in that ExecPlan. Resolve only the named human decision, append a ledger decision note, follow the plan's recovery section, and relaunch. Do not bypass the block by editing a test, specification, graph edge, or verification script.

## 8. Release

Auto-deploy and automatic stable publication are disabled. EP-039 creates the proven release tag and a manual signing and publication packet. Maintainer-controlled keys never enter an agent environment.

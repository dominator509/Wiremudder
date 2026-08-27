# Upstream Overlay Collision Policy

## Purpose

The WireMudder pack overlays a small number of files that already exist in the pinned Mudlet tree. These collisions are intentional, evidence-backed, and limited to control-plane integration. Product source, package, test, build, and release files remain untouched until their owning graph node authorizes exact edits.

## Intentional Collisions at the Pinned Baseline

| Path | Pinned upstream evidence | WireMudder treatment |
| --- | --- | --- |
| `AGENTS.md` | Upstream content resolves to the Mudlet AI instructions, observed blob `5c901deef4843a07789bba3388a1ccac44b78e29`. | Replaced by the canonical Graphlock control plane. The boot sequence requires reading the preserved `docs/ai-instructions.md` and relevant `.agents/skills` before inherited work. |
| `CLAUDE.md` | Upstream content resolves to the same Mudlet AI instructions, observed blob `5c901deef4843a07789bba3388a1ccac44b78e29`. | Replaced by a byte-parity Graphlock adapter that delegates to `AGENTS.md` and then requires upstream instructions and skills. |
| `.github/copilot-instructions.md` | Upstream instructions observed at blob `4b27054438a03efecff96d8fdb552db4b702d6bb`. | Replaced by the Graphlock adapter for Copilot; the upstream instructions remain preserved at `docs/ai-instructions.md`. |
| `.gitignore` | Pinned upstream file observed at blob `cd577ad2ade13c6567ce3a69159490fae4c64d30`. | The complete pinned upstream ignore rules are retained and WireMudder Graphlock, Rust, evidence, and local-runtime exclusions are appended. |

## Preserved Upstream Authorities

The overlay does not replace `docs/ai-instructions.md`, `.agents/skills/build-mudlet/SKILL.md`, `.agents/skills/open-pr/SKILL.md`, `CMakePresets.json`, Mudlet source, existing CI workflows, packaging, licenses, or tests. EP-000 re-verifies these files and hashes in the actual fork.

## Collision Gate

A future collision requires an accepted ADR, source evidence, exact path authorization, independent regression test, rollback, and authority-pack regeneration. A coding executor cannot add a collision by copying a file over upstream content.

# WireMudder Upstream Sync and Governance — design (EP-002)

## Patch Classification

Changes are classified per SPEC-001-R04:

- upstreamable: generic fixes prepared for upstream contribution.
- bridge: WireCore bridge, IPC, headless contracts.
- feature: new WireMudder capability.
- branding: branding metadata, names, assets.
- security: security hardening, secrets, permissions.
- graphlock: Graphlock governance, control plane, evidence.

The classifier `tests/wiremudder/ep002/unit/classify_patch.py` is
deterministic and fail-closed (unknown -> unclassified). Review enforces
the classification before merge.

## Remotes and Roles

- `upstream` = https://github.com/Mudlet/Mudlet.git (official, read).
- `origin` = https://github.com/dominator509/WireMudder.git (fork, write).
- No force-push or history rewrite across a completed green tag.

## Sync Drill

A controlled upstream change is merged on a dedicated sync branch:

1. `git fetch upstream development`
2. `git switch -c sync/drill-<id>`
3. `git merge upstream/development` (or cherry-pick a controlled commit)
4. Run gates: validate-blueprint, preflight, verify, live-fire.
5. On green, merge to wire/development and record before/after SHAs.
6. On failure, `git switch wire/development` and delete the sync branch
   (the previous green tag stays intact, SPEC-001-R10).

## Attribution and Licensing

- The fork preserves Mudlet history, LICENSE, COPYING, and notices.
- Combined work ships under compatible open-source terms (see
  LICENSE_STRATEGY.md); uncertainty is a STOP condition.
- AI-assisted commits carry Assisted-by and Signed-off-by trailers per
  docs/CONTRIBUTING.md.

## Branding Boundaries

- Branding applies to metadata, icons with provenance, package
  identifiers, docs, and narrowly verified UI strings only.
- No mass class rename, source move, or namespace churn (SPEC-001-R07).
- A branding change that increases merge conflict requires an ADR and a
  rollback path.

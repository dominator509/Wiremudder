# WireMudder Discovery Design — EP-000

## Purpose

EP-000 locks the evidence baseline for the Mudlet-derived foundation before
any product edit. This document records the design of the discovery layer:
what is inventoried, how evidence is recorded, and how gates consume it.

## Boundaries

- Read-only inventory of the inherited tree; no product source edits.
- Evidence is append-only JSONL with hash-verified output files.
- Commands are locked to authority-backed wrappers before any build.

## Data Model

- `UPSTREAM.lock.yaml` — provenance: repository, branch, pinned commit,
  stable release reference, source-document hashes (SPEC-001-R02).
- `.agent/state/upstream-tree.tsv` — schema v1: `path type mode size blob_sha`
  for every tracked path at the pinned commit (1393 paths observed).
- `.agent/state/source-evidence.jsonl` — schema v2: one record per verified
  inherited claim; fields include `evidence_id`, `path`, `symbol_or_range`,
  `claim`, `command`, `exit_code`, `output_sha256`, `agent_id`.
- `.agent/state/COMMANDS.lock.tsv` — key/command/evidence/owner/platform rows;
  a locked command must appear verbatim in its cited evidence output.

## Evidence Lifecycle

1. Record: `source-evidence-record.sh PATH SYMBOL CLAIM -- CMD` runs a
   read-only command, verifies the tree is unchanged, writes output + hash.
2. Verify: `source-evidence-check.sh` proves every record's output file
   exists and hashes match.
3. Consume: the node verifier, command lock, and discovered-path amendment
   all require evidence before inherited edits are legal.

## Gate Chain (boot sequence)

`validate-blueprint.sh` → `preflight.sh` → `graph-next.sh` → lease →
milestone verifier → scope audit → ledger → commit → `node-verify.sh` →
green tag. Each gate prints an exact sentinel; a missing sentinel fails.

## Operations and Rollback

- Regenerate the tree inventory with `tests/wiremudder/ep000/unit/gen_upstream_tree.py`.
- Rollback to the last green milestone via `git revert`; never cross a
  completed green tag.
- Any inherited edit requires a prior discovered-path amendment with
  source evidence, test path, and rollback note.

## Observed Commands (2026-08-27)

- Configure: `cmake --preset linux-debug-nosan`
- Build: `cmake --build --preset linux-debug-nosan`
- Unit: `ctest --preset linux-debug-nosan`
- Preset evidence: WM-SRC-000019 (CMakePresets.json)

## Risks

- Uninitialized gitlink submodules are inventoried, not built; a build
  node must initialize them with evidence before compiling.
- The upstream remote is authoritative; origin URL is operator-provided
  and not yet configured.

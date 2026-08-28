# EP-039 Ship Gate Design

## Purpose

EP-039 closes the WireMudder graph: run the final fresh ship gate, verify
evidence hashes and release-profile claims, create the release tag and manual
signing/publishing packet, append RUN_COMPLETE, and leave production
unpublished because auto-deploy is not authorized (WM-SPEC-028-R06).

## Boundaries

- `release/wiremudder/final/` — the 0.9.0-canary release boundary: manifest,
  provenance, SHA256SUMS, VERSION, release notes, known risks, compatibility,
  support, and license notices.
- `.agent/state/final-evidence/` — evidence index over the full corpus
  (`index.json`) plus the corpus aggregate hash.
- `docs/wiremudder/ship/` — ADR-0016 (inherited unit-gate defects), design and
  operations runbooks.

## Key invariants

1. AUTO_DEPLOY=false at every layer (.env, `scripts/probes/auto_deploy.sh`,
   manifest `auto_deploy` field). No automatic publication.
2. The agent never signs. `has_signature=false` and
   `signed_by_maintainer=false` are asserted by unit tests.
3. Every release claim traces to evidence (`CAPABILITY_MATRIX.tsv` rows point
   at `.agent/state/evidence/...` files or test directories).
4. The source archive reproduces from the recorded `source_commit`.
5. Unit-gate inherited failures are documented in ADR-0016 with replacement
   evidence; the gate is not weakened or retried (WM-SPEC-027-R09/R10).

## Flow

1. Fresh verify: the full 28-gate verify.sh chain runs; unit gate reports the
   two ADR-covered deterministic failures (blocking analysis is reported to
   the run gate, not silently retried).
2. Production readiness structural check: EP-000..EP-038 all have NODE_DONE
   ledger rows and green tags.
3. Evidence index hashes validate over real files.
4. Release claims gate under `full` profile: 244 features, all certified or
   explicitly disabled/blocked.
5. LF-039 live-fire: candidate oracle checks, checksum integrity, provenance
   honesty, stable-refusal of unsigned candidate, revocation, known risks,
   operations runbook.
6. Release tag `release/wiremudder-0.9.0-canary` at the proven commit; manual
   signing and publish packet emitted; RUN_COMPLETE appended; production not
   deployed.

## Commands (locked in COMMANDS.lock.tsv)

- `unit`: `ctest --preset linux-debug-nosan` (WM-SRC-000019)
- lint, typecheck, dependency_audit, license, performance, accessibility,
  platform, smoke: verified forms recorded WM-SRC-000332..000343.

## Observed behavior

- verify.sh reaches the unit gate; 106/110 ctest pass; the two deterministic
  ADR-covered failures stop the chain with exit 8 (blocking analysis reported).
- ReleaseTagVersionTest passes 3/3 under `CI=true` once pcre2grep is
  provisioned (pcre2-utils package, Ubuntu 24.04).
- production_readiness.py: `production readiness structural: ok` after all 39
  prior nodes are NODE_DONE + green.

## Rollback

- Revert the release tag: `git tag -d release/wiremudder-0.9.0-canary`.
- Restore the previous candidate directory from the recorded source commit.
- The final boundary is additive; no inherited path is modified.

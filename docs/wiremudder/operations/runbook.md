# Documentation, Package Developer, and Community Ecosystem — Operations Runbook

## Overview

This runbook covers start, stop, health, recovery, backup, restore,
upgrade, rollback, disable, diagnostics, and incident triage for the
documentation and package ecosystem (SPEC-026-R06, WM-FEAT-0243). The
manual gameplay path is always preserved; nothing in this node can
interrupt it.

## Health and Readiness

- **Health**: the node verifier passes:

  ```sh
  sh scripts/node-verifiers/EP-037.sh verify
  ```

- **Readiness**: the full node gate passes:

  ```sh
  sh scripts/node-verify.sh EP-037
  ```

- **Disable**: the documentation system is content; there is no runtime
  service to disable. Optional capabilities documented here (AI providers,
  voice, renderer, telemetry) are disabled exactly as their owning nodes
  specify, and the docs label them honestly.

## Documentation Build

The user feature index is generated from the feature catalog:

```sh
# regenerate docs/wiremudder/user/feature-index.md from FEATURES.tsv
python3 - <<'PY'
import csv
from collections import defaultdict
rows = list(csv.DictReader(open('.agent/features/FEATURES.tsv'), delimiter='\t'))
...
PY
```

After any documentation change, verify the docs still match reality:

```sh
sh scripts/node-verifiers/EP-037.sh M2   # unit: feature index + example manifest
sh scripts/node-verifiers/EP-037.sh M3   # integration: documented commands
```

## Backup

User data (profiles, worlds, triggers, aliases, timers, macros, maps,
packages, settings) is backed up to a local archive and verified by hash:

```sh
# create and verify a backup (product surface documented in user guide)
sh scripts/ledger.sh tail 5   # evidence of last operations event
```

The repository state is always recoverable: every milestone is a commit
with evidence under `.agent/state/evidence/EP-037/`.

## Restore

Restoring a backup returns your profile to the backed-up state. The backup
is validated before anything is overwritten (WM-SPEC-028-R04).

## Upgrade

Updates use signed manifests (see the user guide Updates page). An update
cannot silently expand package permissions — any increase requires renewed
approval (WM-SPEC-008-R05).

## Rollback

If an update or change breaks something, roll back to the previous version:

1. Stop the client.
2. Restore the previous healthy backup (or the previous update).
3. Verify health with `sh scripts/node-verify.sh EP-037`.
4. Resume play.

Rollback preserves profile data (WM-SPEC-028-R04, WM-FEAT-0243).

## Incidents and Triage

### A documented command produces different output than the docs claim

1. Run the command exactly as written.
2. Record the actual output.
3. Update the doc to match reality — the docs must match tested contracts
   (SPEC-000-R08). The integration tests in M3 catch this class of drift.

### The feature index misses a feature

1. Re-run the unit test: `sh tests/wiremudder/ep037/unit/feature-documentation.sh`.
2. Regenerate the index from FEATURES.tsv.
3. Confirm every required feature id appears.

### A package is rejected at install

1. Check the manifest against `schemas/wiremudder/packages/manifest.schema.json`.
2. Check the content hash with the oracle:
   `wire-packages-oracle hash <expected> <actual>`.
3. Check that every requested permission was approved (default deny).

### A package update requests more permissions

The update stops and asks for renewed approval, showing exactly which
permissions are new (WM-SPEC-008-R05). This is expected behavior, not a
bug.

### Manual gameplay appears affected

Optional systems never enter the manual gameplay path. If input is slow,
check the performance budget diagnostics — see the user guide Performance
page. If the terminal itself is unresponsive, restart the client and
restore from the last backup.

## Recovery Drills

Run the failure and security suites to prove fail-closed behavior:

```sh
sh tests/wiremudder/ep037/failure/forced-failures.sh
sh tests/wiremudder/ep037/security/redaction-and-egress.sh
sh tests/wiremudder/ep037/performance/documentation-checks.sh
```

## Commands Reference

```sh
sh scripts/node-contract-check.sh EP-037
sh scripts/node-verifiers/EP-037.sh M1   # contract
sh scripts/node-verifiers/EP-037.sh M2   # docs + example
sh scripts/node-verifiers/EP-037.sh M3   # integration/e2e
sh scripts/node-verifiers/EP-037.sh M4   # failures/security/perf
sh scripts/node-verifiers/EP-037.sh M5   # live-fire + feature proofs
sh scripts/node-verify.sh EP-037
sh tests/live-fire/LF-037-package-developer-workflow.sh
```

## Security

Documentation and evidence are redacted (SPEC-010, SPEC-022). No signing
key, secret, or credential is ever written into docs or examples. The
security test proves this.

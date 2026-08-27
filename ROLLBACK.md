# WireMudder Rollback Policy

## Triggers

P0/P1 regression, emergency-stop failure, unsafe command, data corruption, privacy or secret leak, route fallback, package escape, updater verification failure, installer failure, crash loop, incompatible migration, or material accessibility regression.

## Code Rollback

Return to the previous green milestone or node tag without crossing a completed lower node. Record the target in the ledger. Re-enter through the declared fallback.

## Runtime Rollback

Disable the optional feature, stop its worker, restore the inherited implementation or previous signed artifact, restore backed-up data when required, rebuild indexes, and run smoke and integrity checks.

## Verification

Confirm text gameplay, profile data, command safety, privacy mode, routing, packages, updates, and diagnostics. Record evidence and user-visible impact.

## Postmortem

Preserve sanitized evidence, root cause, missed gate, remediation, regression proof, and whether the specification or Graphlock pack needs a controlled update.

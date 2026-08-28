# WireMudder Maintenance Operations

This directory holds runbook material for the bounded bug automation and
remediation subsystem (EP-029). The owning node's operations runbook lives
under `docs/wiremudder/bug-automation/operations/`; this directory is the
maintenance boundary where operators record remediation campaigns, canary
windows, and rollback confirmations.

## Scope

- Remediation campaigns are bounded (SPEC-019-R09): intake, reproduction,
  diagnosis, patch, validation, review, canary, rollback, DONE or BLOCKED.
- No production code is edited automatically (EP-029 fallback).
- BLOCKED reports reach a human review board with complete evidence.

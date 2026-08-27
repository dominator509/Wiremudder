# WireMudder Contracts Operations — EP-004

## Health

- `python3 tools/schema-bindings/generate_bindings.py` prints
  `schema-bindings: ok`.
- `sh scripts/feature-coverage-check.sh` and
  `sh scripts/spec-trace-check.sh` print ok.

## Readiness

Contracts are ready when: >=6 canonical schemas exist under
schemas/wiremudder/, bindings.manifest.json is current, and the trace
gates pass.

## Regenerate Bindings

```sh
python3 tools/schema-bindings/generate_bindings.py
```

## Recovery and Restart

- A schema with invalid JSON breaks generation; fix the schema and
  regenerate.
- A gate failure means catalog/matrix drift; reconcile the TSV, not the
  gate.

## Backup and Restore

- Schemas and manifest are in-git; regenerate from source.

## Upgrade and Rollback

- Schema changes require `schema_version` bumps (const fields) and the
  spec-update process; rollback = git revert.

## Incident Response

- Secret pattern found in a schema: remove it, rotate, rescan with
  `security/001-schema-secret-scan.sh`.
- Manifest out of date: regenerate and commit with the schema change.

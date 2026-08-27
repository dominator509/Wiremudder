# WireMudder Release Policy

## Versioning

Use semantic versioning for WireMudder public contracts and application releases. Record the inherited Mudlet baseline separately.

## Release Types

Development, canary, beta, and stable. A release profile is included in the artifact metadata and release notes.

## Candidate Criteria

Required graph nodes green, capability matrix honest, dependencies frozen, compatibility and platform evidence complete, no critical issue, known risk documented, rollback proven, and source plus notices ready.

## Publication Authority

Agents may create a candidate and tag only through EP-039 after all gates. Stable artifact signing and publication require the maintainer. AI-assisted commits follow the current verified upstream contribution policy and never fabricate a human sign-off.

## Post-Release

Run smoke, review opt-in crash and health signals, monitor package/update failures, pause rollout on regression, and retain the previous healthy artifact and rollback manifest.

# WireMudder Deployment and Distribution

## Model

WireMudder is a desktop and headless application distributed as source and platform artifacts. There is no required hosted production service for the core release.

## Artifacts

A release includes source archive, Windows installer, macOS artifact, Linux artifact, checksums, signatures, SBOM, provenance, license notices, release notes, feature and platform capability matrix, migration notes, rollback notes, and support documentation.

## Channels

Development, canary, beta, and stable are separate. A channel change is explicit and does not silently enable optional asset or provider downloads.

## Release Flow

1. EP-038 freezes a release candidate and evidence index.
2. EP-039 runs the fresh ship gate.
3. The release tag is created on the proven commit.
4. Build and packaging artifacts are hashed.
5. The maintainer performs the manual signing steps with keys outside the agent environment.
6. The maintainer performs the manual publication command from the EP-039 packet.
7. Post-publish smoke and opt-in health review run.

## Auto-Deploy

`WIREMUDDER_AUTO_DEPLOY` must be `false`. Agents do not publish stable artifacts, mutate a production update channel, or access signing keys.

## Upgrade and Migration

Back up user data, stop or defer active sessions when required, verify signatures and compatibility, apply resumable migrations, launch and run health checks, and restore or quarantine on failure.

## Rollback

Rollback uses the prior signed artifact and backed-up data or a migration restore. The previous healthy release remains available. A rollback never silently discards new user data.

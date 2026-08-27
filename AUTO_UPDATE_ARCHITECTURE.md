# WireMudder Secure Update Architecture

## Status

This is an accepted architecture contract, not a claim that the updater exists.

## Lanes

Core app, provider adapters, context rules, command packs, plugin packs, renderer packs, audio packs, local model assets, and help indexes are separate. A lane has independent version, hash, signature, provenance, compatibility, permissions, rollout, rollback, and disable policy.

## Lifecycle

Check only when idle or user-requested, fetch signed metadata, validate compatibility and permissions, download resumably, verify hash and signature, back up required data, stop affected components, install atomically, migrate safely, restart, run health and smoke, mark healthy or restore/quarantine, and record audit.

## Rejection

Reject unsigned, invalid, corrupted, incompatible, unexpected downgrade, permission-expanding, revoked, or unlicensed artifacts. Local Only Lockdown blocks remote checks and downloads.

## Signing

Agents do not receive signing keys. EP-034 proves verification and rollback with test keys in a controlled test zone. Stable signing is manual and maintainer-controlled.

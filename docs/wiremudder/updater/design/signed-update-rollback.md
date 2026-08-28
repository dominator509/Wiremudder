# Signed Update and Rollback — Design

## Purpose

WireMudder updates must be signed, provenance-aware, and rollback-capable
(SPEC-020). This design covers the EP-034 secure updater: signed core and
asset manifests, separate update lanes, channel policy, resumable downloads,
permission review, health confirmation, migration safety, staged rollout
metadata, quarantine, and rollback. Manual text gameplay is never blocked by
update infrastructure; the updater is a P4 background system (SPEC-004).

## Boundaries

- `wirecore/crates/wire-updater/` — deterministic Rust core. Verifies
  manifests and artifacts, applies admission policy, models resume, health,
  migration, and quarantine. **Never signs.** Signing keys stay outside
  agents (SPEC-020-R09).
- `src/wiremudder/updater/` — Qt model-side boundary (C++). Declares the
  typed surface; binds to the Rust core through the bridge. No UI, no
  gameplay path, no settings mutation.
- `schemas/wiremudder/update/manifest.schema.json` — canonical signed
  manifest schema.
- `tools/update-fixtures/` — TEST-ONLY. Generates ephemeral Ed25519 test
  keypairs and real signed artifacts for the EP-034 suites and live-fire.
  Never used for production signing.
- `tests/live-fire/LF-034-signed-update-rollback.sh` — the live-fire proof.

## Flow

1. **Check** — client fetches the manifest for its channel/lane (gated by
   Local Only Lockdown, SPEC-010-R04).
2. **Verify** — `Verifier::verify_manifest` parses, checks schema version,
   rejects unsigned artifacts, and validates the Ed25519 signature over the
   canonical payload. `Verifier::verify_artifact` compares the artifact
   SHA-256 and size.
3. **Admit** — `UpdatePolicy::admit` rejects permission expansion, rejects
   unexpected downgrades, applies staged rollout gating (fraction + kill
   switch), defers during active sessions, and honors lockdown.
4. **Resume** — `ResumeState` tracks contiguous received bytes; an
   interrupted download resumes from its exact offset.
5. **Install with migration safety** — a manifest with a higher migration
   version requires a completed backup before install and a restore on
   rollback (`plan_migration`).
6. **Confirm health** — `StartupTracker` counts failed startups; the
   configured bound (default 3) triggers quarantine and rollback guidance.
   Clean startup resets the counter and releases quarantine.
7. **Rollback** — quarantine + guidance direct the user to restore the
   previous healthy version from backup (SPEC-028-R04).

## Denial states (SPEC-025 typed)

`denied_unsigned`, `denied_invalid_signature`, `denied_hash_mismatch`,
`denied_permission_expansion`, `denied_downgrade`, `denied_incompatible`,
`deferred_active_sessions`, `deferred_rollout`, `deferred_lockdown`,
`error`. Every denial is deterministic, typed, and redacted.

## Security

- Keys are hardware-backed or maintainer-controlled; agent environments
  never contain signing keys (SPEC-020-R09, acceptance obligation 6).
- The core uses `verify_strict` (Ed25519) and full-artifact SHA-256;
  malformed or oversized input is rejected (SPEC-025).
- Prompt injection cannot override update policy (SPEC-022-R04): policy
  rules are code, not text.
- Local Only Lockdown blocks remote update and asset checks unless
  individually and visibly overridden (SPEC-010-R04).

## Performance

All update work is P4. The hot-path verifier runs in microseconds on a
real artifact (measured fixture: p50 ~1.5 µs, p95 ~1.7 µs, budget 1 ms).
Resume bookkeeping is O(1) per chunk.

## Operations

Health, readiness, disable, recovery, backup, restore, upgrade, rollback,
and uninstall instructions live in
`docs/wiremudder/updater/operations/runbook.md`.

## Commands

```sh
# Generate an ephemeral TEST keypair (never for production)
cargo run --release --manifest-path tools/update-fixtures/Cargo.toml -- \
  gen-key /tmp/update-keys

# Sign a real artifact into a manifest (TEST ONLY)
cargo run --release --manifest-path tools/update-fixtures/Cargo.toml -- \
  sign /tmp/update-keys/keypair.json core.bin core_app stable 2.0.0

# Verify the signed manifest with the Rust core
cargo run --release --manifest-path wirecore/crates/wire-updater/Cargo.toml \
  --bin wire-updater-oracle -- verify-manifest <pubkey-hex> core.manifest.json

# Run the node verifier
sh scripts/node-verify.sh EP-034
```

## Rollback

- Any inherited edit is reverted with `git checkout -- <path>` (see the
  discovered amendment).
- A quarantined update is replaced by restoring the previous healthy
  version; the runbook drills backup, restore, and uninstall.
- Never cross a completed green tag during rollback (LOOPS.md).

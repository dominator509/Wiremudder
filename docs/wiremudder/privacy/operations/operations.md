# WireMudder Privacy Operations

Node: EP-006 (Privacy, Consent, Secrets, Local Only)
Specifications: SPEC-010, SPEC-022, SPEC-023, SPEC-025.

## Health and readiness

- `SecretVaultQt::backendAvailable()` reports whether the OS keyring
  (QtKeychain) is usable; when false, the vault runs the documented
  local-only fallback. The vault is always functional either way.
- `PrivacyFirewall` is stateless-denial-first: `canEgress` returns
  false unless explicitly unlocked. No health probe is needed; the
  policy object is always ready.

## Disable

- Do not construct `PrivacyFirewall` / `SecretVaultQt`. The client runs
  with no privacy modules (fallback posture) — the default.
- Runtime: `setLockdown(true)` + `setMode(LocalOnly)` restores the
  denial-first posture at any time.

## Recovery

- OS keyring disappears: `backendAvailable()` flips false on the next
  construction; the vault falls back to memory (local-only). No data
  corruption; stored secrets remain accessible until the process ends.
- Consent revocation is idempotent: re-revoking a revoked receipt is a
  no-op.

## Backup / restore

- Secrets: with an OS backend, the keyring is the backup (OS-managed).
  The local-only fallback is intentionally non-persistent; do not
  export secret values (WM-SPEC-010-R07). A separately encrypted user
  export is a later-node obligation (SPEC-023-R07).
- Consent receipts: serialize the registry (`ConsentRegistry::serialize`
  in Rust) for audit/backup; restore by granting the same receipts.

## Upgrade

- Rust core: `cargo test` per crate; `Cargo.lock` pins `regex` 1.13.1
  and the serde family. Upgrade paths are lockfile-driven and
  reversible.
- QtKeychain: system package (`qtkeychain-qt6-dev` 0.14.2). The vault
  probes availability at construction, so a keyring upgrade needs no
  code change.

## Rollback

- Code: `git revert` of the EP-006 M4 (and M3/M2) commits.
- Runtime: stop constructing the privacy modules; no config change.
- The dependency (`regex`) is removed by reverting M2; the lockfile
  restores the prior tree.

## Bounded recovery runbook

1. Observe: a privacy test failed or `backendAvailable()` flipped.
2. Diagnose: for keyring issues, check `gnome-keyring`/`kwallet`
   availability; for policy divergence, re-run
   `tests/wiremudder/ep006/e2e/001-egress-lockdown.sh`.
3. Recover: restart the client (vault re-probes); re-grant revoked
   consent only with explicit user action (WM-SPEC-010-R02).
4. Escalate: if the cross-implementation matrix diverges, fix the
   divergent implementation (both must implement SPEC-010 identically)
   and re-run the E2E oracle.

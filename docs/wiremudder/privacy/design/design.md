# WireMudder Privacy Design — Privacy Firewall, Consent, Secrets, Local Only

Status: implemented and evidenced at EP-006 M3 (integration + E2E proven).
Owns: WM-FEAT-0093..0097, 0099..0101, 0190, 0220, 0222.
Specifications: SPEC-010, SPEC-022, SPEC-023, SPEC-025.

## 1. Architecture

Privacy is a denial-first boundary with two real implementations of the
same SPEC-010 rules:

- Rust core: `wirecore/crates/wire-privacy` (egress policy, consent
  registry, redaction engine) and `wirecore/crates/wire-secrets`
  (secret classes, backends, leak redaction).
- C++/Qt adapter: `src/wiremudder/privacy/` (`PrivacyFirewall`,
  `SecretVaultQt` with QtKeychain) — the surface the Mudlet-derived
  client will use. The E2E milestone cross-validates both
  implementations against a shared policy matrix.

```
┌──────────────────────────┐   same SPEC-010 rules   ┌──────────────────────────┐
│ Qt client                │ ◄── cross-validated ───► │ Rust wire-privacy core   │
│  PrivacyFirewall (C++)   │                          │  EgressPolicy/Consent/   │
│  SecretVaultQt (QtKeych.)│                          │  RedactionEngine         │
└──────────────────────────┘                          └──────────────────────────┘
```

## 2. Denial-first egress (WM-SPEC-010-R03/R04, WM-SPEC-022-R03)

Default posture: `LocalOnly` + `lockdown = true` with an empty
allow-list. `canEgress(category, destination)` returns denied unless:

1. the destination is allow-listed (`addAllowedDestination`), AND
2. a denied category (`ai`, `speech`, `asset-generation`, `telemetry`,
   `package-download`, `update-check`) carries a user-visible override
   whose `consent_receipt_id` references a granted, scoped receipt.

Routing is lawful-only (WM-SPEC-022-R07): proxy procurement, identity
rotation, fingerprint spoofing, account automation, spam, and ban
evasion are always denied (`canRoutePurpose`).

## 3. Consent receipts (WM-SPEC-010-R09)

Scoped, versioned, revocable, tied to feature, provider, data class,
profile, and time. `grantConsent`/`revokeConsent`/`isConsented` in the
C++ surface mirror the Rust `ConsentRegistry` (grant validates,
revocation is idempotent, scoping is exact on feature/provider/
data_class/profile).

## 4. Secrets Vault (WM-SPEC-010-R06/R07)

- `SecretVaultQt` probes the OS keyring with a sentinel read at
  construction. With a keyring service (gnome-keyring/kwallet) it uses
  QtKeychain (OS-backed storage). Headless (no keyring), it uses the
  documented local-only in-memory fallback until an OS backend is
  certified — the node's declared fallback posture.
- Values are never logged, never Debug/Display-printed, never
  serialized (the Rust `SecretEntry` skips the value in serialization;
  the C++ vault keeps payloads out of logs).
- `redactLeak` replaces every stored secret value with
  `[REDACTED:secret]` in any text — guaranteed no secret enters AI
  context, logs, or transcripts (WM-SPEC-010-R07).

## 5. Exact commands

```sh
# Rust core tests
CARGO_TARGET_DIR="$PWD/wirecore/target" cargo test \
  --manifest-path wirecore/crates/wire-privacy/Cargo.toml
CARGO_TARGET_DIR="$PWD/wirecore/target" cargo test \
  --manifest-path wirecore/crates/wire-secrets/Cargo.toml

# C++ surface + harness (Qt 6.8.2 + QtKeychain 0.14.2)
export PKG_CONFIG_PATH=/opt/qt/6.8.2/gcc_64/lib/pkgconfig
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) \
  -I/usr/include/qt6keychain -I"$PWD" \
  tests/wiremudder/ep006/harness/privacy_harness.cpp \
  src/wiremudder/privacy/privacy_firewall.cpp \
  src/wiremudder/privacy/secret_vault.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -lqt6keychain \
  -Wl,-rpath,/opt/qt/6.8.2/gcc_64/lib -o /tmp/wm-priv-harness

# Integration + E2E proofs
sh tests/wiremudder/ep006/integration/001-privacy-firewall.sh
sh tests/wiremudder/ep006/integration/002-secrets-vault.sh
sh tests/wiremudder/ep006/e2e/001-egress-lockdown.sh
```

## 6. Observed behavior (M3 evidence)

- `integration privacy-firewall: ok` — lockdown denies by default;
  proxy procurement denied; allow-list alone does not unlock a denied
  category; a non-visible override is rejected; a user-visible
  consent-backed override unlocks only the allow-listed destination;
  consent is scoped to feature/provider/data_class/profile and
  revocation is effective; redaction is deterministic.
- `integration secrets-vault: ok` — store/retrieve/remove round trip;
  duplicates rejected; missing ids return nothing; `redactLeak`
  removes every occurrence of every stored value; OS backend probe
  honest (`backend_available=0` headless).
- `e2e egress-lockdown: ok (6 decisions identical)` — the Rust core and
  the C++ firewall produce byte-identical decisions on the shared
  policy matrix (canEgress ai/speech/telemetry × destinations,
  canRoute proxy-procurement/translation).

## 7. Data scope, privacy, and audit

- No remote egress exists in this node: the firewall is denial-first
  and no adapter actually sends data anywhere. Egress certification is
  explicitly deferred (M3 content item 6).
- Consent receipts and overrides are the audit surface; the ledger of
  grants/revocations is queryable through the consent registry.
- Secrets are excluded from serialization, logs, and AI context by
  construction.

## 8. Rollback

- `git revert` of the EP-006 M3 commit removes the C++ implementations,
  harness, tests, and design docs while leaving the Rust core (M2)
  intact. Runtime disable: never construct `PrivacyFirewall` /
  `SecretVaultQt`; the fallback (no privacy modules) is the default.

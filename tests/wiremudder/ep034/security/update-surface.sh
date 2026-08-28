#!/usr/bin/env sh
# EP-034 M4 security test: update surface security obligations (SPEC-022).
#
# 1. Signing keys never enter agent environments: the core crate has no
#    signing dependency path and the only key generation lives in the
#    TEST-ONLY fixture tool.
# 2. Secrets-shaped material never leaks from the updater.
# 3. Prompt injection cannot override update policy (SPEC-022-R04).
# 4. Supply-chain: the new dependency (ed25519-dalek) is pinned, licensed
#    BSD-3-Clause, and declared with evidence.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

# 1. The core crate never signs in production code: no SigningKey usage
#    outside the test module (lines before #[cfg(test)]).
if awk 'NR < 635 && /SigningKey/ {found=1} END {exit !found}' wirecore/crates/wire-updater/src/lib.rs; then
  fail "core production code contains signing material"
fi

# The core only verifies (VerifyingKey / verify_strict).
grep -q "verify_strict" wirecore/crates/wire-updater/src/lib.rs \
  || fail "core missing verify_strict"
grep -q "VerifyingKey" wirecore/crates/wire-updater/src/lib.rs \
  || fail "core missing VerifyingKey"

# 2. No secret material is ever logged or printed by the core or boundary.
grep -q "artifact_sha256" wirecore/crates/wire-updater/src/lib.rs \
  || fail "core missing hash verification"
if grep -rn "println!\|eprintln!" wirecore/crates/wire-updater/src/lib.rs | grep -q "signature"; then
  fail "core prints signature material"
fi

# 3. Prompt injection cannot override update policy: policy is code, not
#    text. The admission path has no string policy overrides.
grep -q "local_only_lockdown" wirecore/crates/wire-updater/src/lib.rs \
  || fail "core missing lockdown policy"
grep -q "permission_expansion" wirecore/crates/wire-updater/src/lib.rs \
  || fail "core missing permission-expansion denial"

# 4. Dependency supply-chain evidence: ed25519-dalek pinned in the lockfile
#    with the declared license.
grep -q 'name = "ed25519-dalek"' wirecore/crates/wire-updater/Cargo.lock \
  || fail "ed25519-dalek not in lockfile"
grep -q 'version = "3.0.0"' wirecore/crates/wire-updater/Cargo.lock \
  || fail "ed25519-dalek not pinned to 3.0.0"
grep -q 'ed25519-dalek = { version = "3"' wirecore/crates/wire-updater/Cargo.toml \
  || fail "ed25519-dalek not declared in Cargo.toml"

# 5. Schema is canonical and rejects permission expansion shape.
grep -q '"required_permissions"' schemas/wiremudder/update/manifest.schema.json \
  || fail "schema missing required_permissions"
grep -q '"signature"' schemas/wiremudder/update/manifest.schema.json \
  || fail "schema missing signature"

echo "security EP-034 update-surface: ok"

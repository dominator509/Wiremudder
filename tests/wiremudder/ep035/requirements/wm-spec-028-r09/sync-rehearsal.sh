#!/usr/bin/env sh
# WM-SPEC-028-R09 (live-fire): upstream sync is rehearsed before every
# stable release and generic fixes are assessed for contribution.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

oracle="cargo run --quiet --release --manifest-path packaging/wiremudder/Cargo.toml --bin wire-release-oracle --"

tmp=$(mktemp -d /tmp/ep035_r09_XXXX)
trap 'rm -rf "$tmp"' EXIT
out="$tmp/out.log"

# 1. Sync rehearsal is a real gate: pending rehearsal blocks stable
#    readiness.
cat > "$tmp/manifest.json" <<'JSON'
{"schema_version":1,"channel":"stable","version":"1.0.0","upstream_commit":"abc","source_commit":"def","artifacts":[],"has_source_archive":true,"has_binary":true,"has_checksums":true,"has_signature":true,"has_sbom":true,"has_provenance":true,"has_license_notices":true,"has_release_notes":true,"has_compat_matrix":true,"has_known_risks":true,"has_support_instructions":true}
JSON
$oracle sync-ready "$tmp/manifest.json" >"$out" 2>&1
grep -q "sync-pending:" "$out" || fail "sync rehearsal not enforced"

# 2. The sync/rehearsal discipline is documented in the runbook.
grep -q "Upstream Sync Rehearsal" docs/wiremudder/release/operations/runbook.md \
  || fail "runbook missing sync rehearsal section"
grep -q "generic" docs/wiremudder/release/operations/runbook.md \
  || fail "runbook missing generic-fix assessment"

# 3. The pinned upstream commit is real and tracked (SPEC-001).
[ -f UPSTREAM.lock.yaml ] || fail "missing UPSTREAM.lock.yaml"
grep -q "development_commit" UPSTREAM.lock.yaml || fail "lock missing development_commit"

echo "req WM-SPEC-028-R09: ok"

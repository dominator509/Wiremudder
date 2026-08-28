#!/usr/bin/env sh
# WM-FEAT-0244 (release profile): release candidate hardening — the
# frozen candidate is complete, verified, reproducible, and honestly
# claims only certified capabilities. Proven with real artifacts.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0244: FAIL - $1" >&2; exit 1; }

oracle=wirecore/target/release/wire-release-oracle
[ -x "$oracle" ] || fail "oracle binary missing"

cand=release/wiremudder/candidate

# 1. The candidate exists, is frozen at a canary version, and is complete.
[ -f "$cand/manifest.json" ] || fail "candidate manifest missing"
grep -q '"channel": "canary"' "$cand/manifest.json" || fail "not canary"
"$oracle" candidate-check "$cand/manifest.json" | grep -q "candidate-complete" \
  || fail "candidate incomplete"

# 2. Every claimed artifact verifies against real bytes.
(cd "$cand" && sha256sum -c SHA256SUMS >/dev/null) || fail "checksums failed"

# 3. The capability matrix claims exactly the certified features.
[ -f docs/wiremudder/release-candidate/CAPABILITY_MATRIX.tsv ] \
  || fail "capability matrix missing"
WIREMUDDER_RELEASE_PROFILE=full sh scripts/release-claims-check.sh >/dev/null \
  || fail "claims gate failed"

# 4. Known risks are explicit and honest.
[ -f docs/wiremudder/release-candidate/KNOWN_RISKS.md ] || fail "known risks missing"
grep -qi "not signed" docs/wiremudder/release-candidate/KNOWN_RISKS.md \
  || fail "unsigned status missing"

echo "feature-0244 WM-FEAT-0244 release-candidate-hardening: ok"

#!/usr/bin/env sh
# Contract test: governance policies exist and forbid mass rename /
# greenfield rewrite / source-delivery evasion.
set -eu
[ -f LICENSE_STRATEGY.md ] || { echo "FAIL: LICENSE_STRATEGY.md missing" >&2; exit 1; }
[ -f UPSTREAM_SYNC_POLICY.md ] || { echo "FAIL: UPSTREAM_SYNC_POLICY.md missing" >&2; exit 1; }
[ -f BRANDING_POLICY.md ] || { echo "FAIL: BRANDING_POLICY.md missing" >&2; exit 1; }
grep -qi "compatible open-source terms" LICENSE_STRATEGY.md || { echo "FAIL: license strategy lacks open-source commitment" >&2; exit 1; }
grep -qi "STOP condition" LICENSE_STRATEGY.md || { echo "FAIL: license strategy lacks STOP condition" >&2; exit 1; }
grep -qi "mass class renames" BRANDING_POLICY.md || { echo "FAIL: branding policy lacks no-mass-rename" >&2; exit 1; }
echo "contract governance-policies: ok"

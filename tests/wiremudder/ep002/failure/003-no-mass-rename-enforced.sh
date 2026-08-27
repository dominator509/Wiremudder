#!/usr/bin/env sh
# Failure test: branding policy must reject mass source renames — prove
# the classifier and policy agree that a rename of inherited src is not
# branding-allowed (fail-closed governance).
set -eu
grep -qi "mass class renames" BRANDING_POLICY.md || { echo "FAIL: branding policy weakened" >&2; exit 1; }
grep -qi "no_mass_rename" UPSTREAM.lock.yaml || { echo "FAIL: lock policy weakened" >&2; exit 1; }
echo "failure no-mass-rename-enforced: ok"

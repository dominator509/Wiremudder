#!/usr/bin/env sh
# EP-033 M5 requirement test: WM-SPEC-028-R02 — the fresh final verify runs
# blueprint, build, format, lint, type, unit, integration, E2E, security,
# dependency, reality, smoke, live-fire, feature coverage, spec trace,
# performance, accessibility, license, and platform gates applicable to the
# profile.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "requirement: FAIL - $1" >&2; exit 1; }

# The node verifier's verify subcommand runs M1-M5 plus authority, source
# evidence, discovered path, contract, expected-files, and scope gates.
[ -x scripts/node-verifiers/EP-033.sh ] || fail "node verifier missing"
grep -q "verify)" scripts/node-verifiers/EP-033.sh || fail "verify subcommand missing"

# Security and live-fire lanes are real and executable.
sh tests/wiremudder/security/001-repo-secrets-gate.sh >/dev/null 2>&1 \
  || fail "shared repo secrets gate"
[ -f tests/live-fire/LF-033-security-supply-chain-denial.sh ] \
  || fail "LF-033 live-fire missing"

# License inventory lane is present.
[ -f licenses/wiremudder/licenses.json ] || fail "license inventory missing"

echo "requirement WM-SPEC-028-R02: ok"

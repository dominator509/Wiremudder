#!/usr/bin/env sh
# EP-036 M2 unit test: the platform certification and chaos suites run
# against the real repository and pass on this host.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

# Platform certification (Linux host).
sh tests/wiremudder/platform/linux-certification.sh >/dev/null 2>&1 \
  || { sh tests/wiremudder/platform/linux-certification.sh; fail "platform certification failed"; }

# Chaos fault injection.
sh tests/wiremudder/chaos/fault-injection.sh >/dev/null 2>&1 \
  || { sh tests/wiremudder/chaos/fault-injection.sh; fail "chaos suite failed"; }

echo "unit EP-036 platform-and-chaos: ok"

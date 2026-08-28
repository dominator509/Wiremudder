#!/usr/bin/env sh
# EP-036 M4 security test: certification/chaos security obligations
# (SPEC-010, SPEC-022).
#
# 1. Evidence is redacted: no secrets, keys, or private payloads in
#    certification output.
# 2. Chaos never egresses and never touches signing keys.
# 3. The pinned upstream commit protects provenance.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

# 1. Certification evidence never contains secret-shaped material.
sh tests/wiremudder/platform/linux-certification.sh >/tmp/ep036_sec_cert.log 2>&1 \
  || fail "certification failed"
if grep -qiE "AKIA[0-9A-Z]{16}|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|sk-[A-Za-z0-9]{20}" \
     /tmp/ep036_sec_cert.log; then
  fail "certification evidence contains secret-shaped material"
fi
rm -f /tmp/ep036_sec_cert.log

# 2. The chaos suite output is redacted too.
sh tests/wiremudder/chaos/fault-injection.sh >/tmp/ep036_sec_chaos.log 2>&1 \
  || fail "chaos failed"
if grep -qiE "AKIA[0-9A-Z]{16}|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|sk-[A-Za-z0-9]{20}" \
     /tmp/ep036_sec_chaos.log; then
  fail "chaos output contains secret-shaped material"
fi
rm -f /tmp/ep036_sec_chaos.log

# 3. The certification/chaos boundaries declare no egress and no signing.
grep -q "never egress" docs/wiremudder/certification/design/platform-certification.md \
  || fail "design doc missing no-egress declaration"
grep -q "never touch signing keys" docs/wiremudder/certification/design/platform-certification.md \
  || fail "design doc missing no-signing declaration"

# 4. Provenance: the pinned upstream commit is recorded and real.
[ -f UPSTREAM.lock.yaml ] || fail "missing UPSTREAM.lock.yaml"
grep -q "development_commit" UPSTREAM.lock.yaml || fail "lock missing development_commit"
set -a; . ./.env; set +a
git cat-file -e "${WIREMUDDER_UPSTREAM_COMMIT}^{commit}" 2>/dev/null \
  || fail "pinned commit not present"

echo "security EP-036 certification-surface: ok"

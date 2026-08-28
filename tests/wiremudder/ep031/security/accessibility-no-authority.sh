#!/usr/bin/env sh
# EP-031 M4 security test: the accessibility boundary must not introduce
# any authority, secret access, remote egress, routing control, signing
# capability, or package permission (node contract Security and Privacy
# section). Untrusted server-provided text cannot create trusted UI
# controls or render unescaped HTML in privileged surfaces
# (WM-SPEC-007-R06); the boundary only reflects profile booleans.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

# The boundary header must declare the fail-closed passive invariants.
hdr=src/wiremudder/accessibility/accessibility_boundary.h
[ -f "$hdr" ] || fail "missing accessibility boundary header"

grep -q "bool isPassive() const { return true; }" "$hdr" || fail "boundary is not passive"
grep -q "bool canSendCommand() const { return false; }" "$hdr" || fail "boundary has a command path"
grep -q "bool canChangeSettings() const { return false; }" "$hdr" || fail "boundary can change settings"
grep -q "bool canAccessSecrets() const { return false; }" "$hdr" || fail "boundary can access secrets"
grep -q "bool canEgress() const { return false; }" "$hdr" || fail "boundary has an egress path"
grep -q "bool canDisableRawText() const { return false; }" "$hdr" || fail "boundary can disable raw text"

# The boundary must not reach network, secrets, or process execution.
for pat in "QNetworkAccessManager" "QProcess" "QHttp" "QSslSocket" "setenv" "system(" "popen" "fopen(" "/proc/" "getenv"; do
  if grep -q "$pat" src/wiremudder/accessibility/*.cpp src/wiremudder/accessibility/*.h; then
    fail "boundary references forbidden capability $pat"
  fi
done

# The boundary must not render or parse untrusted markup.
for pat in "QTextDocument" "setHtml" "QWebEngine" "QUrl("; do
  if grep -q "$pat" src/wiremudder/accessibility/*.cpp src/wiremudder/accessibility/*.h; then
    fail "boundary references untrusted-markup renderer $pat"
  fi
done

# Logs and evidence are redacted; the boundary holds no secrets to leak.
if grep -q "secret\|password\|token\|api_key" src/wiremudder/accessibility/*.cpp src/wiremudder/accessibility/*.h; then
  fail "boundary references secret-like identifiers"
fi

# The translation catalog must not contain markup or scriptable content.
if grep -q "<script\|onload\|javascript:" translations/wiremudder/wiremudder.ts; then
  fail "translation catalog contains scriptable content"
fi

echo "security EP-031 accessibility-no-authority: ok"

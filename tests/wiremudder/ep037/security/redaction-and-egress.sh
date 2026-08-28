#!/usr/bin/env sh
# EP-037 M4 security test: documentation and examples owned by this node
# never leak secrets, credentials, signing keys, or private data. Logs and
# evidence are redacted (SPEC-010, SPEC-022). The scan covers only the
# boundaries EP-037 owns — inherited docs from other nodes are outside
# this node's scope.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

# EP-037-owned documentation surface.
own_docs="docs/wiremudder/user docs/wiremudder/developer \
docs/wiremudder/package-author docs/wiremudder/design/documentation-system.md \
docs/wiremudder/operations/runbook.md"

# 1. No private key material or credential-prefix patterns in owned docs.
for pat in "BEGIN.*PRIVATE KEY" "BEGIN.*RSA PRIVATE" "sk-" "xoxb-" "ghp_"; do
  if grep -rl "$pat" $own_docs 2>/dev/null; then
    fail "secret-looking material found in owned docs ($pat)"
  fi
done

# 2. No bearer tokens / passwords with values in owned docs.
if grep -rlE "password\s*[:=]\s*[A-Za-z0-9]{8,}" $own_docs 2>/dev/null; then
  fail "password value found in owned docs"
fi

# 3. The example manifest is not a real secret-bearing artifact.
if grep -q "token\|api_key\|secret" examples/wiremudder/manifest.example.json; then
  fail "example manifest contains secret field"
fi

# 4. Redaction discipline: the package-author guide must not instruct
#    authors to embed secrets in packages.
if grep -qi "store.*api key.*in.*manifest" docs/wiremudder/package-author/README.md; then
  fail "package-author guide instructs embedding secrets"
fi

# 5. No egress claims: owned docs must not claim the client uploads data by
#    default.
if grep -rqi "uploads.*by default\|sends.*by default" docs/wiremudder/user/ 2>/dev/null; then
  fail "owned docs claim default data egress"
fi

echo "security EP-037 redaction-and-egress: ok"

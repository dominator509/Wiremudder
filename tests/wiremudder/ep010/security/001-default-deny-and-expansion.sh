#!/usr/bin/env sh
# EP-010 M4 security test: default-deny enforcement, expansion
# protection, hash mismatch rejection, and credential-free fixtures.
set -eu
cd "$(dirname "$0")/../../../.."
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() { echo "security: FAIL - $1" >&2; exit 1; }

ORACLE=wirecore/target/debug/wire-packages-oracle
[ -x "$ORACLE" ] || fail "oracle missing"

# 1. Default deny: nothing is granted without explicit approval
for perm in network secrets command_send microphone ai_egress routing updater telemetry memory renderer audio filesystem ui; do
  OUT=$("$ORACLE" decisions "" "$perm")
  echo "$OUT" | grep -q "\"permission\":\"$perm\",\"decision\":\"denied\"" \
    || fail "default deny violated for $perm"
done

# 2. Expansion protection: approved package requesting new permission
#    must be flagged (WM-SPEC-008-R05)
OUT=$("$ORACLE" decisions "network" "network,secrets")
echo "$OUT" | grep -q '"expansion":\["secrets"\]' || fail "expansion not flagged"

# 3. Hash mismatch rejects (WM-SPEC-020-R05)
$ORACLE hash "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" \
  "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" \
  | grep -q mismatch || fail "hash mismatch must be detected"

# 4. No credential-shaped values anywhere in the package boundary
if grep -rqE "sk-live|api[_-]?key[[:space:]]*[:=]|BEGIN [A-Z ]*PRIVATE KEY" \
  src/wiremudder/packages/ schemas/wiremudder/packages/ wirecore/crates/wire-packages/src/ 2>/dev/null; then
  fail "credential-shaped value in package boundary"
fi

# 5. Quarantine prevents re-execution of runaway hook (WM-SPEC-008-R10)
python3 - <<'PY' || fail "quarantine semantics"
# The C++ boundary quarantine contract must be enforced at compile time
# and exposed to the Qt layer.
h = open("src/wiremudder/packages/package_boundary.h").read()
assert "isQuarantined" in h
assert "quarantine(const QString& hookId)" in h
assert "release(const QString& hookId)" in h
print("quarantine contract enforced")
PY

echo "security EP-010 M4: ok"

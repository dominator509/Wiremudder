#!/usr/bin/env sh
# LF-010 package-script-sandbox (live-fire)
#
# Proves the real user outcome of EP-010: a malicious package is refused
# at every layer (hash, permissions, import gate, quarantine), permission
# expansion requires renewed approval, and the manual gameplay path is
# never gated. Real controlled dependencies only.
set -eu
fail() { echo "LF-010: FAIL - $1" >&2; exit 1; }

cd "$(dirname "$0")/../.."
CARGO=/root/.cargo/bin/cargo
QT=/opt/qt/6.8.2/gcc_64
ORACLE=wirecore/target/debug/wire-packages-oracle

echo "LF-010: package-script-sandbox"
echo "observed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

[ -x "$ORACLE" ] || fail "oracle not built"

# 1. Real Rust core: full test suite for wire-packages.
CARGO_TARGET_DIR="$PWD/wirecore/target" "$CARGO" test \
  --manifest-path wirecore/crates/wire-packages/Cargo.toml >/tmp/wm-lf010-p.log 2>&1 \
  || fail "wire-packages tests"

# 2. Real C++ boundary: compile + invariants.
sh tests/wiremudder/ep010/unit/002-package-boundary-cpp.sh >/dev/null 2>&1 \
  || fail "C++ boundary invariants"

# 3. Malicious package fully denied (network + secrets + command_send).
OUT=$("$ORACLE" decisions "" "network,secrets,command_send")
echo "$OUT" | grep -q '"network","decision":"denied"' || fail "network not denied"
echo "$OUT" | grep -q '"secrets","decision":"denied"' || fail "secrets not denied"
echo "$OUT" | grep -q '"command_send","decision":"denied"' || fail "command_send not denied"

# 4. Permission expansion requires renewed approval.
OUT=$("$ORACLE" decisions "ui" "ui,network")
echo "$OUT" | grep -q '"expansion":\["network"\]' || fail "expansion not flagged"

# 5. Hash mismatch rejects package content (WM-SPEC-020-R05).
$ORACLE hash "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" \
  "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" \
  | grep -q mismatch || fail "hash mismatch not detected"

# 6. Import gate + quarantine via cross-implementation e2e.
sh tests/wiremudder/ep010/e2e/001-sandbox-flow.sh >/dev/null 2>&1 \
  || fail "sandbox flow"

# 7. Manual gameplay preserved: package layer declares no hook into the
#    manual input or socket send path.
grep -q "commandSubmitted" src/wiremudder/packages/package_boundary.h \
  && fail "package layer hooks manual input"
grep -q "sendData" src/wiremudder/packages/package_boundary.h \
  && fail "package layer hooks socket send"

# 8. Feature coverage and spec trace gates.
sh scripts/feature-coverage-check.sh >/dev/null 2>&1 || fail "feature coverage"
sh scripts/spec-trace-check.sh >/dev/null 2>&1 || fail "spec trace"

echo "LF-010: ok"

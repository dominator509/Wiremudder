#!/usr/bin/env sh
# Node verifier for EP-001 Graphlock Overlay and Inherited Baseline.
# Each subcommand runs real checks against the repository and prints its
# exact sentinel only on success. Never edits production code.
set -eu

NODE=EP-001
fail() { echo "node verifier $NODE: FAIL - $1" >&2; exit 1; }
ok() { echo "$1"; exit 0; }

# --- shared helpers -------------------------------------------------------
require_env() {
  [ -f .env ] || fail "missing .env"
  set -a; . ./.env; set +a
}
check_pinned_commit() {
  require_env
  commit=${WIREMUDDER_UPSTREAM_COMMIT:-}
  [ -n "$commit" ] || fail "WIREMUDDER_UPSTREAM_COMMIT empty"
  git cat-file -e "$commit^{commit}" 2>/dev/null || fail "pinned commit $commit missing"
  git merge-base --is-ancestor "$commit" HEAD || fail "pinned commit not ancestor of HEAD"
}
check_graphlock_parity() {
  # All Graphlock adapters must carry the identical prime block.
  for f in AGENTS.md CLAUDE.md .github/copilot-instructions.md; do
    [ -f "$f" ] || fail "missing adapter $f"
    grep -q "PRIME-BLOCK-BEGIN" "$f" || fail "missing prime block in $f"
  done
  # Byte-identical prime blocks: extract the block from AGENTS.md and diff.
  awk '/^PRIME-BLOCK-BEGIN$/{p=1} p{print} /^PRIME-BLOCK-END$/{if(p) exit}' AGENTS.md > /tmp/wm-prime-agents.$$
  for f in CLAUDE.md .github/copilot-instructions.md; do
    awk '/^PRIME-BLOCK-BEGIN$/{p=1} p{print} /^PRIME-BLOCK-END$/{if(p) exit}' "$f" > /tmp/wm-prime-other.$$
    diff -q /tmp/wm-prime-agents.$$ /tmp/wm-prime-other.$$ >/dev/null || fail "prime block mismatch in $f"
  done
  rm -f /tmp/wm-prime-agents.$$ /tmp/wm-prime-other.$$
}

case "${1:-}" in
  M1)
    # Evidence, contracts, and exact path lock.
    check_pinned_commit
    check_graphlock_parity
    [ -f .agent/node-contracts/EP-001.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-001.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-001.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-001-$m.txt" ] || fail "missing milestone fence $m"
    done
    n=$(wc -l < .agent/state/source-evidence.jsonl | tr -d ' ')
    [ "$n" -ge 28 ] || fail "insufficient source evidence ($n records)"
    grep -q 'WM-FEAT-0146' .agent/node-contracts/EP-001.md || fail "feature WM-FEAT-0146 missing from contract"
    grep -q 'WM-FEAT-0154' .agent/node-contracts/EP-001.md || fail "feature WM-FEAT-0154 missing from contract"
    grep -q 'WM-SPEC-005-R01' .agent/node-contracts/EP-001.md || fail "requirement 005-R01 missing from contract"
    grep -q 'WM-SPEC-002-R01' .agent/node-contracts/EP-001.md || fail "requirement 002-R01 missing from contract"
    [ -d tests/wiremudder/ep001/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep001/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-001 >/dev/null || fail "scope audit"
    ok "EP-001 M1: ok"
    ;;
  M2)
    # Core behavior: baseline inventory and unit tests.
    check_pinned_commit
    check_graphlock_parity
    [ -d .agent/state/baseline ] || fail "missing baseline state"
    [ -d docs/wiremudder/baseline ] || fail "missing baseline docs"
    [ -d tests/wiremudder/baseline ] || fail "missing baseline tests"
    [ -d tests/wiremudder/ep001/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep001/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-001 M2: ok"
    ;;
  M3)
    # Real integration: inherited client configures, builds, and tests.
    check_pinned_commit
    check_graphlock_parity
    require_env
    preset=${WIREMUDDER_CMAKE_PRESET:-}
    [ -n "$preset" ] || fail "preset unset"
    cmake --list-presets 2>/dev/null | grep -Fq "\"$preset\"" || fail "preset $preset not offered"
    builddir="build-$preset"
    [ -f "$builddir/CMakeCache.txt" ] || fail "no configure cache at $builddir"
    [ -d "$builddir" ] || fail "missing build directory"
    # The inherited client binary must exist for the desktop shell.
    bin="$builddir/src/mudlet"
    [ -x "$bin" ] || fail "missing inherited client binary $bin"
    [ -d tests/wiremudder/ep001/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep001/e2e ] || fail "missing e2e tests"
    for t in tests/wiremudder/ep001/integration/*.sh tests/wiremudder/ep001/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-001 M3: ok"
    ;;
  M4)
    # Forced failures, abuse cases, performance, operations.
    [ -d tests/wiremudder/ep001/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep001/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep001/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/baseline/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep001/failure/*.sh tests/wiremudder/ep001/security/*.sh tests/wiremudder/ep001/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-001 M4: ok"
    ;;
  M5)
    # Live-fire, evidence closure, green tag readiness.
    check_pinned_commit
    check_graphlock_parity
    [ -f tests/live-fire/LF-001-unchanged-inherited-baseline.sh ] || fail "missing LF-001"
    sh tests/live-fire/LF-001-unchanged-inherited-baseline.sh || fail "LF-001 failed"
    [ -d docs/wiremudder/baseline ] || fail "missing baseline docs"
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-001 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-001 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-001 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-001 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-001 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-001" >/dev/null || fail "green/EP-001 tag missing"
    ok "EP-001 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

#!/usr/bin/env sh
# EP-039 Production Readiness, Ship, and Run Complete - node verifier.
# Each subcommand runs real checks and prints only its exact sentinel.
set -eu

cd "$(dirname "$0")/../.."

fail() { echo "EP-039 verify: FAIL - $1" >&2; exit 1; }
ok() { echo "$1"; exit 0; }

check_pinned_commit() {
  [ -f .env ] || fail "missing .env"
  set -a; . ./.env; set +a
  commit=${WIREMUDDER_UPSTREAM_COMMIT:-}
  git cat-file -e "$commit^{commit}" 2>/dev/null || fail "pinned commit missing"
  git merge-base --is-ancestor "$commit" HEAD || fail "pinned commit not ancestor"
}

case "${1:-}" in
  M1)
    check_pinned_commit
    [ -f .agent/node-contracts/EP-039.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-039.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-039.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-039-$m.txt" ] || fail "missing milestone fence $m"
    done
    for b in release/wiremudder/final/ .agent/state/final-evidence/ docs/wiremudder/ship/; do
      grep -q "$b" .agent/node-contracts/EP-039.md || fail "authorized boundary $b missing from contract"
    done
    for r in WM-SPEC-028-R06; do
      grep -q "$r" .agent/node-contracts/EP-039.md || fail "owned requirement $r missing from contract"
    done
    [ -d tests/wiremudder/ep039/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep039/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    # The 12 EP-039 ship-gate commands must be locked and evidenced.
    python3 scripts/command_lock_check.py >/dev/null || fail "command lock check"
    sh scripts/scope-audit.sh EP-039 >/dev/null || fail "scope audit"
    ok "EP-039 M1: ok"
    ;;
  M2)
    check_pinned_commit
    for d in release/wiremudder/final .agent/state/final-evidence docs/wiremudder/ship; do
      [ -d "$d" ] || fail "missing boundary $d"
      [ -n "$(find "$d" -type f | head -n 1)" ] || fail "empty boundary $d"
    done
    for t in tests/wiremudder/ep039/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-039 M2: ok"
    ;;
  M3)
    check_pinned_commit
    for t in tests/wiremudder/ep039/integration/*.sh tests/wiremudder/ep039/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    [ -d docs/wiremudder/ship/design ] || fail "missing design docs"
    [ -n "$(find docs/wiremudder/ship/design -type f | head -n 1)" ] || fail "empty design docs"
    ok "EP-039 M3: ok"
    ;;
  M4)
    check_pinned_commit
    for d in tests/wiremudder/ep039/failure tests/wiremudder/ep039/security \
             tests/wiremudder/ep039/performance; do
      [ -d "$d" ] || fail "missing $d"
      for t in "$d"/*.sh; do
        [ -f "$t" ] || fail "no tests in $d"
        sh "$t" || fail "test failed: $t"
      done
    done
    [ -d docs/wiremudder/ship/operations ] || fail "missing operations runbook"
    [ -n "$(find docs/wiremudder/ship/operations -type f | head -n 1)" ] || fail "empty operations runbook"
    ok "EP-039 M4: ok"
    ;;
  M5)
    check_pinned_commit
    [ -f tests/live-fire/LF-039-ship-gate.sh ] \
      || fail "missing LF-039 live-fire script"
    sh tests/live-fire/LF-039-ship-gate.sh || fail "LF-039 failed"
    for r in WM-SPEC-028-R06; do
      p=$(awk -F'\t' -v r="$r" '$1==r {print $6; exit}' .agent/requirements/VALIDATION_MATRIX.tsv)
      [ -n "$p" ] || fail "no test path for $r"
      for t in "$p"/*.sh; do
        [ -f "$t" ] || fail "no requirement tests in $p"
        sh "$t" || fail "requirement test failed: $t"
      done
    done
    sh scripts/expected-files-audit.sh EP-039 >/dev/null || fail "expected-files audit"
    sh scripts/scope-audit.sh EP-039 >/dev/null || fail "scope audit"
    ok "EP-039 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-039 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-039 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-039 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-039 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-039" >/dev/null || fail "green/EP-039 tag missing"
    ok "EP-039 verify: ok"
    ;;
  *)
    fail "unknown subcommand ${1:-<none>}"
    ;;
esac

#!/usr/bin/env sh
# EP-037 Documentation, Package Developer, and Community Ecosystem -
# node verifier. Each subcommand runs real checks and prints only its exact
# sentinel.
set -eu

cd "$(dirname "$0")/../.."

fail() { echo "EP-037 verify: FAIL - $1" >&2; exit 1; }
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
    [ -f .agent/node-contracts/EP-037.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-037.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-037.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-037-$m.txt" ] || fail "missing milestone fence $m"
    done
    for b in docs/wiremudder/user/ docs/wiremudder/developer/ \
             docs/wiremudder/package-author/ examples/wiremudder/; do
      grep -q "$b" .agent/node-contracts/EP-037.md || fail "authorized boundary $b missing from contract"
    done
    for f in WM-FEAT-0164 WM-FEAT-0243; do
      grep -q "$f" .agent/node-contracts/EP-037.md || fail "owned feature $f missing from contract"
    done
    [ -d tests/wiremudder/ep037/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep037/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-037 >/dev/null || fail "scope audit"
    ok "EP-037 M1: ok"
    ;;
  M2)
    check_pinned_commit
    for d in docs/wiremudder/user docs/wiremudder/developer \
             docs/wiremudder/package-author examples/wiremudder; do
      [ -d "$d" ] || fail "missing boundary $d"
      [ -n "$(find "$d" -type f | head -n 1)" ] || fail "empty boundary $d"
    done
    for t in tests/wiremudder/ep037/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-037 M2: ok"
    ;;
  M3)
    check_pinned_commit
    for t in tests/wiremudder/ep037/integration/*.sh tests/wiremudder/ep037/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    [ -d docs/wiremudder/design ] || fail "missing design docs boundary"
    [ -n "$(find docs/wiremudder/design -type f | head -n 1)" ] || fail "empty design docs"
    ok "EP-037 M3: ok"
    ;;
  M4)
    check_pinned_commit
    for d in tests/wiremudder/ep037/failure tests/wiremudder/ep037/security \
             tests/wiremudder/ep037/performance; do
      [ -d "$d" ] || fail "missing $d"
      for t in "$d"/*.sh; do
        [ -f "$t" ] || fail "no tests in $d"
        sh "$t" || fail "test failed: $t"
      done
    done
    [ -d docs/wiremudder/operations ] || fail "missing operations runbook boundary"
    [ -n "$(find docs/wiremudder/operations -type f | head -n 1)" ] || fail "empty operations runbook"
    ok "EP-037 M4: ok"
    ;;
  M5)
    check_pinned_commit
    [ -f tests/live-fire/LF-037-package-developer-workflow.sh ] \
      || fail "missing LF-037 live-fire script"
    sh tests/live-fire/LF-037-package-developer-workflow.sh || fail "LF-037 failed"
    for d in tests/wiremudder/ep037/feature-0164 tests/wiremudder/ep037/feature-0243; do
      [ -d "$d" ] || fail "missing feature test dir $d"
      for t in "$d"/*.sh; do
        [ -f "$t" ] || fail "no feature test in $d"
        sh "$t" || fail "feature test failed: $t"
      done
    done
    sh scripts/expected-files-audit.sh EP-037 >/dev/null || fail "expected-files audit"
    sh scripts/scope-audit.sh EP-037 >/dev/null || fail "scope audit"
    ok "EP-037 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-037 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-037 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-037 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-037 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-037" >/dev/null || fail "green/EP-037 tag missing"
    ok "EP-037 verify: ok"
    ;;
  *)
    fail "unknown subcommand ${1:-<none>}"
    ;;
esac

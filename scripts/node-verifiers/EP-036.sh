#!/usr/bin/env sh
# EP-036 Platform Certification, Chaos, and Upstream Sync Regression -
# node verifier. Each subcommand runs real checks and prints only its exact
# sentinel.
set -eu

cd "$(dirname "$0")/../.."

fail() { echo "EP-036 verify: FAIL - $1" >&2; exit 1; }
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
    [ -f .agent/node-contracts/EP-036.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-036.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-036.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-036-$m.txt" ] || fail "missing milestone fence $m"
    done
    for b in tests/wiremudder/platform/ tests/wiremudder/chaos/ \
             compatibility/platform/ docs/wiremudder/certification/; do
      grep -q "$b" .agent/node-contracts/EP-036.md || fail "authorized boundary $b missing from contract"
    done
    for r in WM-SPEC-019-R02 WM-SPEC-027-R08; do
      grep -q "$r" .agent/node-contracts/EP-036.md || fail "owned requirement $r missing from contract"
    done
    [ -d tests/wiremudder/ep036/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep036/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-036 >/dev/null || fail "scope audit"
    ok "EP-036 M1: ok"
    ;;
  M2)
    check_pinned_commit
    [ -d tests/wiremudder/platform ] || fail "missing platform boundary"
    [ -d tests/wiremudder/chaos ] || fail "missing chaos boundary"
    [ -d compatibility/platform ] || fail "missing compatibility boundary"
    [ -d docs/wiremudder/certification ] || fail "missing certification docs boundary"
    for t in tests/wiremudder/ep036/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-036 M2: ok"
    ;;
  M3)
    check_pinned_commit
    for t in tests/wiremudder/ep036/integration/*.sh tests/wiremudder/ep036/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    [ -f docs/wiremudder/certification/design/platform-certification.md ] || fail "missing design doc"
    ok "EP-036 M3: ok"
    ;;
  M4)
    check_pinned_commit
    [ -d tests/wiremudder/ep036/failure ] || fail "missing failure tests"
    for t in tests/wiremudder/ep036/failure/*.sh; do
      [ -f "$t" ] || fail "no failure tests found"
      sh "$t" || fail "failure test failed: $t"
    done
    [ -d tests/wiremudder/ep036/security ] || fail "missing security tests"
    for t in tests/wiremudder/ep036/security/*.sh; do
      [ -f "$t" ] || fail "no security tests found"
      sh "$t" || fail "security test failed: $t"
    done
    [ -d tests/wiremudder/ep036/performance ] || fail "missing performance tests"
    for t in tests/wiremudder/ep036/performance/*.sh; do
      [ -f "$t" ] || fail "no performance tests found"
      sh "$t" || fail "performance test failed: $t"
    done
    [ -f docs/wiremudder/certification/operations/runbook.md ] || fail "missing operations runbook"
    ok "EP-036 M4: ok"
    ;;
  M5)
    check_pinned_commit
    [ -f tests/live-fire/LF-036-platform-chaos-matrix.sh ] \
      || fail "missing LF-036 live-fire script"
    sh tests/live-fire/LF-036-platform-chaos-matrix.sh || fail "LF-036 failed"
    [ -d tests/wiremudder/ep036/requirements ] || fail "missing requirement tests"
    for r in WM-SPEC-019-R02 WM-SPEC-027-R08; do
      p=$(awk -F'\t' -v r="$r" '$1==r {print $6; exit}' .agent/requirements/VALIDATION_MATRIX.tsv)
      [ -n "$p" ] || fail "no test path for $r"
      for t in "$p"/*.sh; do
        [ -f "$t" ] || fail "no requirement tests in $p"
        sh "$t" || fail "requirement test failed: $t"
      done
    done
    sh scripts/expected-files-audit.sh EP-036 >/dev/null || fail "expected-files audit"
    sh scripts/scope-audit.sh EP-036 >/dev/null || fail "scope audit"
    ok "EP-036 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-036 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-036 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-036 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-036 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-036" >/dev/null || fail "green/EP-036 tag missing"
    ok "EP-036 verify: ok"
    ;;
  *)
    fail "unknown subcommand ${1:-<none>}"
    ;;
esac

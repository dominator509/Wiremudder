#!/usr/bin/env sh
# EP-033 Security, Threat Model, License, SBOM, and Supply Chain - node verifier.
# Each subcommand runs real checks and prints only its exact sentinel.
set -eu

cd "$(dirname "$0")/../.."

fail() { echo "EP-033 verify: FAIL - $1" >&2; exit 1; }
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
    [ -f .agent/node-contracts/EP-033.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-033.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-033.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-033-$m.txt" ] || fail "missing milestone fence $m"
    done
    for b in docs/wiremudder/security/ security/wiremudder/ sbom/wiremudder/ \
             licenses/wiremudder/ tests/wiremudder/security/; do
      grep -q "$b" .agent/node-contracts/EP-033.md || fail "authorized boundary $b missing from contract"
    done
    for r in WM-SPEC-001-R03 WM-SPEC-001-R08 WM-SPEC-020-R02 WM-SPEC-020-R03 \
             WM-SPEC-020-R08 WM-SPEC-022-R06 WM-SPEC-022-R08 WM-SPEC-022-R09 \
             WM-SPEC-028-R02 WM-SPEC-028-R03; do
      grep -q "$r" .agent/node-contracts/EP-033.md || fail "owned requirement $r missing from contract"
    done
    [ -d tests/wiremudder/ep033/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep033/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-033 >/dev/null || fail "scope audit"
    ok "EP-033 M1: ok"
    ;;
  M2)
    check_pinned_commit
    [ -d security/wiremudder ] || fail "missing security boundary"
    [ -d sbom/wiremudder ] || fail "missing sbom boundary"
    [ -d licenses/wiremudder ] || fail "missing licenses boundary"
    [ -d tests/wiremudder/security ] || fail "missing security tests boundary"
    for t in tests/wiremudder/ep033/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-033 M2: ok"
    ;;
  M3)
    check_pinned_commit
    for t in tests/wiremudder/ep033/integration/*.sh tests/wiremudder/ep033/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    [ -f docs/wiremudder/security/design/threat-model.md ] || fail "missing threat model design doc"
    ok "EP-033 M3: ok"
    ;;
  M4)
    check_pinned_commit
    [ -d tests/wiremudder/ep033/failure ] || fail "missing failure tests"
    for t in tests/wiremudder/ep033/failure/*.sh; do
      [ -f "$t" ] || fail "no failure tests found"
      sh "$t" || fail "failure test failed: $t"
    done
    [ -d tests/wiremudder/ep033/security ] || fail "missing security tests"
    for t in tests/wiremudder/ep033/security/*.sh; do
      [ -f "$t" ] || fail "no security tests found"
      sh "$t" || fail "security test failed: $t"
    done
    [ -d tests/wiremudder/ep033/performance ] || fail "missing performance tests"
    for t in tests/wiremudder/ep033/performance/*.sh; do
      [ -f "$t" ] || fail "no performance tests found"
      sh "$t" || fail "performance test failed: $t"
    done
    [ -f docs/wiremudder/security/operations/runbook.md ] || fail "missing operations runbook"
    ok "EP-033 M4: ok"
    ;;
  M5)
    check_pinned_commit
    [ -f tests/live-fire/LF-033-security-supply-chain-denial.sh ] \
      || fail "missing LF-033 live-fire script"
    sh tests/live-fire/LF-033-security-supply-chain-denial.sh || fail "LF-033 failed"
    [ -d tests/wiremudder/ep033/requirements ] || fail "missing requirement tests"
    for r in WM-SPEC-001-R03 WM-SPEC-001-R08 WM-SPEC-020-R02 WM-SPEC-020-R03 \
             WM-SPEC-020-R08 WM-SPEC-022-R06 WM-SPEC-022-R08 WM-SPEC-022-R09 \
             WM-SPEC-028-R02 WM-SPEC-028-R03; do
      p=$(grep -m1 "^$r\t" .agent/requirements/VALIDATION_MATRIX.tsv | awk -F'\t' '{print $6}')
      [ -n "$p" ] || fail "no test path for $r"
      for t in "$p"/*.sh; do
        [ -f "$t" ] || fail "no requirement tests in $p"
        sh "$t" || fail "requirement test failed: $t"
      done
    done
    sh scripts/expected-files-audit.sh EP-033 >/dev/null || fail "expected-files audit"
    sh scripts/scope-audit.sh EP-033 >/dev/null || fail "scope audit"
    ok "EP-033 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-033 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-033 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-033 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-033 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-033" >/dev/null || fail "green/EP-033 tag missing"
    ok "EP-033 verify: ok"
    ;;
  *)
    fail "unknown subcommand ${1:-<none>}"
    ;;
esac

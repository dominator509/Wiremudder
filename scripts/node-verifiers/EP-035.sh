#!/usr/bin/env sh
# EP-035 Installers, CI, Release Channels, and Artifacts - node verifier.
# Each subcommand runs real checks and prints only its exact sentinel.
set -eu

cd "$(dirname "$0")/../.."

fail() { echo "EP-035 verify: FAIL - $1" >&2; exit 1; }
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
    [ -f .agent/node-contracts/EP-035.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-035.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-035.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-035-$m.txt" ] || fail "missing milestone fence $m"
    done
    for b in CI/wiremudder/ installers/wiremudder/ \
             packaging/wiremudder/ docs/wiremudder/release/; do
      grep -q "$b" .agent/node-contracts/EP-035.md || fail "authorized boundary $b missing from contract"
    done
    for r in WM-SPEC-020-R01 WM-SPEC-020-R09 WM-SPEC-026-R10 \
             WM-SPEC-028-R05 WM-SPEC-028-R07 WM-SPEC-028-R09 WM-SPEC-028-R10; do
      grep -q "$r" .agent/node-contracts/EP-035.md || fail "owned requirement $r missing from contract"
    done
    [ -d tests/wiremudder/ep035/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep035/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-035 >/dev/null || fail "scope audit"
    ok "EP-035 M1: ok"
    ;;
  M2)
    check_pinned_commit
    [ -d CI/wiremudder ] || fail "missing CI boundary"
    [ -d installers/wiremudder ] || fail "missing installers boundary"
    [ -d packaging/wiremudder ] || fail "missing packaging boundary"
    [ -d docs/wiremudder/release ] || fail "missing release docs boundary"
    for t in tests/wiremudder/ep035/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-035 M2: ok"
    ;;
  M3)
    check_pinned_commit
    for t in tests/wiremudder/ep035/integration/*.sh tests/wiremudder/ep035/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    [ -f docs/wiremudder/release/design/release-channels-artifacts.md ] || fail "missing design doc"
    ok "EP-035 M3: ok"
    ;;
  M4)
    check_pinned_commit
    [ -d tests/wiremudder/ep035/failure ] || fail "missing failure tests"
    for t in tests/wiremudder/ep035/failure/*.sh; do
      [ -f "$t" ] || fail "no failure tests found"
      sh "$t" || fail "failure test failed: $t"
    done
    [ -d tests/wiremudder/ep035/security ] || fail "missing security tests"
    for t in tests/wiremudder/ep035/security/*.sh; do
      [ -f "$t" ] || fail "no security tests found"
      sh "$t" || fail "security test failed: $t"
    done
    [ -d tests/wiremudder/ep035/performance ] || fail "missing performance tests"
    for t in tests/wiremudder/ep035/performance/*.sh; do
      [ -f "$t" ] || fail "no performance tests found"
      sh "$t" || fail "performance test failed: $t"
    done
    [ -f docs/wiremudder/release/operations/runbook.md ] || fail "missing operations runbook"
    ok "EP-035 M4: ok"
    ;;
  M5)
    check_pinned_commit
    [ -f tests/live-fire/LF-035-installer-release-channel.sh ] \
      || fail "missing LF-035 live-fire script"
    sh tests/live-fire/LF-035-installer-release-channel.sh || fail "LF-035 failed"
    [ -d tests/wiremudder/ep035/requirements ] || fail "missing requirement tests"
    for r in WM-SPEC-020-R01 WM-SPEC-020-R09 WM-SPEC-026-R10 \
             WM-SPEC-028-R05 WM-SPEC-028-R07 WM-SPEC-028-R09 WM-SPEC-028-R10; do
      p=$(awk -F'\t' -v r="$r" '$1==r {print $6; exit}' .agent/requirements/VALIDATION_MATRIX.tsv)
      [ -n "$p" ] || fail "no test path for $r"
      for t in "$p"/*.sh; do
        [ -f "$t" ] || fail "no requirement tests in $p"
        sh "$t" || fail "requirement test failed: $t"
      done
    done
    sh scripts/expected-files-audit.sh EP-035 >/dev/null || fail "expected-files audit"
    sh scripts/scope-audit.sh EP-035 >/dev/null || fail "scope audit"
    ok "EP-035 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-035 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-035 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-035 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-035 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-035" >/dev/null || fail "green/EP-035 tag missing"
    ok "EP-035 verify: ok"
    ;;
  *)
    fail "unknown subcommand ${1:-<none>}"
    ;;
esac

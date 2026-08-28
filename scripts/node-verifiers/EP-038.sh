#!/usr/bin/env sh
# EP-038 Full Release Candidate Hardening - node verifier. Each subcommand
# runs real checks and prints only its exact sentinel.
set -eu

cd "$(dirname "$0")/../.."

fail() { echo "EP-038 verify: FAIL - $1" >&2; exit 1; }
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
    [ -f .agent/node-contracts/EP-038.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-038.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-038.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-038-$m.txt" ] || fail "missing milestone fence $m"
    done
    for b in release/wiremudder/candidate/ .agent/state/release-evidence/ \
             docs/wiremudder/release-candidate/; do
      grep -q "$b" .agent/node-contracts/EP-038.md || fail "authorized boundary $b missing from contract"
    done
    for f in WM-FEAT-0244; do
      grep -q "$f" .agent/node-contracts/EP-038.md || fail "owned feature $f missing from contract"
    done
    for r in WM-SPEC-000-R01 WM-SPEC-000-R09 WM-SPEC-000-R10 WM-SPEC-028-R01; do
      grep -q "$r" .agent/node-contracts/EP-038.md || fail "owned requirement $r missing from contract"
    done
    [ -d tests/wiremudder/ep038/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep038/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-038 >/dev/null || fail "scope audit"
    ok "EP-038 M1: ok"
    ;;
  M2)
    check_pinned_commit
    for d in release/wiremudder/candidate .agent/state/release-evidence \
             docs/wiremudder/release-candidate; do
      [ -d "$d" ] || fail "missing boundary $d"
      [ -n "$(find "$d" -type f | head -n 1)" ] || fail "empty boundary $d"
    done
    for t in tests/wiremudder/ep038/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-038 M2: ok"
    ;;
  M3)
    check_pinned_commit
    for t in tests/wiremudder/ep038/integration/*.sh tests/wiremudder/ep038/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    [ -d docs/wiremudder/release-candidate/design ] || fail "missing design docs"
    [ -n "$(find docs/wiremudder/release-candidate/design -type f | head -n 1)" ] || fail "empty design docs"
    ok "EP-038 M3: ok"
    ;;
  M4)
    check_pinned_commit
    for d in tests/wiremudder/ep038/failure tests/wiremudder/ep038/security \
             tests/wiremudder/ep038/performance; do
      [ -d "$d" ] || fail "missing $d"
      for t in "$d"/*.sh; do
        [ -f "$t" ] || fail "no tests in $d"
        sh "$t" || fail "test failed: $t"
      done
    done
    [ -d docs/wiremudder/release-candidate/operations ] || fail "missing operations runbook"
    [ -n "$(find docs/wiremudder/release-candidate/operations -type f | head -n 1)" ] || fail "empty operations runbook"
    ok "EP-038 M4: ok"
    ;;
  M5)
    check_pinned_commit
    [ -f tests/live-fire/LF-038-release-candidate-full-suite.sh ] \
      || fail "missing LF-038 live-fire script"
    sh tests/live-fire/LF-038-release-candidate-full-suite.sh || fail "LF-038 failed"
    for d in tests/wiremudder/ep038/feature-0244; do
      [ -d "$d" ] || fail "missing feature test dir $d"
      for t in "$d"/*.sh; do
        [ -f "$t" ] || fail "no feature test in $d"
        sh "$t" || fail "feature test failed: $t"
      done
    done
    for r in WM-SPEC-000-R01 WM-SPEC-000-R09 WM-SPEC-000-R10 WM-SPEC-028-R01; do
      p=$(awk -F'\t' -v r="$r" '$1==r {print $6; exit}' .agent/requirements/VALIDATION_MATRIX.tsv)
      [ -n "$p" ] || fail "no test path for $r"
      for t in "$p"/*.sh; do
        [ -f "$t" ] || fail "no requirement tests in $p"
        sh "$t" || fail "requirement test failed: $t"
      done
    done
    sh scripts/expected-files-audit.sh EP-038 >/dev/null || fail "expected-files audit"
    sh scripts/scope-audit.sh EP-038 >/dev/null || fail "scope audit"
    ok "EP-038 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-038 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-038 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-038 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-038 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-038" >/dev/null || fail "green/EP-038 tag missing"
    ok "EP-038 verify: ok"
    ;;
  *)
    fail "unknown subcommand ${1:-<none>}"
    ;;
esac

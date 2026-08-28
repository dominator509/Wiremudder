#!/usr/bin/env sh
# EP-032 Performance, Benchmarks, Degradation, and Fairness - node verifier.
# Each subcommand runs real checks and prints only its exact sentinel.
set -eu

cd "$(dirname "$0")/../.."

fail() { echo "EP-032 verify: FAIL - $1" >&2; exit 1; }
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
    [ -f .agent/node-contracts/EP-032.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-032.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-032.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-032-$m.txt" ] || fail "missing milestone fence $m"
    done
    for b in benchmarks/wiremudder/ tests/wiremudder/performance/ \
             docs/wiremudder/performance/ tools/perf-capture/; do
      grep -q "$b" .agent/node-contracts/EP-032.md || fail "authorized boundary $b missing from contract"
    done
    for r in WM-SPEC-002-R07 WM-SPEC-002-R09 WM-SPEC-004-R12 WM-SPEC-019-R10 WM-SPEC-027-R06; do
      grep -q "$r" .agent/node-contracts/EP-032.md || fail "owned requirement $r missing from contract"
    done
    [ -d tests/wiremudder/ep032/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep032/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-032 >/dev/null || fail "scope audit"
    ok "EP-032 M1: ok"
    ;;
  M2)
    check_pinned_commit
    [ -d benchmarks/wiremudder ] || fail "missing benchmarks boundary"
    [ -d tests/wiremudder/performance ] || fail "missing performance tests boundary"
    [ -d tools/perf-capture ] || fail "missing perf-capture tool"
    for t in tests/wiremudder/ep032/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-032 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d benchmarks/wiremudder ] || fail "missing benchmarks boundary"
    for t in tests/wiremudder/ep032/integration/*.sh tests/wiremudder/ep032/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    [ -f docs/wiremudder/performance/design/benchmarks.md ] || fail "missing design doc"
    ok "EP-032 M3: ok"
    ;;
  M4)
    check_pinned_commit
    [ -d tests/wiremudder/ep032/failure ] || fail "missing failure tests"
    for t in tests/wiremudder/ep032/failure/*.sh; do
      [ -f "$t" ] || fail "no failure tests found"
      sh "$t" || fail "failure test failed: $t"
    done
    [ -d tests/wiremudder/ep032/security ] || fail "missing security tests"
    for t in tests/wiremudder/ep032/security/*.sh; do
      [ -f "$t" ] || fail "no security tests found"
      sh "$t" || fail "security test failed: $t"
    done
    [ -f docs/wiremudder/performance/operations/runbook.md ] || fail "missing operations runbook"
    ok "EP-032 M4: ok"
    ;;
  M5)
    check_pinned_commit
    [ -f tests/live-fire/LF-032-performance-priority-flood.sh ] \
      || fail "missing LF-032 live-fire script"
    sh tests/live-fire/LF-032-performance-priority-flood.sh || fail "LF-032 failed"
    # Owned features per FEATURES.tsv test_path column.
    for f in WM-FEAT-0131 WM-FEAT-0134 WM-FEAT-0135 WM-FEAT-0136 WM-FEAT-0137 \
             WM-FEAT-0138 WM-FEAT-0139 WM-FEAT-0140 WM-FEAT-0141 WM-FEAT-0142 \
             WM-FEAT-0143 WM-FEAT-0144 WM-FEAT-0145 WM-FEAT-0163; do
      idx=${f#WM-FEAT-}
      dir="tests/wiremudder/ep032/feature-$idx"
      [ -d "$dir" ] || fail "missing feature test dir $dir"
      for t in "$dir"/*.sh; do
        [ -f "$t" ] || fail "no feature tests in $dir"
        sh "$t" || fail "feature test failed: $t"
      done
    done
    # Owned requirements per VALIDATION_MATRIX test_path column.
    for r in WM-SPEC-002-R07 WM-SPEC-002-R09 WM-SPEC-004-R12 WM-SPEC-019-R10 WM-SPEC-027-R06; do
      p=$(grep -m1 "^$r	" .agent/requirements/VALIDATION_MATRIX.tsv | awk -F'\t' '{print $6}')
      [ -n "$p" ] || fail "no test path for $r"
      for t in "$p"/*.sh; do
        [ -f "$t" ] || fail "no requirement tests in $p"
        sh "$t" || fail "requirement test failed: $t"
      done
    done
    sh scripts/expected-files-audit.sh EP-032 >/dev/null || fail "expected-files audit"
    sh scripts/scope-audit.sh EP-032 >/dev/null || fail "scope audit"
    ok "EP-032 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-032 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-032 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-032 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-032 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-032" >/dev/null || fail "green/EP-032 tag missing"
    ok "EP-032 verify: ok"
    ;;
  *)
    fail "unknown subcommand ${1:-<none>}"
    ;;
esac

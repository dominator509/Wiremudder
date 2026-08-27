#!/usr/bin/env sh
# Node verifier for EP-013 Mapper, World Graph, and Routing.
set -eu

NODE=EP-013
fail() { echo "node verifier $NODE: FAIL - $1" >&2; exit 1; }
ok() { echo "$1"; exit 0; }

require_env() {
  [ -f .env ] || fail "missing .env"
  set -a; . ./.env; set +a
}
check_pinned_commit() {
  require_env
  commit=${WIREMUDDER_UPSTREAM_COMMIT:-}
  git cat-file -e "$commit^{commit}" 2>/dev/null || fail "pinned commit missing"
  git merge-base --is-ancestor "$commit" HEAD || fail "pinned commit not ancestor"
}
check_cargo() {
  cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
  [ -x "$cargo_bin" ] || fail "cargo missing"
}

case "${1:-}" in
  M1)
    check_pinned_commit
    [ -f .agent/node-contracts/EP-013.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-013.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-013.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-013-$m.txt" ] || fail "missing milestone fence $m"
    done
    n=$(wc -l < .agent/state/source-evidence.jsonl | tr -d ' ')
    [ "$n" -ge 98 ] || fail "insufficient source evidence ($n records)"
    for f in WM-FEAT-0165 WM-FEAT-0166 WM-FEAT-0167 WM-FEAT-0168; do
      grep -q "$f" .agent/node-contracts/EP-013.md || fail "owned $f missing from contract"
    done
    for r in WM-SPEC-005-R07 WM-SPEC-012-R02 WM-SPEC-012-R03 WM-SPEC-012-R04 WM-SPEC-012-R05 WM-SPEC-012-R10; do
      grep -q "$r" .agent/node-contracts/EP-013.md || fail "owned $r missing from contract"
    done
    [ -d tests/wiremudder/ep013/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep013/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-013 >/dev/null || fail "scope audit"
    ok "EP-013 M1: ok"
    ;;
  M2)
    check_pinned_commit
    [ -d src/wiremudder/mapper ] || fail "missing mapper boundary"
    [ -d wirecore/crates/wire-world-graph ] || fail "missing world graph crate"
    [ -d schemas/wiremudder/world ] || fail "missing world schemas"
    [ -d docs/wiremudder/mapper ] || fail "missing mapper docs"
    [ -d tests/wiremudder/ep013/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep013/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-013 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep013/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep013/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/mapper ] || fail "missing mapper design docs"
    [ -d compatibility/maps ] || fail "missing map compatibility fixtures"
    for t in tests/wiremudder/ep013/integration/*.sh tests/wiremudder/ep013/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-013 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep013/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep013/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep013/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/mapper/operations ] || fail "missing mapper operations docs"
    for t in tests/wiremudder/ep013/failure/*.sh tests/wiremudder/ep013/security/*.sh tests/wiremudder/ep013/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-013 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-013-mapper-route-roundtrip.sh ] || fail "missing LF-013"
    sh tests/live-fire/LF-013-mapper-route-roundtrip.sh || fail "LF-013 failed"
    [ -d docs/wiremudder/mapper ] || fail "missing mapper docs"
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-013 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-013 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-013 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-013 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-013 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-013" >/dev/null || fail "green/EP-013 tag missing"
    ok "EP-013 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

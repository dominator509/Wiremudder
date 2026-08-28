#!/usr/bin/env sh
# Node verifier for EP-030 Imports, Migrations, and Client Ecosystem.
set -eu

NODE=EP-030
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
    [ -f .agent/node-contracts/EP-030.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-030.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-030.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-030-$m.txt" ] || fail "missing milestone fence $m"
    done
    for c in wirecore/crates/wire-import/ src/wiremudder/ui/import/ \
             compatibility/imports/ schemas/wiremudder/import/; do
      grep -q "$c" .agent/node-contracts/EP-030.md || fail "authorized boundary $c missing from contract"
    done
    grep -q "WM-FEAT-0120" .agent/node-contracts/EP-030.md || fail "owned WM-FEAT-0120 missing from contract"
    grep -q "WM-SPEC-020-R07" .agent/node-contracts/EP-030.md || fail "owned WM-SPEC-020-R07 missing from contract"
    [ -d tests/wiremudder/ep030/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep030/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-030 >/dev/null || fail "scope audit"
    ok "EP-030 M1: ok"
    ;;
  M2)
    check_pinned_commit
    check_cargo
    [ -d wirecore/crates/wire-import ] || fail "missing wire-import crate"
    [ -d src/wiremudder/ui/import ] || fail "missing import UI boundary"
    [ -d compatibility/imports ] || fail "missing compatibility corpus"
    [ -d schemas/wiremudder/import ] || fail "missing import schemas"
    [ -d tests/wiremudder/ep030/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep030/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-030 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep030/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep030/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/imports/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep030/integration/*.sh tests/wiremudder/ep030/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-030 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep030/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep030/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep030/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/imports/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep030/failure/*.sh tests/wiremudder/ep030/security/*.sh tests/wiremudder/ep030/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-030 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-030-import-migration-disabled-automation.sh ] || fail "missing LF-030"
    sh tests/live-fire/LF-030-import-migration-disabled-automation.sh || fail "LF-030 failed"
    [ -d docs/wiremudder/imports ] || fail "missing imports docs"
    [ -d tests/wiremudder/ep030/feature-0120 ] || fail "missing feature test dir"
    for t in tests/wiremudder/ep030/feature-0120/*.sh; do
      [ -f "$t" ] || fail "no feature test"
      sh "$t" || fail "feature test failed: $t"
    done
    for r in wm-spec-020-r07; do
      [ -d "tests/wiremudder/ep030/requirements/$r" ] || fail "missing requirement test dir $r"
      for t in tests/wiremudder/ep030/requirements/$r/*.sh; do
        [ -f "$t" ] || fail "no requirement test in $r"
        sh "$t" || fail "requirement test failed: $t"
      done
    done
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-030 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-030 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-030 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-030 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-030 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-030" >/dev/null || fail "green/EP-030 tag missing"
    ok "EP-030 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

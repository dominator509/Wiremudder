#!/usr/bin/env sh
# Node verifier for EP-023 Multi-Session, Headless CLI, and Supervisor.
set -eu

NODE=EP-023
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
    [ -f .agent/node-contracts/EP-023.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-023.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-023.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-023-$m.txt" ] || fail "missing milestone fence $m"
    done
    for c in src/wiremudder/headless/ wirecore/crates/wire-headless/ schemas/wiremudder/headless/ tools/wiremudder-supervisor/; do
      grep -q "$c" .agent/node-contracts/EP-023.md || fail "authorized boundary $c missing from contract"
    done
    for f in WM-FEAT-0078 WM-FEAT-0081 WM-FEAT-0083 WM-FEAT-0121 WM-FEAT-0122 WM-FEAT-0123 WM-FEAT-0124 WM-FEAT-0125; do
      grep -q "$f" .agent/node-contracts/EP-023.md || fail "owned $f missing from contract"
    done
    for r in WM-SPEC-006-R10 WM-SPEC-017-R02 WM-SPEC-017-R04 WM-SPEC-017-R06 WM-SPEC-017-R10 WM-SPEC-024-R04 WM-SPEC-024-R08 WM-SPEC-026-R01; do
      grep -q "$r" .agent/node-contracts/EP-023.md || fail "owned $r missing from contract"
    done
    [ -d tests/wiremudder/ep023/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep023/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-023 >/dev/null || fail "scope audit"
    ok "EP-023 M1: ok"
    ;;
  M2)
    check_pinned_commit
    check_cargo
    [ -d wirecore/crates/wire-headless ] || fail "missing wire-headless crate"
    [ -d schemas/wiremudder/headless ] || fail "missing headless schemas"
    [ -d tests/wiremudder/ep023/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep023/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-023 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep023/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep023/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/headless/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep023/integration/*.sh tests/wiremudder/ep023/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-023 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep023/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep023/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep023/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/headless/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep023/failure/*.sh tests/wiremudder/ep023/security/*.sh tests/wiremudder/ep023/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-023 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-023-headless-multisession.sh ] || fail "missing LF-023"
    sh tests/live-fire/LF-023-headless-multisession.sh || fail "LF-023 failed"
    [ -d docs/wiremudder/headless ] || fail "missing headless docs"
    for f in feature-0078 feature-0081 feature-0083 feature-0121 feature-0122 feature-0123 feature-0124 feature-0125; do
      [ -d "tests/wiremudder/ep023/$f" ] || fail "missing feature test dir $f"
      for t in tests/wiremudder/ep023/$f/*.sh; do
        [ -f "$t" ] || fail "no feature test in $f"
        sh "$t" || fail "feature test failed: $t"
      done
    done
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-023 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-023 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-023 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-023 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-023 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-023" >/dev/null || fail "green/EP-023 tag missing"
    ok "EP-023 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

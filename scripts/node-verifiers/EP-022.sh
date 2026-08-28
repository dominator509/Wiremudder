#!/usr/bin/env sh
# Node verifier for EP-022 Macro Forge, Trigger Lab, and AI Debugger.
set -eu

NODE=EP-022
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
    [ -f .agent/node-contracts/EP-022.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-022.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-022.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-022-$m.txt" ] || fail "missing milestone fence $m"
    done
    for c in src/wiremudder/ui/power-tools/ wirecore/crates/wire-debugger/ compatibility/automation/ schemas/wiremudder/debug/; do
      grep -q "$c" .agent/node-contracts/EP-022.md || fail "authorized boundary $c missing from contract"
    done
    for f in WM-FEAT-0106 WM-FEAT-0107 WM-FEAT-0108 WM-FEAT-0127 WM-FEAT-0161 WM-FEAT-0162; do
      grep -q "$f" .agent/node-contracts/EP-022.md || fail "owned $f missing from contract"
    done
    for r in WM-SPEC-008-R02 WM-SPEC-008-R07 WM-SPEC-008-R08 WM-SPEC-019-R06; do
      grep -q "$r" .agent/node-contracts/EP-022.md || fail "owned $r missing from contract"
    done
    [ -d tests/wiremudder/ep022/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep022/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-022 >/dev/null || fail "scope audit"
    ok "EP-022 M1: ok"
    ;;
  M2)
    check_pinned_commit
    check_cargo
    [ -d wirecore/crates/wire-debugger ] || fail "missing wire-debugger crate"
    [ -d schemas/wiremudder/debug ] || fail "missing debug schemas"
    [ -d tests/wiremudder/ep022/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep022/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-022 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep022/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep022/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/power-tools/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep022/integration/*.sh tests/wiremudder/ep022/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-022 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep022/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep022/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep022/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/power-tools/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep022/failure/*.sh tests/wiremudder/ep022/security/*.sh tests/wiremudder/ep022/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-022 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-022-macro-trigger-debug.sh ] || fail "missing LF-022"
    sh tests/live-fire/LF-022-macro-trigger-debug.sh || fail "LF-022 failed"
    [ -d docs/wiremudder/power-tools ] || fail "missing power-tools docs"
    for f in feature-0106 feature-0107 feature-0108 feature-0127 feature-0161 feature-0162; do
      [ -d "tests/wiremudder/ep022/$f" ] || fail "missing feature test dir $f"
      for t in tests/wiremudder/ep022/$f/*.sh; do
        [ -f "$t" ] || fail "no feature test in $f"
        sh "$t" || fail "feature test failed: $t"
      done
    done
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-022 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-022 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-022 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-022 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-022 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-022" >/dev/null || fail "green/EP-022 tag missing"
    ok "node verify EP-022: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

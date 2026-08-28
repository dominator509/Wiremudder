#!/usr/bin/env sh
# Node verifier for EP-029 Bounded Bug Automation and Remediation.
set -eu

NODE=EP-029
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
    [ -f .agent/node-contracts/EP-029.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-029.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-029.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-029-$m.txt" ] || fail "missing milestone fence $m"
    done
    for c in wirecore/crates/wire-bug-automation/ tools/wiremudder-bug-lab/ \
             schemas/wiremudder/bugs/ maintenance/wiremudder/; do
      grep -q "$c" .agent/node-contracts/EP-029.md || fail "authorized boundary $c missing from contract"
    done
    for f in WM-FEAT-0133 WM-FEAT-0226 WM-FEAT-0228 WM-FEAT-0229; do
      grep -q "$f" .agent/node-contracts/EP-029.md || fail "owned $f missing from contract"
    done
    for r in WM-SPEC-019-R09 WM-SPEC-025-R03; do
      grep -q "$r" .agent/node-contracts/EP-029.md || fail "owned $r missing from contract"
    done
    [ -d tests/wiremudder/ep029/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep029/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-029 >/dev/null || fail "scope audit"
    ok "EP-029 M1: ok"
    ;;
  M2)
    check_pinned_commit
    check_cargo
    [ -d wirecore/crates/wire-bug-automation ] || fail "missing wire-bug-automation crate"
    [ -d tools/wiremudder-bug-lab ] || fail "missing bug-lab tool"
    [ -d schemas/wiremudder/bugs ] || fail "missing bug schemas"
    [ -d maintenance/wiremudder ] || fail "missing maintenance dir"
    [ -d tests/wiremudder/ep029/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep029/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-029 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep029/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep029/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/bug-automation/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep029/integration/*.sh tests/wiremudder/ep029/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-029 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep029/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep029/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep029/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/bug-automation/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep029/failure/*.sh tests/wiremudder/ep029/security/*.sh tests/wiremudder/ep029/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-029 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-029-bug-remediation-replay.sh ] || fail "missing LF-029"
    sh tests/live-fire/LF-029-bug-remediation-replay.sh || fail "LF-029 failed"
    [ -d docs/wiremudder/bug-automation ] || fail "missing bug-automation docs"
    for f in feature-0133 feature-0226 feature-0228 feature-0229; do
      [ -d "tests/wiremudder/ep029/$f" ] || fail "missing feature test dir $f"
      for t in tests/wiremudder/ep029/$f/*.sh; do
        [ -f "$t" ] || fail "no feature test in $f"
        sh "$t" || fail "feature test failed: $t"
      done
    done
    for r in wm-spec-019-r09 wm-spec-025-r03; do
      [ -d "tests/wiremudder/ep029/requirements/$r" ] || fail "missing requirement test dir $r"
      for t in tests/wiremudder/ep029/requirements/$r/*.sh; do
        [ -f "$t" ] || fail "no requirement test in $r"
        sh "$t" || fail "requirement test failed: $t"
      done
    done
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-029 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-029 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-029 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-029 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-029 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-029" >/dev/null || fail "green/EP-029 tag missing"
    ok "EP-029 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

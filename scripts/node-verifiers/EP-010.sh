#!/usr/bin/env sh
# Node verifier for EP-010 Scripting, Plugins, Packages, and Permissions.
set -eu

NODE=EP-010
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
    [ -f .agent/node-contracts/EP-010.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-010.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-010.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-010-$m.txt" ] || fail "missing milestone fence $m"
    done
    n=$(wc -l < .agent/state/source-evidence.jsonl | tr -d ' ')
    [ "$n" -ge 81 ] || fail "insufficient source evidence ($n records)"
    for f in WM-FEAT-0098 WM-FEAT-0103 WM-FEAT-0104 WM-FEAT-0105 WM-FEAT-0110 WM-FEAT-0113 WM-FEAT-0114 WM-FEAT-0115 WM-FEAT-0116 WM-FEAT-0117 WM-FEAT-0118 WM-FEAT-0119; do
      grep -q "$f" .agent/node-contracts/EP-010.md || fail "owned $f missing from contract"
    done
    for r in WM-SPEC-008-R01 WM-SPEC-008-R03 WM-SPEC-008-R04 WM-SPEC-008-R05 WM-SPEC-020-R05 WM-SPEC-021-R04 WM-SPEC-022-R01 WM-SPEC-022-R02 WM-SPEC-022-R05; do
      grep -q "$r" .agent/node-contracts/EP-010.md || fail "owned $r missing from contract"
    done
    [ -d tests/wiremudder/ep010/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep010/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-010 >/dev/null || fail "scope audit"
    ok "EP-010 M1: ok"
    ;;
  M2)
    check_pinned_commit
    check_cargo
    [ -d wirecore/crates/wire-packages ] || fail "missing wire-packages crate"
    [ -f wirecore/crates/wire-packages/Cargo.toml ] || fail "missing wire-packages manifest"
    [ -d src/wiremudder/packages ] || fail "missing C++ packages boundary"
    [ -d schemas/wiremudder/packages ] || fail "missing package schemas"
    [ -d compatibility/packages ] || fail "missing package compatibility tree"
    [ -d tests/wiremudder/ep010/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep010/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-010 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep010/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep010/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/packages/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep010/integration/*.sh tests/wiremudder/ep010/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-010 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep010/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep010/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep010/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/packages/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep010/failure/*.sh tests/wiremudder/ep010/security/*.sh tests/wiremudder/ep010/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-010 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-010-package-script-sandbox.sh ] || fail "missing LF-010"
    sh tests/live-fire/LF-010-package-script-sandbox.sh || fail "LF-010 failed"
    [ -d docs/wiremudder/packages ] || fail "missing packages docs"
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-010 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-010 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-010 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-010 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-010 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-010" >/dev/null || fail "green/EP-010 tag missing"
    ok "EP-010 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

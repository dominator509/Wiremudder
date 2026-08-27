#!/usr/bin/env sh
# Node verifier for EP-009 Inherited Classic Client Parity.
set -eu

NODE=EP-009
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
    [ -f .agent/node-contracts/EP-009.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-009.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-009.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-009-$m.txt" ] || fail "missing milestone fence $m"
    done
    n=$(wc -l < .agent/state/source-evidence.jsonl | tr -d ' ')
    [ "$n" -ge 75 ] || fail "insufficient source evidence ($n records)"
    for f in WM-FEAT-0002 WM-FEAT-0005 WM-FEAT-0006 WM-FEAT-0007 WM-FEAT-0008 WM-FEAT-0009 WM-FEAT-0010 WM-FEAT-0013 WM-FEAT-0014 WM-FEAT-0015 WM-FEAT-0016 WM-FEAT-0017 WM-FEAT-0020; do
      grep -q "$f" .agent/node-contracts/EP-009.md || fail "owned $f missing from contract"
    done
    for r in WM-SPEC-007-R01 WM-SPEC-007-R05 WM-SPEC-007-R06 WM-SPEC-007-R07 WM-SPEC-007-R08 WM-SPEC-008-R06 WM-SPEC-008-R09 WM-SPEC-008-R10; do
      grep -q "$r" .agent/node-contracts/EP-009.md || fail "owned $r missing from contract"
    done
    [ -d tests/wiremudder/ep009/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep009/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-009 >/dev/null || fail "scope audit"
    ok "EP-009 M1: ok"
    ;;
  M2)
    check_pinned_commit
    [ -d tests/wiremudder/classic ] || fail "missing classic fixture tree"
    [ -d compatibility/classic ] || fail "missing compatibility tree"
    [ -f compatibility/classic/README.md ] || fail "missing compatibility README"
    for d in tests/wiremudder/classic/ansi tests/wiremudder/classic/automation tests/wiremudder/classic/lua tests/wiremudder/classic/mapper tests/wiremudder/classic/logging; do
      [ -d "$d" ] || fail "missing classic fixture dir $d"
    done
    [ -d tests/wiremudder/ep009/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep009/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-009 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep009/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep009/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/classic-parity/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep009/integration/*.sh tests/wiremudder/ep009/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-009 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep009/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep009/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep009/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/classic-parity/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep009/failure/*.sh tests/wiremudder/ep009/security/*.sh tests/wiremudder/ep009/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-009 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-009-classic-client-regression.sh ] || fail "missing LF-009"
    sh tests/live-fire/LF-009-classic-client-regression.sh || fail "LF-009 failed"
    [ -d docs/wiremudder/classic-parity ] || fail "missing classic-parity docs"
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-009 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-009 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-009 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-009 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-009 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-009" >/dev/null || fail "green/EP-009 tag missing"
    ok "EP-009 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

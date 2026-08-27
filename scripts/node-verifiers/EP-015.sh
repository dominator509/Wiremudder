#!/usr/bin/env sh
# Node verifier for EP-015 Context Distillation and Token Budget.
set -eu

NODE=EP-015
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
    [ -f .agent/node-contracts/EP-015.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-015.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-015.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-015-$m.txt" ] || fail "missing milestone fence $m"
    done
    n=$(wc -l < .agent/state/source-evidence.jsonl | tr -d ' ')
    [ "$n" -ge 106 ] || fail "insufficient source evidence ($n records)"
    for r in WM-SPEC-013-R01 WM-SPEC-013-R02 WM-SPEC-013-R05 \
             WM-SPEC-013-R06 WM-SPEC-013-R07 WM-SPEC-013-R09; do
      grep -q "$r" .agent/node-contracts/EP-015.md || fail "owned $r missing from contract"
    done
    [ -d tests/wiremudder/ep015/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep015/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-015 >/dev/null || fail "scope audit"
    ok "EP-015 M1: ok"
    ;;
  M2)
    check_pinned_commit
    [ -d wirecore/crates/wire-context ] || fail "missing wire-context crate"
    [ -d wirecore/crates/wire-token-budget ] || fail "missing wire-token-budget crate"
    [ -d schemas/wiremudder/context ] || fail "missing context schemas"
    [ -d tests/wiremudder/ep015/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep015/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-015 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep015/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep015/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/context/design ] || fail "missing context design docs"
    [ -d compatibility/context ] || fail "missing compatibility oracle"
    for t in tests/wiremudder/ep015/integration/*.sh tests/wiremudder/ep015/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-015 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep015/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep015/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep015/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/context/operations ] || fail "missing context operations docs"
    for t in tests/wiremudder/ep015/failure/*.sh tests/wiremudder/ep015/security/*.sh tests/wiremudder/ep015/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-015 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-015-distilled-context-budget.sh ] || fail "missing LF-015"
    sh tests/live-fire/LF-015-distilled-context-budget.sh || fail "LF-015 failed"
    [ -d docs/wiremudder/context ] || fail "missing context docs"
    for f in tests/wiremudder/ep015/feature-0048 tests/wiremudder/ep015/feature-0049 \
             tests/wiremudder/ep015/feature-0189 tests/wiremudder/ep015/feature-0196 \
             tests/wiremudder/ep015/feature-0197 tests/wiremudder/ep015/feature-0198 \
             tests/wiremudder/ep015/feature-0199 tests/wiremudder/ep015/feature-0200 \
             tests/wiremudder/ep015/feature-0201 tests/wiremudder/ep015/feature-0202 \
             tests/wiremudder/ep015/feature-0203 tests/wiremudder/ep015/feature-0204 \
             tests/wiremudder/ep015/feature-0205 tests/wiremudder/ep015/feature-0206; do
      [ -d "$f" ] || fail "missing feature test dir $f"
      for t in "$f"/*.sh; do
        [ -f "$t" ] || fail "no feature test in $f"
        sh "$t" || fail "feature test failed: $t"
      done
    done
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-015 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-015 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-015 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-015 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-015 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-015" >/dev/null || fail "green/EP-015 tag missing"
    ok "EP-015 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

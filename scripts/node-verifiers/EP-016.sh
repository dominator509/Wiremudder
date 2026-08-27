#!/usr/bin/env sh
# Node verifier for EP-016 AI Provider Router and Adapters.
set -eu

NODE=EP-016
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
    [ -f .agent/node-contracts/EP-016.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-016.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-016.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-016-$m.txt" ] || fail "missing milestone fence $m"
    done
    n=$(wc -l < .agent/state/source-evidence.jsonl | tr -d ' ')
    [ "$n" -ge 108 ] || fail "insufficient source evidence ($n records)"
    for r in WM-SPEC-013-R03 WM-SPEC-013-R04 WM-SPEC-013-R08 \
             WM-SPEC-013-R10 WM-SPEC-025-R07 WM-SPEC-025-R09; do
      grep -q "$r" .agent/node-contracts/EP-016.md || fail "owned $r missing from contract"
    done
    [ -d tests/wiremudder/ep016/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep016/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-016 >/dev/null || fail "scope audit"
    ok "EP-016 M1: ok"
    ;;
  M2)
    check_pinned_commit
    [ -d wirecore/crates/wire-ai-router ] || fail "missing wire-ai-router crate"
    [ -d wirecore/crates/wire-provider-adapters ] || fail "missing wire-provider-adapters crate"
    [ -d schemas/wiremudder/ai ] || fail "missing ai schemas"
    [ -d config/wiremudder/providers ] || fail "missing provider config"
    [ -d tests/wiremudder/ep016/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep016/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-016 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep016/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep016/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/ai-providers/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep016/integration/*.sh tests/wiremudder/ep016/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-016 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep016/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep016/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep016/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/ai-providers/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep016/failure/*.sh tests/wiremudder/ep016/security/*.sh tests/wiremudder/ep016/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-016 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-016-provider-routing-fallback.sh ] || fail "missing LF-016"
    sh tests/live-fire/LF-016-provider-routing-fallback.sh || fail "LF-016 failed"
    [ -d docs/wiremudder/ai-providers ] || fail "missing ai-providers docs"
    for f in tests/wiremudder/ep016/feature-0037 tests/wiremudder/ep016/feature-0038; do
      [ -d "$f" ] || fail "missing feature test dir $f"
      for t in "$f"/*.sh; do
        [ -f "$t" ] || fail "no feature test in $f"
        sh "$t" || fail "feature test failed: $t"
      done
    done
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-016 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-016 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-016 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-016 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-016 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-016" >/dev/null || fail "green/EP-016 tag missing"
    ok "EP-016 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

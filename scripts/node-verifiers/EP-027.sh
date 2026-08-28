#!/usr/bin/env sh
# Node verifier for EP-027 Contextual Help, Setup Coach, and Source Index.
set -eu

NODE=EP-027
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
    [ -f .agent/node-contracts/EP-027.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-027.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-027.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-027-$m.txt" ] || fail "missing milestone fence $m"
    done
    for c in src/wiremudder/ui/help/ wirecore/crates/wire-help/ schemas/wiremudder/help/ tools/help-indexer/; do
      grep -q "$c" .agent/node-contracts/EP-027.md || fail "authorized boundary $c missing from contract"
    done
    for f in WM-FEAT-0109 WM-FEAT-0111 WM-FEAT-0112 WM-FEAT-0187 WM-FEAT-0213 \
             WM-FEAT-0214 WM-FEAT-0215 WM-FEAT-0216 WM-FEAT-0217 WM-FEAT-0218 \
             WM-FEAT-0219; do
      grep -q "$f" .agent/node-contracts/EP-027.md || fail "owned $f missing from contract"
    done
    for r in WM-SPEC-007-R09 WM-SPEC-018-R04 WM-SPEC-018-R05 WM-SPEC-018-R09; do
      grep -q "$r" .agent/node-contracts/EP-027.md || fail "owned $r missing from contract"
    done
    [ -d tests/wiremudder/ep027/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep027/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-027 >/dev/null || fail "scope audit"
    ok "EP-027 M1: ok"
    ;;
  M2)
    check_pinned_commit
    check_cargo
    [ -d wirecore/crates/wire-help ] || fail "missing wire-help crate"
    [ -d schemas/wiremudder/help ] || fail "missing help schemas"
    [ -d tools/help-indexer ] || fail "missing help-indexer tool"
    [ -d tests/wiremudder/ep027/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep027/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-027 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep027/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep027/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/help/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep027/integration/*.sh tests/wiremudder/ep027/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-027 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep027/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep027/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep027/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/help/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep027/failure/*.sh tests/wiremudder/ep027/security/*.sh tests/wiremudder/ep027/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-027 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-027-help-coach-no-side-effects.sh ] || fail "missing LF-027"
    sh tests/live-fire/LF-027-help-coach-no-side-effects.sh || fail "LF-027 failed"
    [ -d docs/wiremudder/help ] || fail "missing help docs"
    for f in feature-0109 feature-0111 feature-0112 feature-0187 feature-0213 \
             feature-0214 feature-0215 feature-0216 feature-0217 feature-0218 \
             feature-0219; do
      [ -d "tests/wiremudder/ep027/$f" ] || fail "missing feature test dir $f"
      for t in tests/wiremudder/ep027/$f/*.sh; do
        [ -f "$t" ] || fail "no feature test in $f"
        sh "$t" || fail "feature test failed: $t"
      done
    done
    for r in wm-spec-007-r09 wm-spec-018-r04 wm-spec-018-r05 wm-spec-018-r09; do
      [ -d "tests/wiremudder/ep027/requirements/$r" ] || fail "missing requirement test dir $r"
      for t in tests/wiremudder/ep027/requirements/$r/*.sh; do
        [ -f "$t" ] || fail "no requirement test in $r"
        sh "$t" || fail "requirement test failed: $t"
      done
    done
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-027 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-027 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-027 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-027 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-027 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-027" >/dev/null || fail "green/EP-027 tag missing"
    ok "EP-027 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

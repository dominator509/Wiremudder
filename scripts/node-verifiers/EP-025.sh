#!/usr/bin/env sh
# Node verifier for EP-025 Retro Renderer, Diorama, and Visual Emits.
set -eu

NODE=EP-025
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
    [ -f .agent/node-contracts/EP-025.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-025.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-025.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-025-$m.txt" ] || fail "missing milestone fence $m"
    done
    for c in src/wiremudder/ui/renderer/ wirecore/crates/wire-renderer/ schemas/wiremudder/renderer/ assets/wiremudder/renderer/; do
      grep -q "$c" .agent/node-contracts/EP-025.md || fail "authorized boundary $c missing from contract"
    done
    for f in WM-FEAT-0069 WM-FEAT-0070 WM-FEAT-0071 WM-FEAT-0072 WM-FEAT-0073 \
             WM-FEAT-0074 WM-FEAT-0077 WM-FEAT-0185 WM-FEAT-0207 WM-FEAT-0208 \
             WM-FEAT-0209 WM-FEAT-0210; do
      grep -q "$f" .agent/node-contracts/EP-025.md || fail "owned $f missing from contract"
    done
    for r in WM-SPEC-004-R04 WM-SPEC-004-R07 WM-SPEC-016-R01 WM-SPEC-016-R03 \
             WM-SPEC-016-R05 WM-SPEC-016-R06 WM-SPEC-016-R09 WM-SPEC-016-R10; do
      grep -q "$r" .agent/node-contracts/EP-025.md || fail "owned $r missing from contract"
    done
    [ -d tests/wiremudder/ep025/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep025/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-025 >/dev/null || fail "scope audit"
    ok "EP-025 M1: ok"
    ;;
  M2)
    check_pinned_commit
    check_cargo
    [ -d wirecore/crates/wire-renderer ] || fail "missing wire-renderer crate"
    [ -d schemas/wiremudder/renderer ] || fail "missing renderer schemas"
    [ -d assets/wiremudder/renderer ] || fail "missing renderer assets"
    [ -d tests/wiremudder/ep025/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep025/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-025 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep025/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep025/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/renderer/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep025/integration/*.sh tests/wiremudder/ep025/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-025 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep025/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep025/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep025/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/renderer/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep025/failure/*.sh tests/wiremudder/ep025/security/*.sh tests/wiremudder/ep025/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-025 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-025-renderer-degradation.sh ] || fail "missing LF-025"
    sh tests/live-fire/LF-025-renderer-degradation.sh || fail "LF-025 failed"
    [ -d docs/wiremudder/renderer ] || fail "missing renderer docs"
    for f in feature-0069 feature-0070 feature-0071 feature-0072 feature-0073 \
             feature-0074 feature-0077 feature-0185 feature-0207 feature-0208 \
             feature-0209 feature-0210; do
      [ -d "tests/wiremudder/ep025/$f" ] || fail "missing feature test dir $f"
      for t in tests/wiremudder/ep025/$f/*.sh; do
        [ -f "$t" ] || fail "no feature test in $f"
        sh "$t" || fail "feature test failed: $t"
      done
    done
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-025 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-025 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-025 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-025 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-025 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-025" >/dev/null || fail "green/EP-025 tag missing"
    ok "EP-025 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

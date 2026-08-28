#!/usr/bin/env sh
# Node verifier for EP-026 Soundscape Engine and Audio Studio.
set -eu

NODE=EP-026
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
    [ -f .agent/node-contracts/EP-026.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-026.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-026.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-026-$m.txt" ] || fail "missing milestone fence $m"
    done
    for c in src/wiremudder/ui/soundscape/ wirecore/crates/wire-soundscape/ schemas/wiremudder/audio/ assets/wiremudder/audio/; do
      grep -q "$c" .agent/node-contracts/EP-026.md || fail "authorized boundary $c missing from contract"
    done
    for f in WM-FEAT-0075 WM-FEAT-0076; do
      grep -q "$f" .agent/node-contracts/EP-026.md || fail "owned $f missing from contract"
    done
    grep -q "WM-SPEC-016-R08" .agent/node-contracts/EP-026.md || fail "owned WM-SPEC-016-R08 missing from contract"
    [ -d tests/wiremudder/ep026/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep026/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-026 >/dev/null || fail "scope audit"
    ok "EP-026 M1: ok"
    ;;
  M2)
    check_pinned_commit
    check_cargo
    [ -d wirecore/crates/wire-soundscape ] || fail "missing wire-soundscape crate"
    [ -d schemas/wiremudder/audio ] || fail "missing audio schemas"
    [ -d assets/wiremudder/audio ] || fail "missing audio assets"
    [ -d tests/wiremudder/ep026/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep026/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-026 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep026/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep026/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/soundscape/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep026/integration/*.sh tests/wiremudder/ep026/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-026 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep026/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep026/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep026/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/soundscape/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep026/failure/*.sh tests/wiremudder/ep026/security/*.sh tests/wiremudder/ep026/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-026 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-026-soundscape-degradation.sh ] || fail "missing LF-026"
    sh tests/live-fire/LF-026-soundscape-degradation.sh || fail "LF-026 failed"
    [ -d docs/wiremudder/soundscape ] || fail "missing soundscape docs"
    for f in feature-0075 feature-0076; do
      [ -d "tests/wiremudder/ep026/$f" ] || fail "missing feature test dir $f"
      for t in tests/wiremudder/ep026/$f/*.sh; do
        [ -f "$t" ] || fail "no feature test in $f"
        sh "$t" || fail "feature test failed: $t"
      done
    done
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-026 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-026 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-026 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-026 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-026 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-026" >/dev/null || fail "green/EP-026 tag missing"
    ok "EP-026 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

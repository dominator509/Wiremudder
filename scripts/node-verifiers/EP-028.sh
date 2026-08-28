#!/usr/bin/env sh
# Node verifier for EP-028 Telemetry, Replay, and Diagnostic Bundles.
set -eu

NODE=EP-028
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
    [ -f .agent/node-contracts/EP-028.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-028.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-028.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-028-$m.txt" ] || fail "missing milestone fence $m"
    done
    for c in src/wiremudder/ui/diagnostics/ wirecore/crates/wire-telemetry/ \
             wirecore/crates/wire-replay/ schemas/wiremudder/telemetry/; do
      grep -q "$c" .agent/node-contracts/EP-028.md || fail "authorized boundary $c missing from contract"
    done
    for f in WM-FEAT-0128 WM-FEAT-0132 WM-FEAT-0221 WM-FEAT-0223 WM-FEAT-0224 \
             WM-FEAT-0225 WM-FEAT-0227; do
      grep -q "$f" .agent/node-contracts/EP-028.md || fail "owned $f missing from contract"
    done
    for r in WM-SPEC-011-R03 WM-SPEC-011-R10 WM-SPEC-019-R01 WM-SPEC-019-R03 \
             WM-SPEC-023-R05 WM-SPEC-024-R09 WM-SPEC-025-R02 WM-SPEC-026-R07 \
             WM-SPEC-026-R08; do
      grep -q "$r" .agent/node-contracts/EP-028.md || fail "owned $r missing from contract"
    done
    [ -d tests/wiremudder/ep028/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep028/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-028 >/dev/null || fail "scope audit"
    ok "EP-028 M1: ok"
    ;;
  M2)
    check_pinned_commit
    check_cargo
    [ -d wirecore/crates/wire-telemetry ] || fail "missing wire-telemetry crate"
    [ -d wirecore/crates/wire-replay ] || fail "missing wire-replay crate"
    [ -d schemas/wiremudder/telemetry ] || fail "missing telemetry schemas"
    [ -d tests/wiremudder/ep028/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep028/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-028 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep028/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep028/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/diagnostics/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep028/integration/*.sh tests/wiremudder/ep028/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-028 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep028/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep028/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep028/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/diagnostics/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep028/failure/*.sh tests/wiremudder/ep028/security/*.sh tests/wiremudder/ep028/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-028 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-028-diagnostic-bundle-redaction.sh ] || fail "missing LF-028"
    sh tests/live-fire/LF-028-diagnostic-bundle-redaction.sh || fail "LF-028 failed"
    [ -d docs/wiremudder/diagnostics ] || fail "missing diagnostics docs"
    for f in feature-0128 feature-0132 feature-0221 feature-0223 feature-0224 \
             feature-0225 feature-0227; do
      [ -d "tests/wiremudder/ep028/$f" ] || fail "missing feature test dir $f"
      for t in tests/wiremudder/ep028/$f/*.sh; do
        [ -f "$t" ] || fail "no feature test in $f"
        sh "$t" || fail "feature test failed: $t"
      done
    done
    for r in wm-spec-011-r03 wm-spec-011-r10 wm-spec-019-r01 wm-spec-019-r03 \
             wm-spec-023-r05 wm-spec-024-r09 wm-spec-025-r02 wm-spec-026-r07 \
             wm-spec-026-r08; do
      [ -d "tests/wiremudder/ep028/requirements/$r" ] || fail "missing requirement test dir $r"
      for t in tests/wiremudder/ep028/requirements/$r/*.sh; do
        [ -f "$t" ] || fail "no requirement test in $r"
        sh "$t" || fail "requirement test failed: $t"
      done
    done
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-028 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-028 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-028 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-028 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-028 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-028" >/dev/null || fail "green/EP-028 tag missing"
    ok "EP-028 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

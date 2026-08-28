#!/usr/bin/env sh
# Node verifier for EP-019 Guarded Autopilot and Action Queue.
set -eu

NODE=EP-019
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
    [ -f .agent/node-contracts/EP-019.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-019.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-019.discovered.txt ] || fail "missing discovered amendment"
    # The Autopilot UI must be compiled into the client: the discovered
    # amendment MUST authorize the inherited build list (smallest patch).
    grep -q '"path":"src/CMakeLists.txt"' .agent/expected-files/EP-019.discovered.txt \
      || fail "discovered amendment missing inherited build list (src/CMakeLists.txt)"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-019-$m.txt" ] || fail "missing milestone fence $m"
    done
    n=$(wc -l < .agent/state/source-evidence.jsonl | tr -d ' ')
    [ "$n" -ge 125 ] || fail "insufficient source evidence ($n records)"
    for f in WM-FEAT-0041; do
      grep -q "$f" .agent/node-contracts/EP-019.md || fail "owned $f missing from contract"
    done
    for r in WM-SPEC-009-R02 WM-SPEC-009-R04 WM-SPEC-014-R10; do
      grep -q "$r" .agent/node-contracts/EP-019.md || fail "owned $r missing from contract"
    done
    [ -d tests/wiremudder/ep019/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep019/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-019 >/dev/null || fail "scope audit"
    ok "EP-019 M1: ok"
    ;;
  M2)
    check_pinned_commit
    check_cargo
    [ -d wirecore/crates/wire-autopilot ] || fail "missing wire-autopilot crate"
    [ -d schemas/wiremudder/autopilot ] || fail "missing autopilot schemas"
    [ -d tests/wiremudder/ep019/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep019/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-019 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep019/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep019/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/autopilot/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep019/integration/*.sh tests/wiremudder/ep019/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-019 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep019/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep019/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep019/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/autopilot/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep019/failure/*.sh tests/wiremudder/ep019/security/*.sh tests/wiremudder/ep019/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-019 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-019-guarded-autopilot-confirmation.sh ] || fail "missing LF-019"
    sh tests/live-fire/LF-019-guarded-autopilot-confirmation.sh || fail "LF-019 failed"
    [ -d docs/wiremudder/autopilot ] || fail "missing autopilot docs"
    [ -d tests/wiremudder/ep019/feature-0041 ] || fail "missing feature test dir feature-0041"
    for t in tests/wiremudder/ep019/feature-0041/*.sh; do
      [ -f "$t" ] || fail "no feature test in feature-0041"
      sh "$t" || fail "feature test failed: $t"
    done
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-019 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-019 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-019 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-019 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-019 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-019" >/dev/null || fail "green/EP-019 tag missing"
    ok "EP-019 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

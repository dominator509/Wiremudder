#!/usr/bin/env sh
# Node verifier for EP-005 Native Bridge, WireCore Boundary, Supervision.
set -eu

NODE=EP-005
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
    [ -f .agent/node-contracts/EP-005.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-005.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-005.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-005-$m.txt" ] || fail "missing milestone fence $m"
    done
    n=$(wc -l < .agent/state/source-evidence.jsonl | tr -d ' ')
    [ "$n" -ge 50 ] || fail "insufficient source evidence ($n records)"
    for f in WM-FEAT-0155 WM-FEAT-0156 WM-FEAT-0157 WM-FEAT-0158; do
      grep -q "$f" .agent/node-contracts/EP-005.md || fail "owned $f missing from contract"
    done
    [ -d tests/wiremudder/ep005/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep005/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-005 >/dev/null || fail "scope audit"
    ok "EP-005 M1: ok"
    ;;
  M2)
    check_pinned_commit
    check_cargo
    [ -d src/wiremudder/bridge ] || fail "missing bridge dir"
    [ -d wirecore/crates/wirecore-runtime ] || fail "missing wirecore-runtime"
    [ -d wirecore/crates/wire-contracts ] || fail "missing wire-contracts"
    [ -d schemas/wiremudder/bridge ] || fail "missing bridge schemas"
    [ -f wirecore/crates/wire-contracts/Cargo.toml ] || fail "missing wire-contracts manifest"
    [ -f wirecore/crates/wirecore-runtime/Cargo.toml ] || fail "missing wirecore-runtime manifest"
    [ -d tests/wiremudder/ep005/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep005/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-005 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep005/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep005/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/bridge/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep005/integration/*.sh tests/wiremudder/ep005/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-005 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep005/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep005/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep005/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/bridge/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep005/failure/*.sh tests/wiremudder/ep005/security/*.sh tests/wiremudder/ep005/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-005 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-005-wirecore-bridge-supervision.sh ] || fail "missing LF-005"
    sh tests/live-fire/LF-005-wirecore-bridge-supervision.sh || fail "LF-005 failed"
    [ -d docs/wiremudder/bridge ] || fail "missing bridge docs"
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-005 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-005 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-005 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-005 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-005 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-005" >/dev/null || fail "green/EP-005 tag missing"
    ok "EP-005 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

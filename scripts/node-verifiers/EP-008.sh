#!/usr/bin/env sh
# Node verifier for EP-008 Command Safety, Emergency Stop, and Human-Tempo.
set -eu

NODE=EP-008
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
    [ -f .agent/node-contracts/EP-008.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-008.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-008.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-008-$m.txt" ] || fail "missing milestone fence $m"
    done
    n=$(wc -l < .agent/state/source-evidence.jsonl | tr -d ' ')
    [ "$n" -ge 60 ] || fail "insufficient source evidence ($n records)"
    for f in WM-FEAT-0174 WM-FEAT-0175 WM-FEAT-0176 WM-FEAT-0177 WM-FEAT-0178 WM-FEAT-0179 WM-FEAT-0180 WM-FEAT-0188; do
      grep -q "$f" .agent/node-contracts/EP-008.md || fail "owned $f missing from contract"
    done
    [ -d tests/wiremudder/ep008/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep008/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-008 >/dev/null || fail "scope audit"
    ok "EP-008 M1: ok"
    ;;
  M2)
    check_pinned_commit
    check_cargo
    [ -d wirecore/crates/wire-actions ] || fail "missing wire-actions crate"
    [ -d wirecore/crates/wire-policy ] || fail "missing wire-policy crate"
    [ -f wirecore/crates/wire-actions/Cargo.toml ] || fail "missing wire-actions manifest"
    [ -f wirecore/crates/wire-policy/Cargo.toml ] || fail "missing wire-policy manifest"
    [ -d schemas/wiremudder/actions ] || fail "missing action schemas"
    [ -d tests/wiremudder/ep008/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep008/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-008 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep008/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep008/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/command-safety/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep008/integration/*.sh tests/wiremudder/ep008/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-008 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep008/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep008/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep008/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/command-safety/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep008/failure/*.sh tests/wiremudder/ep008/security/*.sh tests/wiremudder/ep008/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-008 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-008-emergency-stop-command-gate.sh ] || fail "missing LF-008"
    sh tests/live-fire/LF-008-emergency-stop-command-gate.sh || fail "LF-008 failed"
    [ -d docs/wiremudder/command-safety ] || fail "missing command-safety docs"
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-008 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-008 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-008 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-008 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-008 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-008" >/dev/null || fail "green/EP-008 tag missing"
    ok "EP-008 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

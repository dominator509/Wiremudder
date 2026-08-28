#!/usr/bin/env sh
# Node verifier for EP-021 World Brain, World Bible, and Time Machine.
set -eu

NODE=EP-021
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
    [ -f .agent/node-contracts/EP-021.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-021.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-021.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-021-$m.txt" ] || fail "missing milestone fence $m"
    done
    n=$(wc -l < .agent/state/source-evidence.jsonl | tr -d ' ')
    [ "$n" -ge 138 ] || fail "insufficient source evidence ($n records)"
    for f in WM-FEAT-0050 WM-FEAT-0051 WM-FEAT-0052 WM-FEAT-0053 WM-FEAT-0191 WM-FEAT-0192 WM-FEAT-0193 WM-FEAT-0194 WM-FEAT-0195; do
      grep -q "$f" .agent/node-contracts/EP-021.md || fail "owned $f missing from contract"
    done
    for r in WM-SPEC-012-R01 WM-SPEC-012-R08 WM-SPEC-012-R09 WM-SPEC-016-R02 WM-SPEC-016-R04 WM-SPEC-016-R07 WM-SPEC-023-R02; do
      grep -q "$r" .agent/node-contracts/EP-021.md || fail "owned $r missing from contract"
    done
    [ -d tests/wiremudder/ep021/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep021/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-021 >/dev/null || fail "scope audit"
    ok "EP-021 M1: ok"
    ;;
  M2)
    check_pinned_commit
    check_cargo
    for c in wire-world-brain wire-world-bible wire-time-machine; do
      [ -d "wirecore/crates/$c" ] || fail "missing $c crate"
    done
    [ -d schemas/wiremudder/memory ] || fail "missing memory schemas"
    [ -d tests/wiremudder/ep021/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep021/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-021 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep021/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep021/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/world-brain/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep021/integration/*.sh tests/wiremudder/ep021/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-021 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep021/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep021/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep021/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/world-brain/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep021/failure/*.sh tests/wiremudder/ep021/security/*.sh tests/wiremudder/ep021/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-021 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-021-world-memory-correction.sh ] || fail "missing LF-021"
    sh tests/live-fire/LF-021-world-memory-correction.sh || fail "LF-021 failed"
    [ -d docs/wiremudder/world-brain ] || fail "missing world-brain docs"
    for f in feature-0050 feature-0051 feature-0052 feature-0053 feature-0191 feature-0192 feature-0193 feature-0194 feature-0195; do
      [ -d "tests/wiremudder/ep021/$f" ] || fail "missing feature test dir $f"
      for t in tests/wiremudder/ep021/$f/*.sh; do
        [ -f "$t" ] || fail "no feature test in $f"
        sh "$t" || fail "feature test failed: $t"
      done
    done
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-021 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-021 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-021 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-021 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-021 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-021" >/dev/null || fail "green/EP-021 tag missing"
    ok "EP-021 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

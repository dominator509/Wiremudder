#!/usr/bin/env sh
# Node verifier for EP-017 Player Copilot, Explanations, and Confidence.
set -eu

NODE=EP-017
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
    [ -f .agent/node-contracts/EP-017.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-017.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-017.discovered.txt ] || fail "missing discovered amendment"
    # The copilot UI must be compiled into the client: the discovered
    # amendment MUST authorize the inherited build list (smallest integration
    # patch, execplan M1 goal). Zero-integration is a deviation, not a choice.
    grep -q '"path":"src/CMakeLists.txt"' .agent/expected-files/EP-017.discovered.txt \
      || fail "discovered amendment missing inherited build list (src/CMakeLists.txt)"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-017-$m.txt" ] || fail "missing milestone fence $m"
    done
    n=$(wc -l < .agent/state/source-evidence.jsonl | tr -d ' ')
    [ "$n" -ge 112 ] || fail "insufficient source evidence ($n records)"
    for r in WM-SPEC-014-R01 WM-SPEC-014-R03 WM-SPEC-014-R04 \
             WM-SPEC-014-R08 WM-SPEC-014-R09; do
      grep -q "$r" .agent/node-contracts/EP-017.md || fail "owned $r missing from contract"
    done
    [ -d tests/wiremudder/ep017/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep017/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-017 >/dev/null || fail "scope audit"
    ok "EP-017 M1: ok"
    ;;
  M2)
    check_pinned_commit
    [ -d wirecore/crates/wire-copilot ] || fail "missing wire-copilot crate"
    [ -d schemas/wiremudder/copilot ] || fail "missing copilot schemas"
    [ -d tests/wiremudder/ep017/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep017/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-017 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep017/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep017/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/copilot/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep017/integration/*.sh tests/wiremudder/ep017/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-017 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep017/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep017/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep017/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/copilot/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep017/failure/*.sh tests/wiremudder/ep017/security/*.sh tests/wiremudder/ep017/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-017 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-017-copilot-suggestion-explanation.sh ] || fail "missing LF-017"
    sh tests/live-fire/LF-017-copilot-suggestion-explanation.sh || fail "LF-017 failed"
    [ -d docs/wiremudder/copilot ] || fail "missing copilot docs"
    for f in tests/wiremudder/ep017/feature-0039 tests/wiremudder/ep017/feature-0040 \
             tests/wiremudder/ep017/feature-0046 tests/wiremudder/ep017/feature-0047; do
      [ -d "$f" ] || fail "missing feature test dir $f"
      for t in "$f"/*.sh; do
        [ -f "$t" ] || fail "no feature test in $f"
        sh "$t" || fail "feature test failed: $t"
      done
    done
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-017 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-017 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-017 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-017 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-017 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-017" >/dev/null || fail "green/EP-017 tag missing"
    ok "EP-017 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

#!/usr/bin/env sh
# Node verifier for EP-024 Ambient Voice Companion and Voice Macros.
set -eu

NODE=EP-024
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
    [ -f .agent/node-contracts/EP-024.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-024.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-024.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-024-$m.txt" ] || fail "missing milestone fence $m"
    done
    for c in src/wiremudder/ui/voice/ wirecore/crates/wire-voice/ schemas/wiremudder/voice/ config/wiremudder/voice/; do
      grep -q "$c" .agent/node-contracts/EP-024.md || fail "authorized boundary $c missing from contract"
    done
    for f in WM-FEAT-0057 WM-FEAT-0058 WM-FEAT-0059 WM-FEAT-0060 WM-FEAT-0061 \
             WM-FEAT-0062 WM-FEAT-0063 WM-FEAT-0064 WM-FEAT-0065 WM-FEAT-0066 \
             WM-FEAT-0067 WM-FEAT-0068 WM-FEAT-0186 WM-FEAT-0211 WM-FEAT-0212; do
      grep -q "$f" .agent/node-contracts/EP-024.md || fail "owned $f missing from contract"
    done
    for r in WM-SPEC-007-R02 WM-SPEC-010-R08 WM-SPEC-015-R07 WM-SPEC-015-R10; do
      grep -q "$r" .agent/node-contracts/EP-024.md || fail "owned $r missing from contract"
    done
    [ -d tests/wiremudder/ep024/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep024/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-024 >/dev/null || fail "scope audit"
    ok "EP-024 M1: ok"
    ;;
  M2)
    check_pinned_commit
    check_cargo
    [ -d wirecore/crates/wire-voice ] || fail "missing wire-voice crate"
    [ -d schemas/wiremudder/voice ] || fail "missing voice schemas"
    [ -d config/wiremudder/voice ] || fail "missing voice config"
    [ -d tests/wiremudder/ep024/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep024/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-024 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep024/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep024/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/voice/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep024/integration/*.sh tests/wiremudder/ep024/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-024 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep024/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep024/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep024/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/voice/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep024/failure/*.sh tests/wiremudder/ep024/security/*.sh tests/wiremudder/ep024/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-024 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-024-voice-privacy-command.sh ] || fail "missing LF-024"
    sh tests/live-fire/LF-024-voice-privacy-command.sh || fail "LF-024 failed"
    [ -d docs/wiremudder/voice ] || fail "missing voice docs"
    for f in feature-0057 feature-0058 feature-0059 feature-0060 feature-0061 \
             feature-0062 feature-0063 feature-0064 feature-0065 feature-0066 \
             feature-0067 feature-0068 feature-0186 feature-0211 feature-0212; do
      [ -d "tests/wiremudder/ep024/$f" ] || fail "missing feature test dir $f"
      for t in tests/wiremudder/ep024/$f/*.sh; do
        [ -f "$t" ] || fail "no feature test in $f"
        sh "$t" || fail "feature test failed: $t"
      done
    done
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-024 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-024 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-024 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-024 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-024 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-024" >/dev/null || fail "green/EP-024 tag missing"
    ok "EP-024 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

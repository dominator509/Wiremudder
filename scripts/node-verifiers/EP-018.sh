#!/usr/bin/env sh
# Node verifier for EP-018 Soul, Agent Council, Skills, and Memory Permissions.
set -eu

NODE=EP-018
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
    [ -f .agent/node-contracts/EP-018.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-018.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-018.discovered.txt ] || fail "missing discovered amendment"
    # The Soul UI must be compiled into the client: the discovered amendment
    # MUST authorize the inherited build list (smallest integration patch).
    grep -q '"path":"src/CMakeLists.txt"' .agent/expected-files/EP-018.discovered.txt \
      || fail "discovered amendment missing inherited build list (src/CMakeLists.txt)"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-018-$m.txt" ] || fail "missing milestone fence $m"
    done
    n=$(wc -l < .agent/state/source-evidence.jsonl | tr -d ' ')
    [ "$n" -ge 118 ] || fail "insufficient source evidence ($n records)"
    for r in WM-SPEC-014-R02 WM-SPEC-014-R05 WM-SPEC-014-R06 WM-SPEC-014-R07; do
      grep -q "$r" .agent/node-contracts/EP-018.md || fail "owned $r missing from contract"
    done
    [ -d tests/wiremudder/ep018/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep018/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-018 >/dev/null || fail "scope audit"
    ok "EP-018 M1: ok"
    ;;
  M2)
    check_pinned_commit
    [ -d wirecore/crates/wire-agents ] || fail "missing wire-agents crate"
    [ -d wirecore/crates/wire-soul ] || fail "missing wire-soul crate"
    [ -d schemas/wiremudder/agents ] || fail "missing agents schemas"
    [ -d tests/wiremudder/ep018/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep018/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-018 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d tests/wiremudder/ep018/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep018/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/agents/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep018/integration/*.sh tests/wiremudder/ep018/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-018 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep018/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep018/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep018/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/agents/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep018/failure/*.sh tests/wiremudder/ep018/security/*.sh tests/wiremudder/ep018/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-018 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_cargo
    [ -f tests/live-fire/LF-018-soul-agent-permission.sh ] || fail "missing LF-018"
    sh tests/live-fire/LF-018-soul-agent-permission.sh || fail "LF-018 failed"
    [ -d docs/wiremudder/agents ] || fail "missing agents docs"
    for f in tests/wiremudder/ep018/feature-0042 tests/wiremudder/ep018/feature-0043 \
             tests/wiremudder/ep018/feature-0044 tests/wiremudder/ep018/feature-0045 \
             tests/wiremudder/ep018/feature-0181 tests/wiremudder/ep018/feature-0182; do
      [ -d "$f" ] || fail "missing feature test dir $f"
      for t in "$f"/*.sh; do
        [ -f "$t" ] || fail "no feature test in $f"
        sh "$t" || fail "feature test failed: $t"
      done
    done
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-018 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-018 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-018 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-018 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-018 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-018" >/dev/null || fail "green/EP-018 tag missing"
    ok "EP-018 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

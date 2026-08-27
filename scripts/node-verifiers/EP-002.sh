#!/usr/bin/env sh
# Node verifier for EP-002 Fork Governance, Upstream Sync, and Branding.
set -eu

NODE=EP-002
fail() { echo "node verifier $NODE: FAIL - $1" >&2; exit 1; }
ok() { echo "$1"; exit 0; }

require_env() {
  [ -f .env ] || fail "missing .env"
  set -a; . ./.env; set +a
}
check_remotes() {
  upstream=$(git config --get remote.upstream.url || true)
  origin=$(git config --get remote.origin.url || true)
  case "$upstream" in
    https://github.com/Mudlet/Mudlet.git|git@github.com:Mudlet/Mudlet.git) ;;
    *) fail "upstream remote is not Mudlet: $upstream" ;;
  esac
  case "$origin" in
    https://github.com/dominator509/WireMudder.git|git@github.com:dominator509/WireMudder.git) ;;
    *) fail "origin remote is not dominator509/WireMudder: $origin" ;;
  esac
}
check_pinned_commit() {
  require_env
  commit=${WIREMUDDER_UPSTREAM_COMMIT:-}
  git cat-file -e "$commit^{commit}" 2>/dev/null || fail "pinned commit missing"
  git merge-base --is-ancestor "$commit" HEAD || fail "pinned commit not ancestor"
}

case "${1:-}" in
  M1)
    check_pinned_commit
    check_remotes
    [ -f .agent/node-contracts/EP-002.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-002.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-002.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-002-$m.txt" ] || fail "missing milestone fence $m"
    done
    n=$(wc -l < .agent/state/source-evidence.jsonl | tr -d ' ')
    [ "$n" -ge 36 ] || fail "insufficient source evidence ($n records)"
    for f in WM-FEAT-0148 WM-FEAT-0149 WM-FEAT-0160 WM-SPEC-001-R04 WM-SPEC-001-R07; do
      grep -q "$f" .agent/node-contracts/EP-002.md || fail "owned $f missing from contract"
    done
    [ -d tests/wiremudder/ep002/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep002/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-002 >/dev/null || fail "scope audit"
    ok "EP-002 M1: ok"
    ;;
  M2)
    check_pinned_commit
    check_remotes
    [ -f LICENSE_STRATEGY.md ] || fail "missing LICENSE_STRATEGY.md"
    [ -f UPSTREAM_SYNC_POLICY.md ] || fail "missing UPSTREAM_SYNC_POLICY.md"
    [ -f BRANDING_POLICY.md ] || fail "missing BRANDING_POLICY.md"
    [ -d docs/wiremudder/upstream ] || fail "missing upstream docs"
    [ -d tests/wiremudder/ep002/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep002/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-002 M2: ok"
    ;;
  M3)
    check_pinned_commit
    check_remotes
    [ -d tests/wiremudder/ep002/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep002/e2e ] || fail "missing e2e tests"
    [ -d docs/wiremudder/upstream/design ] || fail "missing design docs"
    for t in tests/wiremudder/ep002/integration/*.sh tests/wiremudder/ep002/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-002 M3: ok"
    ;;
  M4)
    [ -d tests/wiremudder/ep002/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep002/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep002/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/upstream/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep002/failure/*.sh tests/wiremudder/ep002/security/*.sh tests/wiremudder/ep002/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-002 M4: ok"
    ;;
  M5)
    check_pinned_commit
    check_remotes
    [ -f tests/live-fire/LF-002-upstream-sync-drill.sh ] || fail "missing LF-002"
    sh tests/live-fire/LF-002-upstream-sync-drill.sh || fail "LF-002 failed"
    [ -d docs/wiremudder/upstream ] || fail "missing upstream docs"
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-002 M5: ok"
    ;;
  verify)
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-002 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-002 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-002 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-002 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-002" >/dev/null || fail "green/EP-002 tag missing"
    ok "EP-002 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

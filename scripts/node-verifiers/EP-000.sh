#!/usr/bin/env sh
# Node verifier for EP-000 Upstream Discovery and Evidence Lock.
# Each subcommand runs real checks against the repository and prints its
# exact sentinel only on success. Never edits production code.
set -eu

NODE=EP-000
fail() { echo "node verifier $NODE: FAIL - $1" >&2; exit 1; }
ok() { echo "$1"; exit 0; }

# --- shared helpers -------------------------------------------------------
require_env() {
  [ -f .env ] || fail "missing .env"
  set -a; . ./.env; set +a
}
require_clean_inherited() {
  # No inherited (Mudlet) source may be modified by this node.
  dirty=$(git status --porcelain -- src/ 2>/dev/null || true)
  [ -z "$dirty" ] || fail "inherited src/ modified: $dirty"
}
check_pinned_commit() {
  require_env
  commit=${WIREMUDDER_UPSTREAM_COMMIT:-}
  [ -n "$commit" ] || fail "WIREMUDDER_UPSTREAM_COMMIT empty"
  git cat-file -e "$commit^{commit}" 2>/dev/null || fail "pinned commit $commit missing"
  git merge-base --is-ancestor "$commit" HEAD || fail "pinned commit not ancestor of HEAD"
}

case "${1:-}" in
  M1)
    # Evidence, contracts, and exact path lock.
    check_pinned_commit
    require_clean_inherited
    [ -f .agent/node-contracts/EP-000.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-000.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-000.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-000-$m.txt" ] || fail "missing milestone fence $m"
    done
    [ -f .agent/state/source-evidence.jsonl ] || fail "missing source-evidence ledger"
    n=$(wc -l < .agent/state/source-evidence.jsonl | tr -d ' ')
    [ "$n" -ge 10 ] || fail "insufficient source evidence ($n records)"
    # Every owned feature and requirement must appear in the node contract.
    grep -q 'WM-FEAT-0147' .agent/node-contracts/EP-000.md || fail "feature WM-FEAT-0147 missing from contract"
    grep -q 'WM-FEAT-0150' .agent/node-contracts/EP-000.md || fail "feature WM-FEAT-0150 missing from contract"
    grep -q 'WM-SPEC-000-R02' .agent/node-contracts/EP-000.md || fail "requirement R02 missing from contract"
    grep -q 'WM-SPEC-001-R10' .agent/node-contracts/EP-000.md || fail "requirement R10 missing from contract"
    # Contract tests must exist and pass.
    [ -d tests/wiremudder/ep000/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep000/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    # Scope audit must pass for M1 (lease base is in the ledger).
    sh scripts/scope-audit.sh EP-000 >/dev/null || fail "scope audit"
    ok "EP-000 M1: ok"
    ;;
  M2)
    # Core behavior: upstream tree inventory, command lock, unit tests.
    check_pinned_commit
    [ -f .agent/state/upstream-tree.tsv ] || fail "missing upstream-tree.tsv"
    [ -s .agent/state/upstream-tree.tsv ] || fail "empty upstream-tree.tsv"
    [ -f .agent/state/COMMANDS.lock.tsv ] || fail "missing COMMANDS.lock.tsv"
    [ -s .agent/state/COMMANDS.lock.tsv ] || fail "empty COMMANDS.lock.tsv"
    sh scripts/command-lock-check.sh >/dev/null || fail "command lock check"
    [ -d tests/wiremudder/ep000/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep000/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-000 M2: ok"
    ;;
  M3)
    # Real integration: upstream docs, discovery design, integration/e2e tests.
    check_pinned_commit
    [ -d docs/upstream ] || fail "missing docs/upstream"
    [ -d docs/wiremudder/discovery/design ] || fail "missing discovery design docs"
    [ -d tests/wiremudder/ep000/integration ] || fail "missing integration tests"
    [ -d tests/wiremudder/ep000/e2e ] || fail "missing e2e tests"
    for t in tests/wiremudder/ep000/integration/*.sh tests/wiremudder/ep000/e2e/*.sh; do
      [ -f "$t" ] || fail "no integration/e2e tests found"
      sh "$t" || fail "integration/e2e test failed: $t"
    done
    ok "EP-000 M3: ok"
    ;;
  M4)
    # Forced failures, abuse cases, performance, operations.
    [ -d tests/wiremudder/ep000/failure ] || fail "missing failure tests"
    [ -d tests/wiremudder/ep000/security ] || fail "missing security tests"
    [ -d tests/wiremudder/ep000/performance ] || fail "missing performance tests"
    [ -d docs/wiremudder/discovery/operations ] || fail "missing operations docs"
    for t in tests/wiremudder/ep000/failure/*.sh tests/wiremudder/ep000/security/*.sh tests/wiremudder/ep000/performance/*.sh; do
      [ -f "$t" ] || fail "no M4 tests found"
      sh "$t" || fail "M4 test failed: $t"
    done
    ok "EP-000 M4: ok"
    ;;
  M5)
    # Live-fire, evidence closure, green tag readiness.
    check_pinned_commit
    [ -f tests/live-fire/LF-000-upstream-baseline-discovery.sh ] || fail "missing LF-000"
    sh tests/live-fire/LF-000-upstream-baseline-discovery.sh || fail "LF-000 failed"
    [ -d docs/wiremudder/discovery ] || fail "missing discovery docs"
    sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
    sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"
    ok "EP-000 M5: ok"
    ;;
  verify)
    # Full node completion checks (node_verify.py calls this after milestones).
    for m in M1 M2 M3 M4 M5; do
      sh "$0" "$m" >/dev/null || fail "subcommand $m"
    done
    sh scripts/authority-check.sh >/dev/null || fail "authority check"
    sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check"
    sh scripts/discovered-path-check.sh EP-000 >/dev/null || fail "discovered path check"
    sh scripts/node-contract-check.sh EP-000 >/dev/null || fail "node contract check"
    sh scripts/expected-files-audit.sh EP-000 >/dev/null || fail "expected files audit"
    sh scripts/scope-audit.sh EP-000 >/dev/null || fail "scope audit"
    grep -q 'NODE_DONE' .agent/state/LEDGER.md || fail "NODE_DONE not in ledger"
    git rev-parse -q --verify "refs/tags/green/EP-000" >/dev/null || fail "green/EP-000 tag missing"
    ok "EP-000 verify: ok"
    ;;
  *)
    echo "usage: $0 M1|M2|M3|M4|M5|verify" >&2; exit 2
    ;;
esac

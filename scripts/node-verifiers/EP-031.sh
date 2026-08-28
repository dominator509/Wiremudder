#!/usr/bin/env sh
# EP-031 Accessibility, Localization, and UX Hardening - node verifier.
# Each subcommand runs real checks and prints only its exact sentinel.
set -eu

cd "$(dirname "$0")/../.."

fail() { echo "EP-031 verify: FAIL - $1" >&2; exit 1; }
ok() { echo "$1"; exit 0; }

check_pinned_commit() {
  [ -f .env ] || fail "missing .env"
  set -a; . ./.env; set +a
  commit=${WIREMUDDER_UPSTREAM_COMMIT:-}
  git cat-file -e "$commit^{commit}" 2>/dev/null || fail "pinned commit missing"
  git merge-base --is-ancestor "$commit" HEAD || fail "pinned commit not ancestor"
}

case "${1:-}" in
  M1)
    check_pinned_commit
    [ -f .agent/node-contracts/EP-031.md ] || fail "missing node contract"
    [ -f .agent/expected-files/EP-031.txt ] || fail "missing static fence"
    [ -f .agent/expected-files/EP-031.discovered.txt ] || fail "missing discovered amendment"
    for m in M1 M2 M3 M4 M5; do
      [ -f ".agent/milestone-files/EP-031-$m.txt" ] || fail "missing milestone fence $m"
    done
    for b in src/wiremudder/accessibility/ tests/wiremudder/accessibility/ \
             docs/wiremudder/accessibility/ translations/wiremudder/; do
      grep -q "$b" .agent/node-contracts/EP-031.md || fail "authorized boundary $b missing from contract"
    done
    grep -q "WM-SPEC-007-R10" .agent/node-contracts/EP-031.md || fail "owned WM-SPEC-007-R10 missing from contract"
    grep -q '"path":"src/CMakeLists.txt"' .agent/expected-files/EP-031.discovered.txt \
      || fail "discovered amendment missing src/CMakeLists.txt"
    [ -d tests/wiremudder/ep031/contract ] || fail "missing contract tests"
    for t in tests/wiremudder/ep031/contract/*.sh; do
      [ -f "$t" ] || fail "no contract tests found"
      sh "$t" || fail "contract test failed: $t"
    done
    sh scripts/scope-audit.sh EP-031 >/dev/null || fail "scope audit"
    ok "EP-031 M1: ok"
    ;;
  M2)
    check_pinned_commit
    [ -d src/wiremudder/accessibility ] || fail "missing accessibility boundary"
    [ -d translations/wiremudder ] || fail "missing translations boundary"
    [ -d tests/wiremudder/ep031/unit ] || fail "missing unit tests"
    for t in tests/wiremudder/ep031/unit/*.sh; do
      [ -f "$t" ] || fail "no unit tests found"
      sh "$t" || fail "unit test failed: $t"
    done
    ok "EP-031 M2: ok"
    ;;
  M3)
    check_pinned_commit
    [ -d src/wiremudder/accessibility ] || fail "missing accessibility boundary"
    grep -q "wiremudder/accessibility/accessibility_boundary.cpp" src/CMakeLists.txt \
      || fail "accessibility boundary not wired into CMakeLists"
    for t in tests/wiremudder/ep031/integration/*.sh; do
      [ -f "$t" ] || fail "no integration tests found"
      sh "$t" || fail "integration test failed: $t"
    done
    ok "EP-031 M3: ok"
    ;;
  M4)
    check_pinned_commit
    [ -d tests/wiremudder/ep031/failure ] || fail "missing failure tests"
    for t in tests/wiremudder/ep031/failure/*.sh; do
      [ -f "$t" ] || fail "no failure tests found"
      sh "$t" || fail "failure test failed: $t"
    done
    [ -d tests/wiremudder/ep031/security ] || fail "missing security tests"
    for t in tests/wiremudder/ep031/security/*.sh; do
      [ -f "$t" ] || fail "no security tests found"
      sh "$t" || fail "security test failed: $t"
    done
    [ -f docs/wiremudder/accessibility/operations.md ] || fail "missing operations runbook"
    ok "EP-031 M4: ok"
    ;;
  M5)
    check_pinned_commit
    [ -f tests/live-fire/LF-031-accessibility-keyboard-screenreader.sh ] \
      || fail "missing LF-031 live-fire script"
    sh tests/live-fire/LF-031-accessibility-keyboard-screenreader.sh || fail "LF-031 failed"
    [ -d tests/wiremudder/ep031/features ] || fail "missing feature tests"
    [ -d tests/wiremudder/ep031/requirements ] || fail "missing requirement tests"
    for d in features requirements; do
      for t in tests/wiremudder/ep031/$d/*.sh; do
        [ -f "$t" ] || fail "no $d tests found"
        sh "$t" || fail "$d test failed: $t"
      done
    done
    sh scripts/expected-files-audit.sh EP-031 >/dev/null || fail "expected-files audit"
    sh scripts/scope-audit.sh EP-031 >/dev/null || fail "scope audit"
    ok "EP-031 M5: ok"
    ;;
  *)
    fail "unknown subcommand ${1:-<none>}"
    ;;
esac

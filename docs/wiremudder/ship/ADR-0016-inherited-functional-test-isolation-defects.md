# ADR-0016: Inherited functional-test isolation defects surfaced by the first full unit gate run

## Status

Accepted during EP-039 M1 gate wiring.

## Context and Evidence

The run-level unit gate (`ctest --preset linux-debug-nosan`, locked as `unit` from
WM-SRC-000019) executes the 110-test CTest suite. EP-039 is the first node to run
the full chain end to end: the 12 ship-gate commands were not previously locked,
so verify.sh never reached the unit gate. Provisioning the runtime prerequisites
(Xvfb display for the Qt xcb plugin; lua-yajl, luautf8, LuaFileSystem, lpeg,
lua-zip, lrexlib-pcre2 via luarocks per `CI/linux.install.sh` and the Flatpak
manifest) brings the suite to 107/110 passing.

Three tests fail deterministically or intermittently, all unchanged from the
pinned upstream commit `77086c295f4adf59197e586e689d19bdde8e1008`:

1. `ScriptEventHandlerLifetimeTest::testRenamingASelectedHandlerStillWorks`
   - Fails only when run after `testAddingAScriptDropsTheNotedHandler` in the
     same binary; passes in isolation and when run first.
   - Failure: `savedHandlersOf(pScript)` size 0, expected `{renamedEvent}`.
2. `ScriptEventHandlerLifetimeTest::testDeletingAHandlerReleasesIt`
   - Same test-order dependency; passes in isolation.
   - Failure: `savedHandlersOf(pScript)` size 0, expected `{secondEvent}`.
3. TOscTest — flaky in isolation across several buffer-asserting cases
   - Observed failing cases (real runs, `DISPLAY=:99 LUA_CPATH=...`):
     `test_OscTextDisplay(BEL-terminated OSC 2 (window title))` (multiple runs),
     `test_FindNextLink_SkipsCurrentLink()`, `test_FindNextLink_NoLinks()`.
   - Root cause captured in failure output: an asynchronous `[ MPKG ] - New
     version of mpkg found. Automatically upgrading to 3.5` + `[ MPKG ] - mpkg
     package removed.` notification lands in the TBuffer before the test's
     assertion, so `allText.trimmed()` is `"Hello World[ MPKG ] ..."` instead of
     the expected `"Hello World"`. The mpkg background poll is unrelated to the
     OSC/link code under test. Observed frequency: 9 of 27 fully-documented
     full-binary isolation runs failed (33%); the failing case varies run to
     run, plus one additional failing run captured as root-cause evidence.

Replacement evidence: the ScriptEventHandlerLifetimeTest cases each pass when
executed in isolation (real runs: 3 passed, 0 failed each), and the TOscTest
failures are proven to be mpkg-notification pollution by the captured failure
output (the same code path passes when the poll does not land). Examples:
`DISPLAY=:99 LUA_CPATH="/root/.luarocks/lib/lua/5.1/?.so;/root/.luarocks/lib/lua/5.1/?/?.so;;" build-linux-debug-nosan/test/functional_tests/ScriptEventHandlerLifetimeTest testRenamingASelectedHandlerStillWorks` → 3 passed, 0 failed (exit 0).

## Decision

Record the inherited suite-isolation defects as a known risk (SPEC-028-R03) with
ADR authorization rather than weakening, deleting, or retrying the unit gate
(WM-SPEC-027-R09/R10 forbid retry-until-green and gate weakening). The failing
cases are upstream-inherited and byte-identical to the pinned commit; EP-039 is
not authorized to modify `test/functional_tests/` (not in EP-039 fence; the
discovered amendment requires an independent test path and the change would be a
product-behavior fix owned by the editor node, not the ship node). The gate
continues to run the full suite; the failures are recorded with evidence and the
blocking analysis is reported to the run gate.

## Alternatives

- Fix the editor state leak in `dlgTriggerEditor` (rename/delete handler
  persistence after prior-test teardown): rejected, out of EP-039 scope, would
  touch inherited editor code without node ownership, and the test-order
  dependency is upstream behavior not a regression introduced by any WireMudder
  node.
- Weaken the unit gate to exclude the three tests: rejected, WM-SPEC-027-R10.
- Retry until green: rejected, WM-SPEC-027-R09.

## Consequences

The fresh ship gate records 107/110 ctest passing with three documented
inherited failures and per-case isolation evidence. RUN_COMPLETE and the release
tag remain blocked until the ship gate's own acceptance is decided with the
recorded evidence; production is not deployed.

## Security and Privacy

No credentials, keys, or personal data are exposed by these test failures; logs
are redacted per existing evidence rules.

## Compatibility and Upstream Impact

No code change; pinned upstream behavior preserved. A fix would be an upstream
contribution candidate for the Mudlet project (generic fix assessed per
WM-SPEC-028-R09).

## Performance

No performance impact; the suite runtime is dominated by the 70 functional
tests and is unchanged.

## Migration and Rollback

No migration. Rollback: revert ADR file; the gate behavior is unchanged.

## Affected Features, Requirements, and Nodes

- Requirements: WM-SPEC-027-R09, WM-SPEC-028-R03
- Nodes: EP-039 (gate wiring; ship gate)
- Tests: ScriptEventHandlerLifetimeTest (2 cases), TOscTest (1 case)

## Verification

- Isolation pass: each failing test passes alone under the provisioned
  environment (commands above).
- Full suite: 107/110 pass; the three failures reproduce deterministically
  (2) or intermittently (1) in sequence.
- Evidence recorded in `.agent/state/evidence/EP-039/M1/`.

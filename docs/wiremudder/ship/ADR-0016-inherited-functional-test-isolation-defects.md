# ADR-0016: Inherited functional-test isolation defects surfaced by the first full unit gate run

## Status

Accepted during EP-039 M1 gate wiring (updated after the first complete gate runs).

## Context and Evidence

The run-level unit gate (`ctest --preset linux-debug-nosan`, locked as `unit` from
WM-SRC-000019) executes the 110-test CTest suite. EP-039 is the first node to run
the full chain end to end: the 12 ship-gate commands were not previously locked,
so verify.sh never reached the unit gate. Provisioning the runtime prerequisites
(Xvfb display for the Qt xcb plugin; lua-yajl, luautf8, LuaFileSystem, lpeg,
lua-zip, lrexlib-pcre2 via luarocks per `CI/linux.install.sh` and the Flatpak
manifest; pcre2grep via `pcre2-utils` because `run_locked_command.py` sets
`CI=true` and the inherited `ReleaseTagVersionTest` treats a missing pcre2grep on
CI as a broken runner) brings the suite to 106/110 passing with two deterministic
failures and two intermittent failures.

All failing tests are byte-identical to the pinned upstream commit
`77086c295f4adf59197e586e689d19bdde8e1008` (verified `git diff --stat` empty for
each test file), and the production code paths involved (`src/Host.cpp`,
`src/Host.h`, `src/TAction.cpp`, `src/TAction.h`) are also byte-identical to the
pin. Upstream has since fixed this exact failure class in later commits that are
NOT ancestors of the pin: `1d607d0f` (#9977 "functional tests no longer abort at
random during profile setup"), `d681e335` (#9995 ephemeral ports), `a0606d54`
(#10012 per-test config directories), `e4d002ac` (#10017 single functional-test
executable), `11b4105d` (#10020 portable-mode config isolation). The failures are
therefore inherited environment-exposed races, not WireMudder regressions.

Four test classes fail deterministically or intermittently:

1. `ScriptEventHandlerLifetimeTest::testRenamingASelectedHandlerStillWorks`
   - Fails only when run after `testAddingAScriptDropsTheNotedHandler` in the
     same binary; passes in isolation and when run first.
   - Failure: `savedHandlersOf(pScript)` size 0, expected `{renamedEvent}`.
   - Deterministic: 2/2 full-binary runs failed in sequence; isolation passes 3/3.
2. `ScriptEventHandlerLifetimeTest::testDeletingAHandlerReleasesIt`
   - Same test-order dependency; passes in isolation (3/3).
   - Failure: `savedHandlersOf(pScript)` size 0, expected `{secondEvent}`.
3. `ActionSelfRemovalTest::test_selfUninstallingButtonDoesNotCrash`
   - Deterministic: fails 5/5 offscreen and 3/3 xcb (8/8 total).
   - Root cause captured in output: the button's `uninstallPackage()` script
     triggers `Host::slot_saveProfileAfterPackageChange()`, which logs
     `WARNING - couldn't save 'Test-ActionSelfRemoval' ... because: profile
     loading is in progress`; the failed save surfaces as a "Lua error" in the
     buffer and the test's `!bufferContains("Lua error")` assertion fails.
     Profile boot and the immediate `TAction::execute()` race on the
     not-yet-complete load; upstream #9977/#10012/#10017 fix this class.
4. TOscTest — flaky in isolation across several buffer-asserting cases
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
5. `ProfileRoundTripTest` — flaky in isolation
   - Fails intermittently (2 of 8 offscreen isolation runs) in `initTestCase`
     with `'saved' returned FALSE. (a save is already in progress)` at
     `Host::saveProfile` (Host.cpp:1064 guard). Profile boot autosave and the
     test's explicit save race; the same boot-timing class as #9977/#10012.
   - Passes 3/3 under xcb in the sampled runs and 6/8 offscreen.

Note: `ReleaseTagVersionTest` initially failed in the full gate run for the same
CI-flag reason (missing pcre2grep under `CI=true`), and is NOT part of this ADR:
it passes 3/3 under `CI=true` once pcre2grep is provisioned (real runs recorded).
Similarly the earlier M1 report's "107/110" predates the complete runs; the
verified current steady-state is 106/110 with the four classes above.

Replacement evidence: the ScriptEventHandlerLifetimeTest cases each pass when
executed in isolation (real runs: 3 passed, 0 failed each), and the TOscTest
failures are proven to be mpkg-notification pollution by the captured failure
output (the same code path passes when the poll does not land). Examples:
`DISPLAY=:99 LUA_CPATH="/root/.luarocks/lib/lua/5.1/?.so;/root/.luarocks/lib/lua/5.1/?/?.so;;" build-linux-debug-nosan/test/functional_tests/ScriptEventHandlerLifetimeTest testRenamingASelectedHandlerStillWorks` → 3 passed, 0 failed (exit 0).
All captured in `.agent/state/evidence/EP-039/M1/adr0016-*`.

## Decision

Record the inherited suite-isolation defects as a known risk (SPEC-028-R03) with
ADR authorization rather than weakening, deleting, or retrying the unit gate
(WM-SPEC-027-R09/R10 forbid retry-until-green and gate weakening). The failing
cases are upstream-inherited and byte-identical to the pinned commit, with the
production code byte-identical as well and the failure class fixed upstream only
after the pin; EP-039 is not authorized to modify `test/functional_tests/` (not
in EP-039 fence; the discovered amendment requires an independent test path and
the change would be a product-behavior fix owned by the editor node, not the
ship node). The gate continues to run the full suite; the failures are recorded
with evidence and the blocking analysis is reported to the run gate.

## Alternatives

- Fix the editor state leak in `dlgTriggerEditor` (rename/delete handler
  persistence after prior-test teardown): rejected, out of EP-039 scope, would
  touch inherited editor code without node ownership, and the test-order
  dependency is upstream behavior not a regression introduced by any WireMudder
  node.
- Cherry-pick the upstream infra fixes (#9977/#9995/#10012/#10017/#10020):
  rejected, they postdate the pinned commit and would change pinned test
  infrastructure and inherited code without a node owning the change; they are
  noted as the upstream resolution for a future pin bump.
- Weaken the unit gate to exclude the failing tests: rejected, WM-SPEC-027-R10.
- Retry until green: rejected, WM-SPEC-027-R09.

## Consequences

The fresh ship gate records 106/110 ctest passing with two deterministic and two
intermittent inherited failures and per-case isolation evidence. RUN_COMPLETE and
the release tag remain blocked until the ship gate's own acceptance is decided
with the recorded evidence; production is not deployed.

## Security and Privacy

No credentials, keys, or personal data are exposed by these test failures; logs
are redacted per existing evidence rules.

## Compatibility and Upstream Impact

No code change; pinned upstream behavior preserved. The four failure classes are
all addressed by later upstream commits (#9977, #9995, #10012, #10017, #10020)
and should be revisited when the upstream pin is next bumped.

## Performance

No performance impact; the suite runtime is dominated by the 70 functional
tests and is unchanged.

## Migration and Rollback

No migration. Rollback: revert ADR file; the gate behavior is unchanged.

## Affected Features, Requirements, and Nodes

- Requirements: WM-SPEC-027-R09, WM-SPEC-028-R03
- Nodes: EP-039 (gate wiring; ship gate)
- Tests: ScriptEventHandlerLifetimeTest (2 cases), ActionSelfRemovalTest (1
  case), TOscTest (multiple cases), ProfileRoundTripTest (initTestCase)

## Verification

- Isolation passes: ScriptEventHandlerLifetimeTest cases pass alone under the
  provisioned environment (commands above); ActionSelfRemovalTest and
  ProfileRoundTripTest failures captured with root-cause output.
- Full suite: 106/110 pass; the four failures reproduce deterministically (2)
  or intermittently (2) in sequence.
- ReleaseTagVersionTest: 3/3 pass under `CI=true` after pcre2grep provisioning
  (not part of this ADR).
- Evidence recorded in `.agent/state/evidence/EP-039/M1/`.

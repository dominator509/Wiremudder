# Classic Parity Design (EP-009 M3)

## Architecture

```
fixtures (tests/wiremudder/classic/)
   |  JSON: reference_trace + wiremudder_trace + level
   v
parity_oracle.py (compatibility/classic/)
   |  validate -> sanitize check -> compare at exact|semantic|subset
   v
verdict: agree | disagree (exit 0/1)
```

## Integration Points

1. **Lua corpus** - `tests/wiremudder/ep009/integration/001-lua-corpus-live.sh`
   runs the real `lua5.1` interpreter against every `lua_eval` payload and
   asserts each `lua_result` matches. This grounds WM-SPEC-005-R06
   (Lua 5.1 behavior is a compatibility contract) in observed reality, not
   prose.
2. **Baseline build** - `002-mudlet-baseline-build.sh` verifies the built
   mudlet binary exists, is ELF64, links Qt6Core, and carries TConsole
   symbols (WM-SPEC-005-R01 baseline build obligation).
3. **E2E parity flow** - `001-parity-flow.sh` drives the full corpus
   through the oracle, proves degraded optional surfaces do not gate the
   manual command path, and proves oracle determinism across restarts.

## Observed Behavior (2026-08-27)

- `lua5.1 -e "t={'a','b'}; print(#t)"` -> `2` (array table length)
- `lua5.1 -e "t={a=1,b=2}; print(#t)"` -> `0` (hash table; corrected in
  fixture 001 - initial draft declared `2` from assumption, live run
  disproved it)
- Oracle: all 9 fixtures agree (8 semantic + 1 subset)

## Rollback

All artifacts are additive files under namespaced trees. Reverting the M3
commit removes them without touching inherited source. The oracle is
read-only over fixtures; no state is mutated.

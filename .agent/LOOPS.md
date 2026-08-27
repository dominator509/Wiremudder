# WireMudder Bounded Loops

## Run Loop

Run the boot sequence, ask the scheduler, lease or resume one node, complete or block it, then ask the scheduler again. The finite node count and terminal node loop make the run bounded.

## Node Loop

Execute milestones in order. Before each milestone, re-read its block, the node Non-goals, node contract, owning specs, milestone path file, and the last 20 ledger lines. After the last milestone, run node verify, expected-file audit, scope audit, append NODE_DONE, tag green, and release the lease.

## Milestone Verify-Fix Ladder

Maximum six total attempts unless the ExecPlan declares fewer.

1. First occurrence of a normalized signature: read full output, state one hypothesis, make the smallest targeted fix, rerun the narrowest failing command.
2. Second same signature: stop patching, create or run a narrower diagnostic, confirm or reject the hypothesis, then make one different targeted fix.
3. Third same signature or evidence that the approach is wrong: record discoveries and take the declared real fallback.
4. Fallback failure or budget exhaustion: roll back to the previous milestone commit and attempt the fallback once from clean state.
5. Remaining failure: append a complete NODE_BLOCKED report and terminate.

A new signature returns to rung one but does not reset the total attempt cap. The same diff or logical fix may not be applied twice.

## Readiness Loop

A started process has a PID or container ID, exact readiness command, bounded attempts, sleep interval, timeout, and kill command. Exhaustion becomes `READINESS_TIMEOUT_COMPONENT` and enters the ladder.

## Watchdogs

- Three identical command and output pairs force a rung climb.
- Ten actions without a ledger append require a HEARTBEAT.
- Every milestone runs scope audit and reverts unauthorized paths unless a prior evidence-backed amendment exists.
- Exceeding a declared budget enters the fallback rung.
- Queue, process, model, voice, renderer, import, update, and indexing work has cancellation and teardown.

## Brownfield Path Amendment

Static expected paths are authoritative. An inherited path may be added only to `.agent/expected-files/EP-XXX.discovered.txt` with the header fields node, source evidence ID, repository commit, rationale, test, and rollback. The amendment is written before the code edit and appears in the Decision Log and ledger. A directory-wide inherited path is forbidden unless the node contract explicitly proves why narrower paths are impossible.

## Lease

Acquire with `scripts/lease.sh acquire`. Append HEARTBEAT at least every 15 minutes and after each milestone. Release when stopping. A lease older than 90 minutes may be taken over only after re-running the last completed milestone sentinel and recording LEASE_TAKEOVER.

## Rollback

Rollback to the previous milestone commit or last completed green tag, never across a completed lower node. Append ROLLBACK with target and reason. Re-enter through the declared fallback.

## Blocked Report

The report names the exact blocker, commands, outputs, exit codes, signatures, hypotheses, attempted diffs, fallback, rollback, smallest human decision, recommended conservative default, affected features and requirements, data/security/performance impact, and safe resume command.

## Noninteractive Rule

Use the environment in COMMANDS.md. No editor, pager, REPL, watch mode, unbounded parallel build, prompt-on-conflict command, credential prompt, or background process without readiness and kill path is allowed.

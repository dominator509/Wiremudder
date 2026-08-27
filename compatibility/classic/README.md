# Inherited Classic Client Parity (compatibility/classic)

Compatibility oracle and fixture conventions for SPEC-005 / EP-009.

## Purpose

WireMudder preserves the pinned Mudlet-derived foundation. This tree is the
single source of truth for *what parity means*: how baseline semantic traces
are compared against WireMudder traces, and at what compatibility level.

## Compatibility Levels (SPEC-005 canonical terms)

- `exact` - event kinds, payloads, and order must be identical.
- `semantic` - normalized equivalence (whitespace/case/timing insensitive).
- `subset` - every reference event appears in order; WireMudder may add events.

No parity claim is accepted from compilation alone (WM-SPEC-005-R10).
Observable reference and WireMudder traces must agree under the declared level.

## Oracle

`python3 compatibility/classic/parity_oracle.py --compare FIXTURE.json`
`python3 compatibility/classic/parity_oracle.py --compare-all tests/wiremudder/classic`
`python3 compatibility/classic/parity_oracle.py --validate FIXTURE.json`

Exit 0 means agreement; exit 1 means disagreement or invalid fixture.

## Fixture Rules

1. Fixtures are JSON objects with `fixture_id`, `feature`, `spec`, `level`,
   `sanitized`, `reference_trace`, `wiremudder_trace`.
2. Reference traces encode verified inherited behavior (source evidence
   WM-SRC-000062..000076). WireMudder traces encode observed/expected
   WireMudder behavior.
3. Fixtures MUST be sanitized (SPEC-005: no user passwords, private
   messages, or private profiles).
4. `research_status: verified` means the reference behavior was confirmed
   from repository source; `reference-only` means the fixture is declared
   but not yet live-verified (explicit research status is allowed by the
   node contract acceptance obligation 1).

## Trees

- `compatibility/classic/` - oracle + conventions (this tree).
- `tests/wiremudder/classic/` - fixture corpus (ansi, automation, lua,
  mapper, logging).
- `docs/wiremudder/classic-parity/` - design and operations documentation.

## Rollback

The oracle is read-only over fixtures. Reverting any commit restores the
previous oracle behavior. Fixtures are additive; removing a fixture only
reduces coverage.

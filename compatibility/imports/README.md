# WireMudder Import Compatibility Corpus (EP-030)

Representative fixtures for import and migration testing
(WM-SPEC-021-R08). Each fixture is labeled with its class: clean, old,
malformed, partially corrupt, conflicting, oversized, or adversarial.
Mudlet XML fixtures are real parser inputs; the other formats are research
paths (WM-FEAT-0120) and are analyzed read-only.

## Fixtures

- `mudlet-clean-profile.xml` — clean Mudlet profile package (verified
  format, WM-SPEC-021-R01).
- `mudlet-malformed.xml` — malformed XML: unbalanced tags and unknown
  elements (must fail safely or report, WM-SPEC-021-R07/R09).
- `generic-json.json` — generic JSON research-path input.
- `generic-csv.csv` — generic CSV research-path input.
- `mushclient.xml` — MUSHclient-style research input.
- `tintin.tin` — TinTin++-style research input.
- `zmud-cmud.xml` — zMUD/CMUD-style research input.

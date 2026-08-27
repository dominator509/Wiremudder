#!/usr/bin/env python3
"""Parity Oracle for Inherited Classic Client Compatibility (EP-009).

Compares reference (baseline Mudlet-derived) semantic traces against
WireMudder traces under a declared compatibility level. Deterministic,
stdlib-only, no network. Used by tests/wiremudder/ep009/unit/* and
LF-009 live-fire.

Compatibility levels (SPEC-005 canonical terms):
  exact    - event kinds, payloads, and order must be identical.
  semantic - normalized equivalence: payload comparison ignores
             whitespace, case, and timing; event kinds and sequence
             must match.
  subset   - every reference event must appear in the WireMudder trace
             in order; WireMudder may add events.

Fixture schema (JSON):
  {
    "fixture_id": str,
    "feature": "WM-FEAT-XXXX",
    "spec": "WM-SPEC-XXX-RXX",
    "level": "exact|semantic|subset",
    "description": str,
    "sanitized": true,
    "research_status": "verified|reference-only",
    "reference_trace": [{"seq": int, "kind": str, "payload": ...}, ...],
    "wiremudder_trace": [{"seq": int, "kind": str, "payload": ...}, ...]
  }

Exit codes: 0 = all fixtures agree; 1 = disagreement or validation error;
2 = usage error.
"""
import json
import sys

REQUIRED_KEYS = {"fixture_id", "feature", "spec", "level", "sanitized",
                 "reference_trace", "wiremudder_trace"}
LEVELS = {"exact", "semantic", "subset"}
TRACE_KEYS = {"seq", "kind", "payload"}


def _normalize(value):
    """Normalize a payload for semantic comparison."""
    if isinstance(value, str):
        return " ".join(value.split()).lower()
    if isinstance(value, list):
        return [_normalize(v) for v in value]
    if isinstance(value, dict):
        return {k: _normalize(v) for k, v in value.items()}
    return value


def validate_fixture(fixture):
    """Return list of validation errors (empty == valid)."""
    errors = []
    missing = REQUIRED_KEYS - set(fixture.keys())
    if missing:
        errors.append(f"missing keys: {sorted(missing)}")
    if fixture.get("level") not in LEVELS:
        errors.append(f"invalid level: {fixture.get('level')!r}")
    if fixture.get("sanitized") is not True:
        errors.append("fixture must be sanitized (SPEC-005: no passwords/private data)")
    for key in ("reference_trace", "wiremudder_trace"):
        trace = fixture.get(key)
        if not isinstance(trace, list):
            errors.append(f"{key} must be a list")
            continue
        seen = set()
        for ev in trace:
            if not isinstance(ev, dict) or not TRACE_KEYS <= set(ev.keys()):
                errors.append(f"{key}: event missing {TRACE_KEYS - set(ev.keys()) if isinstance(ev, dict) else 'dict'}")
                continue
            if ev["seq"] in seen:
                errors.append(f"{key}: duplicate seq {ev['seq']}")
            seen.add(ev["seq"])
    return errors


def compare_traces(reference, wiremudder, level):
    """Return (agree: bool, reason: str)."""
    ref = sorted(reference, key=lambda e: e["seq"])
    wm = sorted(wiremudder, key=lambda e: e["seq"])

    if level == "exact":
        if len(ref) != len(wm):
            return False, f"exact: event count {len(ref)} != {len(wm)}"
        for r, w in zip(ref, wm):
            if r["kind"] != w["kind"]:
                return False, f"exact: kind {r['kind']!r} != {w['kind']!r} at seq {r['seq']}"
            if r["payload"] != w["payload"]:
                return False, f"exact: payload differs at seq {r['seq']}"
        return True, "exact match"

    if level == "semantic":
        ref_n = [(_normalize(e["kind"]), _normalize(e["payload"])) for e in ref]
        wm_n = [(_normalize(e["kind"]), _normalize(e["payload"])) for e in wm]
        if len(ref_n) != len(wm_n):
            return False, f"semantic: event count {len(ref_n)} != {len(wm_n)}"
        for i, (r, w) in enumerate(zip(ref_n, wm_n)):
            if r != w:
                return False, f"semantic: normalized mismatch at event {i}"
        return True, "semantic match"

    # subset: every reference event appears in order in the WireMudder trace
    it = iter(wm_n if False else wm)
    ref_it = iter(ref)
    try:
        r = next(ref_it)
        for w in wm:
            if (w["kind"] == r["kind"] and
                    _normalize(w["payload"]) == _normalize(r["payload"])):
                r = next(ref_it)
    except StopIteration:
        return True, "subset match"
    return False, f"subset: reference event {r['kind']!r} not found in order"


def main(argv):
    if len(argv) < 2:
        print(f"usage: {argv[0]} --validate FIXTURE.json", file=sys.stderr)
        print(f"       {argv[0]} --compare FIXTURE.json", file=sys.stderr)
        print(f"       {argv[0]} --compare-all DIR", file=sys.stderr)
        return 2

    mode = argv[1]
    if mode == "--validate":
        fixture = json.load(open(argv[2]))
        errors = validate_fixture(fixture)
        if errors:
            for e in errors:
                print(f"parity oracle: invalid - {e}")
            return 1
        print(f"parity oracle: valid {fixture['fixture_id']}")
        return 0

    if mode == "--compare":
        fixture = json.load(open(argv[2]))
        errors = validate_fixture(fixture)
        if errors:
            for e in errors:
                print(f"parity oracle: invalid - {e}")
            return 1
        agree, reason = compare_traces(fixture["reference_trace"],
                                       fixture["wiremudder_trace"],
                                       fixture["level"])
        if not agree:
            print(f"parity oracle: DISAGREE {fixture['fixture_id']}: {reason}")
            return 1
        print(f"parity oracle: agree {fixture['fixture_id']} ({reason})")
        return 0

    if mode == "--compare-all":
        import glob
        d = argv[2]
        files = sorted(glob.glob(f"{d}/**/*.json", recursive=True))
        if not files:
            print(f"parity oracle: no fixtures under {d}")
            return 1
        failed = 0
        for f in files:
            try:
                rc = main([argv[0], "--compare", f])
            except Exception as e:
                print(f"parity oracle: error {f}: {e}")
                rc = 1
            if rc != 0:
                failed += 1
        if failed:
            print(f"parity oracle: {failed}/{len(files)} fixtures failed")
            return 1
        print(f"parity oracle: all {len(files)} fixtures agree")
        return 0

    print(f"parity oracle: unknown mode {mode!r}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))

#!/usr/bin/env python3
"""Schema binding generator (EP-004).

Validates every canonical WireMudder schema, checks that it declares the
required meta fields, and generates a bindings manifest that downstream
nodes can consume. This is the generated-binding gate (SPEC-003).
"""
from __future__ import annotations
import json, sys
from pathlib import Path

SCHEMA_ROOT = Path(__file__).resolve().parent.parent.parent / 'schemas' / 'wiremudder'
OUT_MANIFEST = Path(__file__).resolve().parent.parent.parent / 'tools' / 'schema-bindings' / 'bindings.manifest.json'

REQUIRED_META = ('$id', '$schema', 'title', 'type')


def validate_schema(path: Path) -> dict:
    doc = json.loads(path.read_text(encoding='utf-8'))
    for key in REQUIRED_META:
        assert key in doc, f'{path}: missing {key}'
    # JSON Schema permits any root type; the transcript export is a
    # legitimate top-level array (EP-014). Accept object and array roots.
    assert doc['type'] in ('object', 'array'), f'{path}: unsupported root type {doc["type"]!r}'
    assert str(path).startswith(str(SCHEMA_ROOT)), f'{path}: outside schema root'
    return doc


def main() -> int:
    schemas = sorted(SCHEMA_ROOT.rglob('*.schema.json'))
    assert len(schemas) >= 6, f'expected >=6 schemas, found {len(schemas)}'
    manifest = []
    for s in schemas:
        doc = validate_schema(s)
        rel = str(s.relative_to(SCHEMA_ROOT.parent.parent))
        manifest.append({
            'path': rel,
            'id': doc['$id'],
            'title': doc['title'],
            'schema_version': doc.get('schema_version', doc.get('properties', {}).get('schema_version', {}).get('const', 'unversioned')),
        })
    OUT_MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    OUT_MANIFEST.write_text(json.dumps({'schemas': manifest, 'count': len(manifest)}, indent=2) + '\n', encoding='utf-8')
    print(f'schema-bindings: ok schemas={len(manifest)} manifest={OUT_MANIFEST.name}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

#!/usr/bin/env python3
"""Compatibility oracle session recorder.

Connects a real TCP client to a Protocol Museum fake MUD server,
captures the deterministic session as a sanitized replay document, and
writes it for differential comparison. This is the independent reference
harness (SPEC-019-R04/R07).
"""
from __future__ import annotations
import json, socket, subprocess, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT / 'compatibility' / 'protocol-museum'))
sys.path.insert(0, str(ROOT / 'compatibility' / 'framework'))

from museum import FakeMudServer, SCENARIOS  # noqa: E402
from sanitize import sanitize_replay  # noqa: E402


def capture(scenario: str, duration: float = 0.5) -> dict:
    if scenario not in SCENARIOS:
        raise ValueError(f'unknown scenario {scenario}')
    server = FakeMudServer(scenario, SCENARIOS[scenario]).start()
    events = []
    try:
        client = socket.create_connection(('127.0.0.1', server.port), timeout=5)
        client.settimeout(2)
        deadline = time.time() + duration
        buf = b''
        while time.time() < deadline:
            try:
                chunk = client.recv(4096)
            except socket.timeout:
                continue
            if not chunk:
                break
            buf += chunk
            # Split on telnet-agnostic newlines; record text lines.
            while b'\r\n' in buf or b'\n' in buf:
                if b'\r\n' in buf:
                    raw, buf = buf.split(b'\r\n', 1)
                else:
                    raw, buf = buf.split(b'\n', 1)
                if raw:
                    try:
                        text = raw.decode('utf-8', errors='replace')
                    except Exception:
                        text = repr(raw)
                    events.append({'seq': len(events) + 1, 't': round(time.time() * 1000), 'kind': 'line', 'direction': 'in', 'line': text})
        client.close()
    finally:
        server.stop()
    git_sha = subprocess.run(['git', 'rev-parse', 'HEAD'], stdout=subprocess.PIPE, text=True).stdout.strip()
    return {
        'schema_version': 1,
        'session_id': f'lmf-{scenario}-{int(time.time())}',
        'client_version': {'app': 'WireMudder-oracle', 'git_sha': git_sha},
        'profile': 'oracle',
        'world': f'protocol-museum-{scenario}',
        'events': events,
    }


def main() -> int:
    if len(sys.argv) != 3:
        print('usage: oracle_record.py SCENARIO OUT.json', file=sys.stderr)
        return 2
    scenario, out = sys.argv[1], sys.argv[2]
    try:
        doc = capture(scenario)
    except ValueError as exc:
        print(f'oracle record: FAIL - {exc}', file=sys.stderr)
        return 1
    doc = sanitize_replay(doc)
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    Path(out).write_text(json.dumps(doc, indent=2) + '\n', encoding='utf-8')
    print(f'oracle record: ok scenario={scenario} events={len(doc["events"])} out={out}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

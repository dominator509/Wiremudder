#!/usr/bin/env python3
"""Sanitization for session traces (SPEC-019-R05).

Strips secrets, player names, private message content, routing
credentials, and prompt text from replay fixtures deterministically.
"""
from __future__ import annotations
import re

SECRET_PATTERNS = [
    re.compile(r'\b(?:api[_-]?key|secret|password|token|private[_-]?key)\s*[=:]\s*\S+', re.I),
    re.compile(r'\b(?:bearer|authorization)\s*[:=]\s*\S+', re.I),
    # Bare scheme with a space-separated value, e.g. "Bearer zzzz".
    re.compile(r'\bbearer\s+[A-Za-z0-9._~+/=-]{4,}', re.I),
    re.compile(r'\bAKIA[0-9A-Z]{16}\b'),
    re.compile(r'-----BEGIN (?:RSA|OPENSSH|EC|PRIVATE) KEY-----'),
]

# Long runs of token-like characters are redacted regardless of keyword.
TOKEN_RUN = re.compile(r'\b[A-Za-z0-9_-]{24,}\b')

# Common in-world names that are treated as private player identifiers.
DEFAULT_PLAYER_NAMES = {'Dominic', 'Dominator', 'WireMudderTestPlayer', 'Probe'}


def sanitize_line(line: str, player_names: set[str] | None = None) -> str:
    out = line
    names = player_names if player_names is not None else DEFAULT_PLAYER_NAMES
    for name in names:
        out = re.sub(r'\b' + re.escape(name) + r'\b', '[PLAYER]', out)
    for pat in SECRET_PATTERNS:
        out = pat.sub(lambda m: m.group(0).split('=')[0] + '=[REDACTED]' if '=' in m.group(0) else '[REDACTED]', out)
    out = TOKEN_RUN.sub('[REDACTED]', out)
    return out


def sanitize_event(event: dict, player_names: set[str] | None = None) -> dict:
    out = dict(event)
    for field in ('line', 'command', 'prompt'):
        if field in out and isinstance(out[field], str):
            out[field] = sanitize_line(out[field], player_names)
    return out


def sanitize_replay(doc: dict, player_names: set[str] | None = None) -> dict:
    out = dict(doc)
    if 'events' in out and isinstance(out['events'], list):
        out['events'] = [sanitize_event(ev, player_names) for ev in out['events']]
    return out

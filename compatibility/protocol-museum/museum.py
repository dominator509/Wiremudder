#!/usr/bin/env python3
"""Protocol Museum fake MUD servers (SPEC-019-R08).

Controlled TCP servers that emit real protocol fixtures: negotiation,
text lines, malformed input, latency, and disconnect. Used by the
Compatibility Lab oracle to produce deterministic session traces.
"""
from __future__ import annotations
import socket, threading, time
from typing import Callable, Optional


class FakeMudServer:
    """A minimal controlled fake MUD server on a local port."""

    def __init__(self, name: str, handler: Callable[[socket.socket], None], port: int = 0):
        self.name = name
        self.handler = handler
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind(('127.0.0.1', port))
        self.sock.listen(1)
        self.port = self.sock.getsockname()[1]
        self._thread = threading.Thread(target=self._serve, daemon=True)

    def _serve(self) -> None:
        while True:
            try:
                conn, _ = self.sock.accept()
            except OSError:
                return
            try:
                self.handler(conn)
            finally:
                try:
                    conn.close()
                except OSError:
                    pass

    def start(self) -> 'FakeMudServer':
        self._thread.start()
        return self

    def stop(self) -> None:
        try:
            self.sock.close()
        except OSError:
            pass


def negotiation_handler(conn: socket.socket) -> None:
    """Emit telnet negotiation then a welcome banner."""
    # IAC WILL ECHO, IAC WILL SUPPRESS-GO-AHEAD
    conn.sendall(bytes([255, 251, 1, 255, 251, 3]))
    conn.sendall(b'\r\nWelcome to the Protocol Museum.\r\n')
    conn.sendall(b'You stand in a quiet hall of fixtures.\r\n')
    conn.sendall(b'> ')


def text_stream_handler(conn: socket.socket) -> None:
    """Emit a deterministic stream of lines with a command echo."""
    lines = [
        'The north wall is covered in fading script.',
        'A lantern flickers on an iron hook.',
        'Someone has left a ledger on the table.',
    ]
    for line in lines:
        conn.sendall(('\r\n%s\r\n' % line).encode('utf-8'))
        conn.sendall(b'> ')
        time.sleep(0.02)


def malformed_handler(conn: socket.socket) -> None:
    """Emit bytes that are deliberately not valid UTF-8 text."""
    conn.sendall(b'\xff\xfb\x01\x00\xff\xfe\x80\x81\xff\xfd\x18')


def latency_handler(conn: socket.socket) -> None:
    """Emit a line, wait, then another line (latency fixture)."""
    conn.sendall(b'\r\nFirst line after a pause.\r\n')
    time.sleep(0.25)
    conn.sendall(b'\r\nSecond line arrives late.\r\n')


def disconnect_handler(conn: socket.socket) -> None:
    """Send a banner then close abruptly."""
    conn.sendall(b'\r\nGoodbye.\r\n')


SCENARIOS: dict[str, Callable[[socket.socket], None]] = {
    'negotiation': negotiation_handler,
    'text-stream': text_stream_handler,
    'malformed': malformed_handler,
    'latency': latency_handler,
    'disconnect': disconnect_handler,
}


def available_scenarios() -> list[str]:
    return sorted(SCENARIOS.keys())


if __name__ == '__main__':
    import sys
    scenario = sys.argv[1] if len(sys.argv) > 1 else 'negotiation'
    if scenario not in SCENARIOS:
        print(f'protocol museum: unknown scenario {scenario}', file=sys.stderr)
        raise SystemExit(1)
    server = FakeMudServer(scenario, SCENARIOS[scenario]).start()
    print(f'protocol museum: {scenario} listening on 127.0.0.1:{server.port}')
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        server.stop()

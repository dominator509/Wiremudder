#!/usr/bin/env python3
"""EP-007 test fixture: raw TCP echo server for controlled egress tests
(CI fixture mode, WM-SPEC-017-R09).

This is a SIMULATION fixture: a local test-only echo server. Not a
product component. Usage: echo_server.py <port>"""
import socketserver
import sys


class EchoHandler(socketserver.StreamRequestHandler):
    def handle(self):
        while True:
            data = self.request.recv(4096)
            if not data:
                break
            self.request.sendall(data)


if __name__ == "__main__":
    port = int(sys.argv[1])
    with socketserver.ThreadingTCPServer(("127.0.0.1", port), EchoHandler) as srv:
        print(f"echo server listening on 127.0.0.1:{port}", flush=True)
        srv.serve_forever()

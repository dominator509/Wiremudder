#!/usr/bin/env python3
"""EP-011 M3 controlled telnet fixture (SIMULATION: local test-only server).

Sends Telnet IAC negotiation bytes per mode, then echoes text lines so the
harness can prove protocol handling and manual gameplay coexist.

Modes:
  negotiate : WILL GMCP (ff fb c9), WILL MSDP (ff fb 45), WILL ATCP (ff fb c8)
  decline   : WONT GMCP (ff fc c9), DONT MSDP (ff fe 45)
  garbage   : unterminated SB with escaped IACs, then plain echo
"""
import socket
import sys
import threading

IAC = b"\xff"
WILL = b"\xfb"
WONT = b"\xfc"
DO = b"\xfd"
DONT = b"\xfe"
SB = b"\xfa"
SE = b"\xf0"
GMCP = b"\xc9"   # 201
MSDP = b"\x45"   # 69
ATCP = b"\xc8"   # 200


def main() -> int:
    if len(sys.argv) < 3:
        print("usage: telnet_server.py PORT MODE", file=sys.stderr)
        return 2
    port = int(sys.argv[1])
    mode = sys.argv[2]

    if mode == "negotiate":
        banner = IAC + WILL + GMCP + IAC + WILL + MSDP + IAC + WILL + ATCP
    elif mode == "decline":
        banner = IAC + WONT + GMCP + IAC + DONT + MSDP
    elif mode == "garbage":
        # Unterminated subnegotiation with escaped IACs: ff fa 00 ff ff 00 ff c9
        banner = IAC + SB + b"\x00" + IAC + IAC + b"\x00" + IAC + GMCP + b"  garbage-mode"
    else:
        print("unknown mode", file=sys.stderr)
        return 2

    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("127.0.0.1", port))
    srv.listen(4)
    print(f"ready {port} {mode}", flush=True)

    def handle(conn: socket.socket) -> None:
        try:
            conn.sendall(banner)
            while True:
                data = conn.recv(4096)
                if not data:
                    break
                conn.sendall(b"echo:" + data)
        except OSError:
            pass
        finally:
            conn.close()

    threads = []
    try:
        while True:
            conn, _ = srv.accept()
            t = threading.Thread(target=handle, args=(conn,), daemon=True)
            t.start()
            threads.append(t)
    except KeyboardInterrupt:
        pass
    finally:
        srv.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())

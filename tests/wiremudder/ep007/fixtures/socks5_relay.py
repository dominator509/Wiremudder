#!/usr/bin/env python3
"""EP-007 test fixture: minimal SOCKS5 relay (no-auth CONNECT) for
controlled egress tests (CI fixture mode, WM-SPEC-017-R09).

This is a SIMULATION fixture: a local test-only SOCKS5 relay used to
prove the routing layer really traverses a proxy. It is not a product
component and never runs in production paths.

Usage: socks5_relay.py <listen_port> <log_file>
Each CONNECT target is appended to log_file as host:port so tests can
assert the connection actually went through the relay.
"""
import asyncio
import sys


async def handle(reader, writer, log_file):
    try:
        # Greeting: VER NMETHODS METHODS
        greeting = await reader.readexactly(2)
        if greeting[0] != 5:
            return
        nmethods = greeting[1]
        if nmethods:
            await reader.readexactly(nmethods)
        # No-auth response
        writer.write(b"\x05\x00")
        await writer.drain()

        # Request: VER CMD RSV ATYP DST.ADDR DST.PORT
        head = await reader.readexactly(4)
        if head[0] != 5 or head[1] != 1:
            writer.write(b"\x05\x07\x00\x01" + b"\x00" * 6)
            await writer.drain()
            return
        atyp = head[3]
        if atyp == 1:  # IPv4
            addr = await reader.readexactly(4)
            host = ".".join(str(b) for b in addr)
        elif atyp == 3:  # domain
            ln = (await reader.readexactly(1))[0]
            host = (await reader.readexactly(ln)).decode()
        elif atyp == 4:  # IPv6
            raw = await reader.readexactly(16)
            host = ":".join(f"{raw[i]:02x}{raw[i+1]:02x}" for i in range(0, 16, 2))
        else:
            return
        port = int.from_bytes(await reader.readexactly(2), "big")

        with open(log_file, "a", encoding="utf-8") as f:
            f.write(f"{host}:{port}\n")

        try:
            upstream = await asyncio.open_connection(host, port)
        except OSError as e:
            writer.write(b"\x05\x05\x00\x01" + b"\x00" * 6)
            await writer.drain()
            return
        writer.write(b"\x05\x00\x00\x01" + b"\x00" * 6)
        await writer.drain()

        async def pump(src, dst):
            try:
                while True:
                    data = await src.read(65536)
                    if not data:
                        break
                    dst.write(data)
                    await dst.drain()
            except (ConnectionError, asyncio.CancelledError):
                pass
            finally:
                try:
                    dst.close()
                except Exception:
                    pass

        await asyncio.gather(pump(reader, upstream[1]), pump(upstream[0], writer))
    except (asyncio.IncompleteReadError, ConnectionError):
        pass
    finally:
        try:
            writer.close()
        except Exception:
            pass


async def main(port, log_file):
    server = await asyncio.start_server(
        lambda r, w: handle(r, w, log_file), "127.0.0.1", port
    )
    print(f"socks5 relay listening on 127.0.0.1:{port}", flush=True)
    async with server:
        await server.serve_forever()


if __name__ == "__main__":
    port = int(sys.argv[1])
    log_file = sys.argv[2]
    asyncio.run(main(port, log_file))

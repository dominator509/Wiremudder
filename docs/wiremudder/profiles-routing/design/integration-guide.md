# EP-007 Integration and Test Guide — Design

Node: EP-007. Commands verified on 2026-08-27 against Qt 6.8.2
(`/opt/qt/6.8.2/gcc_64`) and the standalone WireCore crates.

## 1. Unit Tests (Rust core)

```sh
cd wirecore/crates/wire-profiles && cargo test --offline   # 5 tests
cd wirecore/crates/wire-routing && cargo test --offline   # 7 tests
```

Observed sentinels: `test result: ok. 5 passed; 0 failed` /
`test result: ok. 7 passed; 0 failed`.

## 2. C++ Harness

Compile once for all harness subcommands:

```sh
QT=/opt/qt/6.8.2/gcc_64
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep007/harness/ep007_harness.cpp \
  src/wiremudder/profiles/character_profile_store.cpp \
  src/wiremudder/routing/route_profile_store.cpp \
  src/wiremudder/routing/router.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o /tmp/wm-ep007-h
LD_LIBRARY_PATH="$QT/lib" /tmp/wm-ep007-h profiles   # harness profiles: ok
LD_LIBRARY_PATH="$QT/lib" /tmp/wm-ep007-h routing    # harness routing: ok
LD_LIBRARY_PATH="$QT/lib" /tmp/wm-ep007-h router     # harness router: ok
```

## 3. Integration Tests

```sh
sh tests/wiremudder/ep007/integration/001-profile-persistence.sh
sh tests/wiremudder/ep007/integration/002-route-store.sh
sh tests/wiremudder/ep007/integration/003-router-qt.sh
```

Sentinels: `integration profile-persistence: ok`, `integration
route-store: ok`, `integration router-qt: ok`.

## 4. E2E Tests

```sh
sh tests/wiremudder/ep007/e2e/001-egress-oracle.sh          # oracle e2e: ok
sh tests/wiremudder/ep007/e2e/002-profile-connect-flow.sh   # e2e profile-connect-flow: ok
```

The connect-flow test starts controlled local fixtures (SIMULATION):
a raw echo server (`fixtures/echo_server.py`) and a minimal SOCKS5
relay (`fixtures/socks5_relay.py`, CI fixture mode per WM-SPEC-017-R09).
It proves:

1. A QTcpSocket with a SOCKS5 route decision traverses the relay (the
   relay log records the target `host:port`).
2. Killing the relay makes the same connect BLOCK — no silent fallback
   to direct (WM-SPEC-006-R06).
3. The explicit direct route still connects (manual text gameplay is
   preserved when optional routing is unavailable).

## 5. Oracle Cross-Check

`e2e/001-egress-oracle.sh` builds `wire-routing/src/bin/oracle.rs` and
`wire-profiles/src/bin/oracle.rs` and compares their JSON against the
C++ harness `oracle` subcommand and `profiles` invariants:

- 12 route-validation entries agree (id, kind, valid).
- 10 profile domains agree with sensitive flags (routing/ai sensitive).
- Actor rules agree: automation denied for routing changes, allowed for
  voice; user AI change audited and redacted.

## 6. Rollback

Recompile of the harness is idempotent. All fixtures are local-only
test servers bound to 127.0.0.1 and are torn down on script exit via
trap. No production path starts or references these fixtures.

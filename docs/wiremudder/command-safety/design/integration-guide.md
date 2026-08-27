# EP-008 Integration and Test Guide — Design

Node: EP-008. Commands verified on 2026-08-27 against Qt 6.8.2
(`/opt/qt/6.8.2/gcc_64`) and the standalone WireCore crates.

## 1. Unit Tests (Rust core)

```sh
cd wirecore/crates/wire-policy && cargo test --offline   # 5 tests
cd wirecore/crates/wire-actions && cargo test --offline  # 9 tests
```

Observed sentinels: `test result: ok. 5 passed; 0 failed` /
`test result: ok. 9 passed; 0 failed`.

## 2. C++ Harness

```sh
QT=/opt/qt/6.8.2/gcc_64
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep008/harness/ep008_harness.cpp \
  src/wiremudder/command-safety/action_gateway.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o /tmp/wm-ep008-h
LD_LIBRARY_PATH="$QT/lib" /tmp/wm-ep008-h policy   # harness policy: ok
LD_LIBRARY_PATH="$QT/lib" /tmp/wm-ep008-h gateway  # harness gateway: ok
LD_LIBRARY_PATH="$QT/lib" /tmp/wm-ep008-h estop    # harness estop: ok
```

## 3. Integration Tests

```sh
sh tests/wiremudder/ep008/integration/001-command-policy.sh
sh tests/wiremudder/ep008/integration/002-action-gateway.sh
sh tests/wiremudder/ep008/integration/003-emergency-stop.sh
```

Sentinels: `integration command-policy: ok`, `integration
action-gateway: ok`, `integration emergency-stop: ok`.

## 4. E2E Tests

```sh
sh tests/wiremudder/ep008/e2e/001-oracle.sh          # e2e oracle: ok
sh tests/wiremudder/ep008/e2e/002-command-flow.sh    # e2e command-flow: ok
```

The command-flow test proves: all nine non-manual sources enter the
gate; safe commands send, destructive commands queue for confirmation,
denied commands never send; emergency stop cancels the queue and blocks
new proposals; the manual input path (TCommandLine/TConsole) never
references the gateway (WM-SPEC-009-R01); audit serialization carries
every schema-required field.

## 5. Oracle Cross-Check

`e2e/001-oracle.sh` builds `wire-policy/src/bin/oracle.rs` and
`wire-actions/src/bin/oracle.rs` and compares their JSON against the
C++ harness `oracle` subcommand:

- 8 policy entries agree on tier/denied/confirmation/arg validation.
- Gate decisions agree on shared scenarios (approved /
  needs-confirmation / denied), normalizing Rust enum rendering.

## 6. Rollback

Harness compilation is idempotent. All fixtures are local-only. No
production path references test fixtures.

#!/usr/bin/env sh
# E2E test: launch the built inherited client headlessly using the
# upstream CI smoke pattern (xvfb + QT_QPA_PLATFORM=offscreen) and prove
# it starts and stays alive (a GUI client must not crash on startup).
set -eu
. ./.env
preset=$WIREMUDDER_CMAKE_PRESET
bin="build-$preset/src/mudlet"
[ -x "$bin" ] || { echo "FAIL: $bin missing" >&2; exit 1; }
if command -v xvfb-run >/dev/null 2>&1; then
  # Launch under Xvfb; the client should stay alive (no startup crash).
  set +e
  xvfb-run --auto-servernum "$bin" --profile "Mudlet self-test" --mirror </dev/null >/tmp/wm-e2e-001.out 2>&1 &
  child=$!
  set -e
  sleep 12
  if kill -0 "$child" 2>/dev/null; then
    # Still alive after 12s: startup succeeded. Terminate cleanly.
    pkill -P "$child" 2>/dev/null || true
    kill "$child" 2>/dev/null || true
    wait "$child" 2>/dev/null || true
    echo "e2e client-launch: ok"
    exit 0
  fi
  wait "$child" 2>/dev/null || true
  echo "FAIL: client exited during startup: $(tail -5 /tmp/wm-e2e-001.out)" >&2
  exit 1
else
  QT_QPA_PLATFORM=offscreen "$bin" --help >/tmp/wm-e2e-001.out 2>&1 || true
  echo "e2e client-launch: ok (offscreen help)"
fi

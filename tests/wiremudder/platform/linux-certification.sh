#!/usr/bin/env sh
# EP-036 M2 platform certification: clean build and core flow certification
# for the Linux platform (SPEC-027-R08). The Linux host is certified with
# real evidence: clean builds of the release core and updater core, their
# full unit suites, and the installer smoke. Windows/macOS certification is
# documented with exact evidence requirements (not claimed without evidence).
set -eu
cd "$(dirname "$0")/../../.."

fail() { echo "platform: FAIL - $1" >&2; exit 1; }
pass() { echo "platform: ok - $1"; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

# Detect the certified platform.
case "$(uname -s)" in
  Linux) PLATFORM=linux ;;
  Darwin) PLATFORM=macos ;;
  MINGW*|MSYS*|CYGWIN*) PLATFORM=windows ;;
  *) PLATFORM=unknown ;;
esac
[ "$PLATFORM" = "unknown" ] && fail "unsupported host platform"

# 1. Clean build: release core and updater core compile with zero warnings.
for crate in packaging/wiremudder wirecore/crates/wire-updater; do
  log=$(mktemp /tmp/ep036_build_XXXX.log)
  "$cargo_bin" build --quiet --release --manifest-path "$crate/Cargo.toml" \
    >"$log" 2>&1 || { cat "$log" >&2; fail "$crate clean build failed"; }
  if grep -q "^warning" "$log"; then
    cat "$log" >&2
    fail "$crate clean build emitted warnings"
  fi
done
pass "clean build zero warnings (release core, updater core)"

# 2. Full unit suites pass on this platform.
for crate in packaging/wiremudder wirecore/crates/wire-updater; do
  log=$(mktemp /tmp/ep036_test_XXXX.log)
  "$cargo_bin" test --quiet --manifest-path "$crate/Cargo.toml" \
    >"$log" 2>&1 || { cat "$log" >&2; fail "$crate tests failed on $PLATFORM"; }
  grep -q "test result: ok" "$log" || fail "$crate no passing suite on $PLATFORM"
done
pass "full unit suites pass on $PLATFORM"

# 3. Installer smoke passes on this platform.
sh installers/wiremudder/smoke.sh 0.5.0 "$(mktemp -d /tmp/ep036_inst_XXXX)" >/dev/null 2>&1 \
  || fail "installer smoke failed on $PLATFORM"
pass "installer smoke passes on $PLATFORM"

# 4. Cross-platform evidence requirements are documented (not claimed).
[ -f compatibility/platform/matrix.md ] || fail "missing compatibility matrix"
grep -q "## Linux" compatibility/platform/matrix.md || fail "matrix missing linux status"
grep -q "## Windows" compatibility/platform/matrix.md || fail "matrix missing windows status"
grep -q "## macOS" compatibility/platform/matrix.md || fail "matrix missing macos status"

echo "platform EP-036 $PLATFORM-certification: ok"

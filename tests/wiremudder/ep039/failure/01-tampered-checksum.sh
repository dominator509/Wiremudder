#!/usr/bin/env sh
# EP-039 M4 failure: a tampered checksum must be caught by the real
# sha256sum -c path — fail-closed, no silent acceptance.
set -eu
cd "$(dirname "$0")/../../../.."

work=$(mktemp -d /tmp/ep039_fail_XXXX)
trap 'rm -rf "$work"' EXIT

cp release/wiremudder/final/SHA256SUMS "$work/"
# Tamper: corrupt one recorded hash.
sed 's/^\([0-9a-f]\{6\}\)/000000/' "$work/SHA256SUMS" > "$work/SHA256SUMS.bad"
mv "$work/SHA256SUMS.bad" "$work/SHA256SUMS"

if (cd release/wiremudder/final && sha256sum -c "$work/SHA256SUMS" >/dev/null 2>&1); then
  echo "FAIL: tampered checksums verified" >&2
  exit 1
fi
echo 'tampered checksum rejection: ok'

#!/usr/bin/env sh
# Contract test: upstream remote must point at the official Mudlet repository.
set -eu
url=$(git config --get remote.upstream.url)
[ -n "$url" ] || { echo "FAIL: no upstream remote" >&2; exit 1; }
case "$url" in
  https://github.com/Mudlet/Mudlet.git|git@github.com:Mudlet/Mudlet.git) ;;
  *) echo "FAIL: upstream remote is $url, expected Mudlet" >&2; exit 1 ;;
esac
echo "contract upstream-remote: ok"

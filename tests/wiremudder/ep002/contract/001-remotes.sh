#!/usr/bin/env sh
# Contract test: origin/upstream roles are unambiguous and correct.
set -eu
up=$(git config --get remote.upstream.url)
or=$(git config --get remote.origin.url)
case "$up" in
  https://github.com/Mudlet/Mudlet.git|git@github.com:Mudlet/Mudlet.git) ;;
  *) echo "FAIL: upstream=$up" >&2; exit 1 ;;
esac
case "$or" in
  https://github.com/dominator509/Wiremudder.git|git@github.com:dominator509/Wiremudder.git|https://github.com/dominator509/WireMudder.git|git@github.com:dominator509/WireMudder.git) ;;
  *) echo "FAIL: origin=$or" >&2; exit 1 ;;
esac
[ "$up" != "$or" ] || { echo "FAIL: upstream and origin identical" >&2; exit 1; }
echo "contract remotes: ok"

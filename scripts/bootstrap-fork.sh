#!/usr/bin/env sh
set -eu
[ "$#" -eq 2 ] || { echo 'usage: bootstrap-fork.sh TARGET_DIR WIREMUDDER_ORIGIN_URL' >&2; exit 2; }
target=$1
origin_url=$2
[ ! -e "$target" ] || { echo 'bootstrap: target exists' >&2; exit 1; }
pack_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
git clone https://github.com/Mudlet/Mudlet.git "$target"
cd "$target"
git switch -c wire/development 77086c295f4adf59197e586e689d19bdde8e1008
git remote rename origin upstream
git remote add origin "$origin_url"
cp -R "$pack_root"/. .
sh scripts/validate-blueprint.sh
echo 'bootstrap fork: ok'

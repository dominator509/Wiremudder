#!/usr/bin/env sh
set -eu
[ -f .env ] && { set -a; . ./.env; set +a; }
sh scripts/run-locked-command.sh build
echo 'build: ok'

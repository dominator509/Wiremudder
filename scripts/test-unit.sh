#!/usr/bin/env sh
set -eu
[ -f .env ] && { set -a; . ./.env; set +a; }
sh scripts/run-locked-command.sh unit
echo 'unit tests: ok'

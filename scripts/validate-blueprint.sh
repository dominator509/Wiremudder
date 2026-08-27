#!/usr/bin/env sh
set -eu
python3 scripts/validate_blueprint.py
sh scripts/authority-check.sh
echo 'blueprint validation: ok'

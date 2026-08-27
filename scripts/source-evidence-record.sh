#!/usr/bin/env sh
set -eu
case " $* " in *" -- "*) ;; *) echo 'usage: source-evidence-record.sh PATH SYMBOL_OR_RANGE CLAIM -- COMMAND ARGS' >&2; exit 2;; esac
[ "$#" -ge 5 ] || { echo 'usage: source-evidence-record.sh PATH SYMBOL_OR_RANGE CLAIM -- COMMAND ARGS' >&2; exit 2; }
exec python3 scripts/source_evidence.py "$@"

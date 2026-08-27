#!/usr/bin/env sh
set -eu
case "${WIREMUDDER_RELEASE_PROFILE:-}" in core|ai|immersion|developer|full) exit 0;; *) exit 1;; esac

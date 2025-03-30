#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -eo pipefail

/usr/local/bin/db-util healthcheck 2>/dev/null
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
exec python3 "$(dirname "$SCRIPT_PATH")/kde-lockscreen/manage.py" "$@"

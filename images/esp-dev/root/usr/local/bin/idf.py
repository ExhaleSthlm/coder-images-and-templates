#!/usr/bin/env bash
set -euo pipefail

# ESP-IDF keeps its Python environment and versioned tools outside PATH.
# shellcheck disable=SC1091
source /opt/esp/idf/export.sh >/dev/null 2>&1
exec python /opt/esp/idf/tools/idf.py "$@"

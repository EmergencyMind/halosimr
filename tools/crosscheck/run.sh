#!/usr/bin/env bash
# Run the Python -> R cross-check end to end.
#
#   HALOSIM_DIR   path to the Python halosim repo (default: ../../../halosim)
#   R_LIBS        library path where halosimr + jsonlite are installed
#
# Exits non-zero if any deterministic stage differs between the engines.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
HALOSIM_DIR="${HALOSIM_DIR:-$HERE/../../../halosim}"

PYTHONPATH="$HALOSIM_DIR" python3 "$HERE/crosscheck.py" > "$HERE/expected.json"
Rscript "$HERE/crosscheck.R" "$HERE/expected.json"

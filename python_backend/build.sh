#!/usr/bin/env bash
# Local build check — same steps Render runs (from repo root).
set -euo pipefail
bash "$(dirname "$0")/render-build.sh"

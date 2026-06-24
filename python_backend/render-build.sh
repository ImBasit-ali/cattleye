#!/usr/bin/env bash
# Render build — works when this folder is the repo root (standalone deploy).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "==> Upgrading pip"
python -m pip install --upgrade pip

echo "==> Installing dependencies"
python -m pip install -r requirements.txt

echo "==> Verifying model weights"
python verify_models.py

echo "==> Build complete"

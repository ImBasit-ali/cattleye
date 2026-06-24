#!/usr/bin/env bash
# PyTorch weights in assets/models — run the Python backend (no ONNX/TFLite export).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -f "$ROOT/assets/models/bcs_scorer.pth" ]]; then
  echo "ERROR: Missing assets/models/*.pth — copy Kaggle-trained weights first." >&2
  exit 1
fi

echo "PyTorch models:"
ls -lh "$ROOT/assets/models/"*.{pth,pt} 2>/dev/null || true
echo
echo "Start backend:"
echo "  pip install -r python_backend/requirements.txt"
echo "  python -m uvicorn python_backend.main:app --host 0.0.0.0 --port 8000"

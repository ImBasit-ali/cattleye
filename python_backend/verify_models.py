"""Verify PyTorch weights exist before Render deploy finishes building."""
from __future__ import annotations

import sys
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parent
MONOREPO_ROOT = BACKEND_ROOT.parent
for path in (BACKEND_ROOT, MONOREPO_ROOT):
    entry = str(path)
    if entry not in sys.path:
        sys.path.insert(0, entry)

try:
    from config import MODELS_DIR
except ImportError:
    from python_backend.config import MODELS_DIR

REQUIRED = (
    "eartag_detector.pt",
    "yolov8n-pose.pt",
    "behavior_classifier.pth",
    "bcs_scorer.pth",
    "muzzle_embedder.pth",
    "lameness_detector.pth",
)


def main() -> int:
    missing = [name for name in REQUIRED if not (MODELS_DIR / name).is_file()]
    if missing:
        print(f"ERROR: Missing model weights in {MODELS_DIR}:", file=sys.stderr)
        for name in missing:
            print(f"  - {name}", file=sys.stderr)
        print(
            "\nPut weights in python_backend/models/\n"
            "Required: *.pth, *.pt, and *_meta.json files.\n"
            "Or set MODELS_DIR in python_backend/.env.",
            file=sys.stderr,
        )
        return 1

    total_mb = sum((MODELS_DIR / name).stat().st_size for name in REQUIRED) / (
        1024 * 1024
    )
    print(f"OK: {len(REQUIRED)} model files found in {MODELS_DIR} ({total_mb:.1f} MB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

"""Paths and settings for the PyTorch inference backend."""
from __future__ import annotations

import json
import os
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parent


def _load_dotenv() -> None:
    """Load python_backend/.env into os.environ (does not override existing vars)."""
    env_file = BACKEND_ROOT / ".env"
    if not env_file.is_file():
        return
    for line in env_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        os.environ.setdefault(key, value)


_load_dotenv()

# Default: python_backend/models/ (all .pth / .pt weights live here)
DEFAULT_MODELS_DIR = BACKEND_ROOT / "models"


def resolve_models_dir() -> Path:
    from_env = os.getenv("MODELS_DIR", "").strip()
    if from_env:
        path = Path(from_env)
        if path.is_absolute():
            return path
        return BACKEND_ROOT / from_env
    return DEFAULT_MODELS_DIR


MODELS_DIR = resolve_models_dir()

EARTAG_PT = MODELS_DIR / "eartag_detector.pt"
POSE_PT = MODELS_DIR / "yolov8n-pose.pt"
BEHAVIOR_PTH = MODELS_DIR / "behavior_classifier.pth"
BCS_PTH = MODELS_DIR / "bcs_scorer.pth"
MUZZLE_PTH = MODELS_DIR / "muzzle_embedder.pth"
LAMENESS_PTH = MODELS_DIR / "lameness_detector.pth"

ENABLE_EARTAG_OCR = os.getenv("ENABLE_EARTAG_OCR", "true").strip().lower() in (
    "1",
    "true",
    "yes",
    "on",
)
TROCR_MODEL = os.getenv("TROCR_MODEL", "microsoft/trocr-small-printed").strip()


def load_meta(name: str) -> dict:
    path = MODELS_DIR / f"{name}_meta.json"
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def load_meta_optional(name: str) -> dict | None:
    path = MODELS_DIR / f"{name}_meta.json"
    if not path.is_file():
        return None
    with path.open(encoding="utf-8") as f:
        return json.load(f)

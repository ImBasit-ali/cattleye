"""FastAPI server — runs original .pth / .pt models for all five cattle functions."""
from __future__ import annotations

import os
import sys
from pathlib import Path

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

BACKEND_ROOT = Path(__file__).resolve().parent
MONOREPO_ROOT = BACKEND_ROOT.parent

if (MONOREPO_ROOT / "pubspec.yaml").exists():
    if str(MONOREPO_ROOT) not in sys.path:
        sys.path.insert(0, str(MONOREPO_ROOT))
    from python_backend.services.local_model_service import LocalModelService
else:
    if str(BACKEND_ROOT) not in sys.path:
        sys.path.insert(0, str(BACKEND_ROOT))
    from services.local_model_service import LocalModelService

_allowed = os.getenv("ALLOWED_ORIGINS", "*").split(",")
app = FastAPI(title="Cattle AI — PyTorch Backend", version="2.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in _allowed if o.strip()],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

_service = LocalModelService()


@app.on_event("startup")
def startup() -> None:
    try:
        print(
            f"[startup] ENV={os.getenv('ENV', 'development')} "
            f"MODELS_DIR={_service.models_dir} PORT={os.getenv('PORT', '8000')}"
        )
        _service.initialize()
        print("[startup] ✓ Models loaded successfully")
    except Exception as e:
        print(f"[startup] ✗ ERROR: {e}")
        import traceback
        traceback.print_exc()


@app.get("/")
def root():
    return {
        "status": "backend running",
        "backend": "pytorch"
    }


@app.get("/health")
def health() -> dict:
    return {
        "status": "ok" if _service.is_ready else "loading",
        "env": os.getenv("ENV", "development"),
        "models_dir": str(_service.models_dir),
        "backend": "pytorch",
        "weights": [
            "eartag_detector.pt",
            "yolov8n-pose.pt",
            "behavior_classifier.pth",
            "bcs_scorer.pth",
            "muzzle_embedder.pth",
            "lameness_detector.pth",
        ],
        "features": {
            "eartag_ocr": _service.has_eartag_ocr if _service.is_ready else False,
        },
    }


def _handle_analysis_error(exc: Exception) -> HTTPException:
    if isinstance(exc, ValueError) and "No cattle found" in str(exc):
        return HTTPException(status_code=422, detail=str(exc))
    if isinstance(exc, ValueError):
        return HTTPException(status_code=400, detail=str(exc))
    return HTTPException(status_code=500, detail=str(exc))


@app.post("/api/count-cattle")
async def count_cattle(image: UploadFile = File(...)) -> dict:
    try:
        data = await image.read()
        if not data:
            raise HTTPException(status_code=400, detail="Empty image upload")
        count = _service.count_cattle(data)
        return {"cattle_count": count}
    except HTTPException:
        raise
    except Exception as exc:
        raise _handle_analysis_error(exc) from exc


@app.post("/api/analyze-image")
async def analyze_image(image: UploadFile = File(...)) -> dict:
    try:
        data = await image.read()
        if not data:
            raise HTTPException(status_code=400, detail="Empty image upload")
        return _service.analyze_image(data)
    except HTTPException:
        raise
    except Exception as exc:
        raise _handle_analysis_error(exc) from exc


@app.post("/api/analyze-video-preview")
async def analyze_video_preview(
    preview: UploadFile = File(...),
    video_file_name: str = Form(default="video.mp4"),
) -> dict:
    try:
        data = await preview.read()
        if not data:
            raise HTTPException(status_code=400, detail="Empty preview upload")
        return _service.analyze_video_preview(data, video_file_name)
    except HTTPException:
        raise
    except Exception as exc:
        raise _handle_analysis_error(exc) from exc


@app.post("/api/analyze-video-frames")
async def analyze_video_frames(
    frames: list[UploadFile] = File(...),
    video_file_name: str = Form(default="video.mp4"),
) -> dict:
    """Analyze up to 20 JPEG frames for lameness BiLSTM sequence inference."""
    try:
        frame_bytes: list[bytes] = []
        for upload in frames[:20]:
            data = await upload.read()
            if data:
                frame_bytes.append(data)
        if not frame_bytes:
            raise HTTPException(status_code=400, detail="Empty frame upload")
        return _service.analyze_video_frames(frame_bytes, video_file_name)
    except HTTPException:
        raise
    except Exception as exc:
        raise _handle_analysis_error(exc) from exc


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", "8000"))
    app_path = (
        "main:app"
        if not (MONOREPO_ROOT / "pubspec.yaml").exists()
        else "python_backend.main:app"
    )
    uvicorn.run(app_path, host="0.0.0.0", port=port, reload=False)

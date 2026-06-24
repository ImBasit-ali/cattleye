# Release mode: run cattle AI on-device (Android, iOS, Windows)

This guide explains how to ship **release builds** of Cattle AI that run your **Kaggle-trained models** from `assets/models/` **inside the Flutter app only** — without starting `python_backend` or any separate server on the user’s machine.

---

## 1. Goal vs current app behavior

| Target (what you want) | Current project (today) |
|------------------------|-------------------------|
| Single Flutter app in **release** mode | Flutter UI + Supabase |
| Models run **on the phone/PC** | Models run in **Python** (`python_backend/`) via HTTP (`127.0.0.1:8000`) |
| No second process / no terminal | `LocalModelService` calls `/api/analyze-image` and `/api/analyze-video` |
| Works offline for vision tasks | Requires PyTorch + Ultralytics in Python |

**Important:** Flutter/Dart cannot load `.pth` / `.pt` (PyTorch) weights directly. Those files are correct for training on Kaggle and for the Python dev backend, but **release on-device inference needs exported formats** (TFLite, ONNX, or Core ML). Your `eartag_meta.json` already points at the right idea: `eartag_detector.tflite`.

Until on-device runners are implemented in Dart, release builds still need either the Python backend or OpenRouter API keys in `.env`.

---

## 2. Trained model files in `assets/models/`

These are the weights produced from your Kaggle training pipeline. Keep them in the repo (or download from Kaggle into this folder).

| File | Size (approx.) | Function | Architecture (from `*_meta.json`) |
|------|----------------|----------|----------------------------------|
| `eartag_detector.pt` | 6 MB | Ear tag detection | YOLOv8n |
| `yolov8n-pose.pt` | 7 MB | Pose / cattle presence (lameness pipeline) | YOLOv8n-pose |
| `behavior_classifier.pth` | 6 MB | Feeding / behavior | MobileNetV3-Small, 224×224, 5 classes |
| `bcs_scorer.pth` | 47 MB | Body condition score | EfficientNet-B3, 384×384, ordinal 8 logits |
| `lameness_detector.pth` | 3 MB | Lameness from pose sequence | LayerNorm → proj 51→128 → BiLSTM → attention |
| `muzzle_embedder.pth` | 99 MB | Muzzle biometric embedding | ResNet50 + ArcFace, 256-d embed |
| `*_meta.json` | small | Pre/post-processing rules | Input size, mean/std, class names, thresholds |

**Total bundled weights:** ~165 MB if you ship all PyTorch files in the app. Plan for store size limits and optional “download models on first launch.”

### Meta JSON files (required in the app)

Always bundle the five meta files — they define how to preprocess images and decode outputs:

- `assets/models/eartag_meta.json`
- `assets/models/bcs_meta.json`
- `assets/models/behavior_meta.json`
- `assets/models/muzzle_meta.json`
- `assets/models/lameness_meta.json`

---

## 3. Why the Python backend exists today

The backend (`python_backend/services/local_model_service.py`) loads:

- **PyTorch** (`.pth`) for BCS, behavior, muzzle, lameness  
- **Ultralytics YOLO** (`.pt`) for ear tag and pose  

That stack is not available inside standard Flutter release binaries. The backend was added so you could use your **existing Kaggle exports unchanged** while developing.

For **production release without Python**, you must:

1. **Export** each model to a mobile/desktop runtime format.  
2. **Implement** inference in Dart (or via a small native plugin).  
3. **Point** `CattleAnalysisService` at on-device inference instead of HTTP.

---

## 4. Recommended on-device formats per platform

| Model role | Suggested export | Android / iOS | Windows release |
|------------|------------------|-----------------|-------------------|
| Ear tag (YOLO) | **TFLite** (or TFLite from Ultralytics) | `tflite_flutter` | **ONNX** + `onnxruntime` (or TFLite if you add a Windows TFLite build) |
| Pose (YOLO) | TFLite / ONNX | same | same |
| Behavior (MobileNetV3) | **TFLite** | `tflite_flutter` | ONNX |
| BCS (EfficientNet-B3) | TFLite (may need int8 quantize) | `tflite_flutter` | ONNX |
| Muzzle (ResNet50) | TFLite or ONNX | largest file — consider int8 | ONNX |
| Lameness (BiLSTM) | **ONNX** (LSTM ops) | `onnxruntime` / `flutter_onnxruntime` | ONNX |

**Practical split:**

- **Mobile (Android / iOS):** prefer **TFLite** for CNNs; use **ONNX Runtime** for lameness BiLSTM if TFLite conversion is painful.  
- **Windows desktop:** **ONNX Runtime** for all five is usually the simplest single stack.

Target paths (align with meta `flutter_model` where possible):

```
assets/models/eartag_detector.tflite
assets/models/yolov8n_pose.tflite          # or .onnx
assets/models/behavior_classifier.tflite
assets/models/bcs_scorer.tflite
assets/models/muzzle_embedder.tflite
assets/models/lameness_detector.onnx         # BiLSTM → ONNX is typical
```

---

## 5. Export pipeline (Kaggle / local PyTorch → mobile)

### One-command export (recommended)

From the project root (requires Python + pip):

```powershell
.\export_models.ps1
```

Or:

```bash
chmod +x export_models.sh && ./export_models.sh
```

This runs `python_backend/scripts/export_all_models.py`, which writes:

| File | Format |
|------|--------|
| `eartag_detector.tflite` / `.onnx` | YOLO |
| `yolov8n_pose.tflite` / `.onnx` | YOLO pose |
| `behavior_classifier.tflite` / `.onnx` | MobileNetV3 |
| `bcs_scorer.tflite` / `.onnx` | EfficientNet-B3 |
| `muzzle_embedder.tflite` / `.onnx` | ResNet50 |
| `lameness_detector.onnx` | BiLSTM (ONNX only) |

Also updates `*_meta.json` and creates `export_manifest.json`.

Extra pip packages: `python_backend/requirements-export.txt` (`onnx`, `onnx2tf`, `tensorflow`).

---

Run these **manually** only if you need custom export settings:

### 5.1 YOLO (ear tag + pose)

```python
from ultralytics import YOLO

# Ear tag
YOLO("assets/models/eartag_detector.pt").export(format="tflite", imgsz=416)
# Pose
YOLO("assets/models/yolov8n-pose.pt").export(format="tflite", imgsz=640)
# For Windows ONNX:
# .export(format="onnx", imgsz=416)
```

Verify output names and update `eartag_meta.json` / a new `pose_meta.json` if paths change.

### 5.2 BCS, behavior, muzzle (PyTorch → ONNX → optional TFLite)

Use the **same** `model_architectures.py` definitions as the Python backend (especially lameness — LayerNorm + `proj` + BiLSTM + `cls`).

Example ONNX export pattern:

```python
import torch
from model_architectures import BcsScorer, BehaviorClassifier, MuzzleEmbedder, LamenessBiLSTM

model = BcsScorer(num_bins=8)
ckpt = torch.load("assets/models/bcs_scorer.pth", map_location="cpu", weights_only=False)
# load state_dict into model (same logic as local_model_service._load_torch_module)
model.eval()
dummy = torch.randn(1, 3, 384, 384)
torch.onnx.export(model, dummy, "assets/models/bcs_scorer.onnx", opset_version=17)
```

Repeat for:

- `BehaviorClassifier` — input `[1, 3, 224, 224]`  
- `MuzzleEmbedder` — input `[1, 3, 224, 224]`, output `[1, 256]`  
- `LamenessBiLSTM` — input `[1, 20, 51]` (sequence from pose keypoints)

Then convert ONNX → TFLite only where tools support your ops (BiLSTM often stays ONNX on mobile).

### 5.3 Post-processing (must match meta JSON)

Implement in Dart using the same rules as Python:

| Function | Decode rule (from meta) |
|----------|-------------------------|
| BCS | `sigmoid(logits)` → count values > 0.5 → index into `bcs_bins` |
| Behavior | `softmax` → argmax → `classes` |
| Muzzle | L2-normalize embedding; cosine match vs gallery |
| Lameness | `softmax` on 2 classes; pose sequence length 20, `feat_dim` 51 |
| Ear tag | YOLO boxes, `conf_threshold` 0.4 |

---

## 6. Flutter changes for “no Python backend”

High-level implementation checklist (not yet in the repo):

1. **Dependencies** (add to `pubspec.yaml` when implementing):
   - `tflite_flutter` (Android / iOS CNNs)
   - `onnxruntime` or `flutter_onnxruntime` (lameness + Windows)
   - Optional: `google_mlkit` only if you replace YOLO with ML Kit (not required if you export YOLO to TFLite)

2. **New service:** e.g. `lib/services/on_device_model_service.dart`
   - Load interpreters once at startup (or lazy-load per model).
   - Read `*_meta.json` from `rootBundle`.
   - Expose the same methods as today’s analysis API: `analyzeCattleImage`, `analyzeCattleVideoPreview`.

3. **Switch routing in** `lib/services/cattle_analysis_service.dart`:
   - **First:** on-device runner if model files exist and interpreters initialized.
   - **Fallback:** OpenRouter only if keys are set (optional for release).
   - **Remove** dependency on `LOCAL_MODEL_BACKEND_URL` for release flavor.

4. **Assets in** `pubspec.yaml` (release flavor example):

```yaml
flutter:
  assets:
    - .env
    - assets/models/bcs_meta.json
    - assets/models/behavior_meta.json
    - assets/models/eartag_meta.json
    - assets/models/lameness_meta.json
    - assets/models/muzzle_meta.json
    - assets/models/eartag_detector.tflite
    - assets/models/yolov8n_pose.tflite
    - assets/models/behavior_classifier.tflite
    - assets/models/bcs_scorer.tflite
    - assets/models/muzzle_embedder.tflite
    - assets/models/lameness_detector.onnx
```

Do **not** bundle `.pth` / `.pt` in store builds unless you also ship PyTorch (not recommended). Keep PyTorch files for training/backend dev only.

5. **Release `.env`** (no Python, no cloud vision):

```env
USE_LOCAL_MODELS=true
USE_ON_DEVICE_INFERENCE=true
LOCAL_MODEL_BACKEND_URL=
# Supabase only — user auth + saving results
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
OPENROUTER_API_KEY=
VISION_API_KEY=
```

---

## 7. Release build commands (Flutter only)

Prerequisites: Flutter SDK, platform SDKs (Android Studio, Xcode, Visual Studio for Windows), `.env` with Supabase keys.

### Android

```bash
flutter build apk --release
# or Play Store bundle:
flutter build appbundle --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk` or `app-release.aab`.

Notes:

- Test on a **physical device**; ML inference is slow/unreliable on most emulators.
- If APK size is too large, use **ABI splits** or host models as a one-time download.

### iOS

```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode → **Product → Archive** → distribute.

Notes:

- Enable required capabilities (camera, photo library for video upload).
- Large models may need **on-demand resources** or background download to stay under cellular download limits.

### Windows

```bash
flutter build windows --release
```

Output: `build/windows/x64/runner/Release/cattle_ai.exe`.

Notes:

- ONNX Runtime DLLs must be bundled with the plugin you choose.
- FFmpeg on PATH helps video frame extraction (`video_preview_service` / `VideoFfmpegHelper`).

---

## 8. End-to-end flow in release (target architecture)

```text
User (camera / video upload)
        │
        ▼
Flutter release app
        │
        ├─► Extract frame(s) (video_thumbnail / FFmpeg on Windows)
        │
        ├─► YOLO TFLite/ONNX — cattle present? → else "No cattle found in this video"
        │
        ├─► For each animal crop / frame:
        │     • eartag TFLite
        │     • muzzle TFLite/ONNX
        │     • bcs TFLite/ONNX
        │     • behavior TFLite/ONNX
        │     • pose → lameness ONNX (20×51 sequence)
        │
        └─► Supabase (save detections / analysis JSON)
```

No `python main.py`, no `127.0.0.1:8000`.

---

## 9. Verification checklist before shipping release

- [ ] All five `*_meta.json` files present under `assets/models/`
- [ ] Exported **TFLite/ONNX** files present (not only `.pth` / `.pt`)
- [ ] `flutter build` release succeeds for each target platform
- [ ] App runs **without** Python backend running
- [ ] Image analysis returns same BCS/behavior/lameness ranges as Python backend on 10 test images
- [ ] Video with no cows shows: **No cattle found in this video**
- [ ] Video with cows shows success + data saved to Supabase
- [ ] Cold start time acceptable (lazy-load largest model: muzzle ~99 MB PyTorch equivalent)

---

## 10. What works today without extra implementation

| Mode | Command / setup | Models run where? |
|------|-----------------|-------------------|
| **Dev (current)** | `python main.py` + `flutter run` | Python backend |
| **Release + Python** | Build release Flutter app but user must run backend on PC | Still Python on desktop only |
| **Release on-device (target)** | Export models + implement `OnDeviceModelService` | Inside Flutter |

---

## 11. Suggested implementation order

1. Export **behavior** + **BCS** to TFLite (smallest integration test).  
2. Export **eartag** + **pose** YOLO to TFLite; wire cattle gate for video.  
3. Export **lameness** to ONNX; build 20-frame pose buffer in Dart.  
4. Export **muzzle** (quantize if possible).  
5. Switch `CattleAnalysisService` to on-device first; remove HTTP to Python for release flavor.  
6. Build release APK / IPA / Windows installer and run the checklist in §9.

---

## 12. Kaggle → repo workflow (reminder)

1. Train on Kaggle → download notebook output / weights.  
2. Copy into `assets/models/` with the exact names above (or update meta JSON paths).  
3. Run export scripts (§5) → commit **mobile** artifacts (`.tflite` / `.onnx`).  
4. Keep `.pth` / `.pt` for re-export and Python dev backend only (optional: `.gitignore` large weights on mobile branches).  
5. Tag release in git with model version in meta JSON or a `models_version.txt`.

---

## 13. Related project files

| Path | Role |
|------|------|
| `assets/models/*` | Trained weights + meta |
| `python_backend/services/local_model_service.py` | Reference inference logic to port to Dart |
| `python_backend/services/model_architectures.py` | Exact network shapes for ONNX export |
| `lib/services/cattle_analysis_service.dart` | Router — switch to on-device here |
| `lib/services/local_model_service.dart` | Today: HTTP to Python (replace for release) |
| `.env.example` | Environment template |

---

**Summary:** Your Kaggle models in `assets/models/` are valid and already used correctly by the Python backend. For **release on Android, iOS, and Windows without any backend**, export them to **TFLite / ONNX**, bundle those exports plus `*_meta.json`, implement an **on-device inference service in Flutter**, then build with `flutter build --release` per platform. PyTorch files alone are not enough for a standalone Flutter release binary.

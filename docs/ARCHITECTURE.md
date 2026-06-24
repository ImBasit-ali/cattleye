# Clean architecture — on-device AI

## Layers

```
presentation/     providers, screens
domain/           repositories (interfaces), exceptions
data/
  repositories/   CattleAnalysisRepositoryImpl
  ml/             CattleMlEngine, InferenceRunner, YOLO + classifiers
services/         camera, video, Supabase storage (unchanged infra)
```

## Inference

| Platform | Format | Package |
|----------|--------|---------|
| Windows / macOS / Linux | `.onnx` | `flutter_onnxruntime` |
| Android / iOS | `.tflite` | `tflite_flutter` |
| Lameness (all) | `.onnx` | `flutter_onnxruntime` |

Models load at app start in `main.dart` via `CattleAnalysisRepositoryImpl.ensureInitialized()`.

## Flows

- **Live camera:** `CameraProvider` → 30s timer → `analyzeImage` on JPEG frame
- **Video upload:** `processVideoFile` → multi-frame sampling → best frame with cattle → all five models per animal

No Python backend or OpenRouter required for vision.

## Re-export models (optional)

Use `export_models.ps1` if you retrain on Kaggle (requires Python export tooling — see git history or `docs/RELEASE_MODE_ON_DEVICE_MODELS.md`).

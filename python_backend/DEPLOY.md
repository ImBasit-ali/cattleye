# Deploy python_backend to Render

Push **this folder** (`python_backend/`) as its own GitHub repository, then connect it to Render.

## 1. Prepare models

Copy PyTorch weights from the Flutter monorepo into `models/`:

```powershell
# From cattle-ai repo root (Windows)
New-Item -ItemType Directory -Force python_backend\models
Copy-Item assets\models\*.pth python_backend\models\
Copy-Item assets\models\*.pt python_backend\models\
```

Commit all six weight files (~170 MB total).

## 2. Push to GitHub

```bash
cd python_backend
git init
git add .
git commit -m "Cattle AI PyTorch backend for Render"
git remote add origin https://github.com/YOUR_USER/cattle-ai-backend.git
git push -u origin main
```

## 3. Deploy on Render

1. [Render Dashboard](https://dashboard.render.com) → **New** → **Blueprint**
2. Connect your `cattle-ai-backend` repo
3. Render reads `render.yaml` automatically
4. Wait for build + deploy (~5–10 min on first run)
5. Copy the service URL, e.g. `https://cattle-ai-backend-xxxx.onrender.com`

## 4. Configure Flutter app

In the Flutter repo root `.env`:

```env
RENDER_MODEL_BACKEND_URL=https://cattle-ai-backend-xxxx.onrender.com
```

## 5. Build release apps

```powershell
# Android APK (uses Render URL in release mode)
flutter build apk --release

# Windows EXE (uses Render URL in release mode)
flutter build windows --release
```

Debug mode always uses `LOCAL_MODEL_BACKEND_URL=http://127.0.0.1:8000`.

## Local dev (monorepo)

From the **cattle-ai** repo root:

```powershell
.\scripts\start_backend.ps1
flutter run -d windows
```

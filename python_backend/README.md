# Cattle AI — Python PyTorch Backend

FastAPI service that runs all five cattle AI functions using original `.pth` / `.pt` weights:

| Weight file | Function |
|-------------|----------|
| `eartag_detector.pt` | Cattle / ear-tag detection |
| `yolov8n-pose.pt` | Pose keypoints (lameness pipeline) |
| `behavior_classifier.pth` | Behavior classification |
| `bcs_scorer.pth` | Body condition score |
| `muzzle_embedder.pth` | Muzzle embedding / ID |
| `lameness_detector.pth` | Lameness scoring |

Model files live in **`assets/models/`** at the **repository root** (not inside `python_backend/`).

---

## API endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Service + model load status |
| `POST` | `/api/count-cattle` | Count cattle in an image |
| `POST` | `/api/analyze-image` | Full image analysis |
| `POST` | `/api/analyze-video-preview` | Analyze a video preview frame |

Interactive docs (when running): `http://localhost:8000/docs`

---

## Run locally

From the **repo root** (`cattle-ai/`):

```bash
# 1. Create a virtual environment (recommended)
python -m venv .venv
# Windows
.venv\Scripts\activate
# macOS / Linux
source .venv/bin/activate

# 2. Install dependencies
pip install -r python_backend/requirements.txt

# 3. Verify model weights are present
python python_backend/verify_models.py

# 4. Start the server
python -m uvicorn python_backend.main:app --host 0.0.0.0 --port 8000
```

Health check:

```bash
curl http://127.0.0.1:8000/health
```

Expected response when models are loaded:

```json
{
  "status": "ok",
  "models_dir": ".../assets/models",
  "backend": "pytorch"
}
```

### Flutter app (local)

In `.env.development`:

```env
LOCAL_MODEL_BACKEND_URL=http://127.0.0.1:8000
```

**Android USB:** run `adb reverse tcp:8000 tcp:8000` so the phone can reach your PC.

**Same Wi‑Fi:** use your PC IP, e.g. `http://192.168.1.10:8000`, and start uvicorn with `--host 0.0.0.0`.

---

## Deploy on Render

Render hosts this backend as a **Web Service**. The repo includes a **Blueprint** (`render.yaml`) so deploy is repeatable.

### Prerequisites

1. **Git repository** (GitHub / GitLab / Bitbucket) with this project pushed.
2. **Model weights committed** under `assets/models/` (~170 MB total).  
   Render builds from Git — if weights are missing, the build fails at `verify_models.py`.
3. **Render account** — [https://render.com](https://render.com)

> **Memory:** PyTorch + Ultralytics needs **≥ 2 GB RAM**.  
> `render.yaml` uses the **Standard** plan. The Starter plan (512 MB) often runs out of memory during model load.

### Option A — Blueprint (recommended)

1. Push your code to GitHub (including `assets/models/*.pth` and `*.pt`).
2. Open [Render Dashboard](https://dashboard.render.com/) → **New** → **Blueprint**.
3. Connect the `cattle-ai` repository.
4. Render reads **`render.yaml`** and creates the service `cattle-ai-backend`.
5. Click **Apply** and wait for the first deploy (install PyTorch + load models can take **10–20 minutes**).
6. When deploy succeeds, copy the service URL, e.g.  
   `https://cattle-ai-backend.onrender.com`
7. Verify:

   ```bash
   curl https://cattle-ai-backend.onrender.com/health
   ```

8. Point the Flutter **production** env at that URL (see below).

### Option B — Manual Web Service

If you prefer the dashboard without Blueprint:

| Setting | Value |
|---------|--------|
| **Environment** | Python 3 |
| **Region** | Oregon (or nearest) |
| **Branch** | `main` |
| **Root Directory** | *(leave empty — repo root)* |
| **Build Command** | `bash python_backend/render-build.sh` |
| **Start Command** | `python -m uvicorn python_backend.main:app --host 0.0.0.0 --port $PORT` |
| **Health Check Path** | `/health` |
| **Instance Type** | Standard (2 GB RAM minimum) |

**Environment variables** (Render → Service → Environment):

| Key | Value |
|-----|--------|
| `PYTHON_VERSION` | `3.11.0` |
| `MODELS_DIR` | `assets/models` |
| `ENV` | `production` |
| `WEB_CONCURRENCY` | `1` |
| `ALLOWED_ORIGINS` | `*` |

Render sets **`PORT`** automatically — do not override it.

Alternative: Render can auto-detect **`Procfile`** at the repo root and **`requirements.txt`** (which includes `-r python_backend/requirements.txt`).

### Connect Flutter to Render

Edit **`.env.production`** (or copy from `.env.production.example`):

```env
APP_ENV=production
MODEL_BACKEND_URL=https://cattle-ai-backend.onrender.com
RENDER_MODEL_BACKEND_URL=https://cattle-ai-backend.onrender.com
LOCAL_MODEL_BACKEND_URL=
```

Build/run release:

```bash
flutter run --release
# or
flutter build apk --release
```

The app uses `MODEL_BACKEND_URL` in production and waits longer for Render **cold starts** (free/standard services spin down after inactivity).

### Render deploy files (reference)

```
cattle-ai/
├── render.yaml                 # Blueprint definition
├── runtime.txt                 # python-3.11.0
├── Procfile                    # web process for Render
├── requirements.txt            # → python_backend/requirements.txt
├── assets/models/              # .pth / .pt weights (required in Git)
└── python_backend/
    ├── main.py                 # FastAPI app
    ├── config.py               # MODELS_DIR, weight paths
    ├── requirements.txt        # PyTorch CPU, FastAPI, Ultralytics, …
    ├── render-build.sh         # Build script used on Render
    ├── verify_models.py        # Fails build if weights missing
    └── README.md               # This file
```

### Troubleshooting on Render

| Problem | What to do |
|---------|------------|
| Build fails: “Missing model weights” | Commit all six files in `assets/models/` and push. |
| Build fails: pip / torch errors | Confirm `PYTHON_VERSION=3.11.0` and `runtime.txt` is `python-3.11.0`. |
| Deploy OK but 502 / crash on start | Upgrade to **Standard** plan; reduce `WEB_CONCURRENCY` to `1`. |
| `/health` returns `"status":"loading"` for a long time | Normal on first request after cold start; models load on startup. |
| Flutter timeout on first call | Wait 2–3 minutes; app retries health automatically. |
| Out of memory (OOM) | Use Standard or Pro; do not run multiple workers (`WEB_CONCURRENCY=1`). |

**Logs:** Render Dashboard → your service → **Logs**. Look for PyTorch / Ultralytics errors during startup.

**Cold starts:** After idle, the service sleeps. The first API call wakes it; expect slower responses until `/health` returns `"status":"ok"`.

---

## Environment variables

| Variable | Local example | Render |
|----------|---------------|--------|
| `PORT` | `8000` | Set by Render |
| `MODELS_DIR` | `assets/models` | `assets/models` |
| `ENV` | `development` | `production` |
| `ALLOWED_ORIGINS` | `*` | `*` or your web origins |
| `WEB_CONCURRENCY` | — | `1` |

Copy `python_backend/.env.example` to `python_backend/.env` for local overrides (file is gitignored).

---

## Test production build locally

Simulate Render’s build step from repo root:

```bash
bash python_backend/render-build.sh
PORT=8000 python -m uvicorn python_backend.main:app --host 0.0.0.0 --port 8000
```

---

## CPU-only PyTorch

`requirements.txt` installs **CPU** builds of PyTorch (via `--extra-index-url https://download.pytorch.org/whl/cpu`). GPU is not used on Render’s default Python runtime.

---

## Support checklist before going live

- [ ] All six weight files exist in `assets/models/`
- [ ] `python python_backend/verify_models.py` passes locally
- [ ] `bash python_backend/render-build.sh` completes without errors
- [ ] Render deploy green; `curl …/health` returns `"status":"ok"`
- [ ] `.env.production` `MODEL_BACKEND_URL` matches Render service URL
- [ ] Release Flutter build analyzed a test image successfully

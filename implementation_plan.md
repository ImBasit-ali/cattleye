# 🐄 Implementation Plan — Cattle AI Monitor Rebuild

**Goal:** Replace all Django/Firebase logic with **Supabase + FastAPI + Roboflow**, remove `ai_monitoring_screen` and all video upload/processing screens, and ship a fully workable real-time monitoring app.

---

## 📐 Final Architecture

```
Flutter App (Provider)
    │
    ├── Supabase Auth  ───────────────────────── auth.users table
    │
    ├── CattleService (new)  ──────────────────► Supabase Realtime
    │       └── subscribeToDetections()             (cattle_detections table)
    │
    └── http ──────────────────────────────────► Railway (FastAPI)
                                                      │
                                               Roboflow API
                                               (cattle-detection model)
                                                      │
                                               Supabase DB
                                               (writes results)
```

---

## 🔑 Environment Variables — Where Each One Lives

### Python Backend (`python_backend/.env`) — also set in Railway Dashboard

| Variable | Value | Used In | Purpose |
|---|---|---|---|
| `SUPABASE_URL` | `https://xyzxyz.supabase.co` | `config.py` → `database_service.py` | Connect to Supabase PostgreSQL & Realtime |
| `SUPABASE_SERVICE_KEY` | `eyJ…` (service_role JWT) | `database_service.py` | Bypasses RLS — allows server to write any row. **Never expose to Flutter** |
| `ROBOFLOW_API_KEY` | `your_key` | `detection_service.py` | Authenticates with Roboflow Inference API |
| `ROBOFLOW_MODEL_ID` | `cattle-detection/1` | `detection_service.py` | Which Roboflow model to call |
| `CAMERA_SOURCE` | `0` / `rtsp://…` / `demo` | `main.py` startup | `demo` = auto-generate synthetic detections every 5s on Railway (no real camera needed) |
| `ALERT_FEEDING_HOURS` | `12` | `main.py` | Hours between feeding alerts |
| `FRAME_INTERVAL` | `30` | `detection_service.py` | Process every Nth frame to reduce CPU load |
| `API_HOST` | `0.0.0.0` | `config.py` | Railway requires binding to 0.0.0.0 |
| `API_PORT` | `8000` | `config.py` | Railway sets `PORT` env var — use it |

> **Railway note:** Railway auto-injects `PORT`. Change `API_PORT` default to read `os.getenv("PORT", "8000")`.

### Flutter App (`.env` at project root — loaded via `flutter_dotenv`)

| Variable | Value | Used In | Purpose |
|---|---|---|---|
| `SUPABASE_URL` | `https://xyzxyz.supabase.co` | `main.dart` → `Supabase.initialize()` | Same project URL |
| `SUPABASE_ANON_KEY` | `eyJ…` (anon JWT) | `main.dart` | Client-side safe key — respects Row Level Security |

> **Security rule:** Flutter uses ANON key (RLS enforced). Python backend uses SERVICE_ROLE key (RLS bypassed for server writes).

---

## 🗄️ Supabase SQL Schema

Run this once in Supabase SQL Editor:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users profile (linked to auth.users)
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT,
  farm_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Animals registered by user
CREATE TABLE IF NOT EXISTS animals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  animal_id TEXT NOT NULL,          -- e.g. "COW-001"
  ear_tag TEXT,
  species TEXT DEFAULT 'Cow',       -- 'Cow' | 'Buffalo'
  health_status TEXT DEFAULT 'Healthy',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Real-time detections from Railway Python backend
CREATE TABLE IF NOT EXISTS cattle_detections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cattle_id TEXT NOT NULL,          -- matches animal_id
  user_id UUID REFERENCES auth.users(id),
  confidence FLOAT,
  cattle_count INT DEFAULT 1,
  buffalo_count INT DEFAULT 0,
  lameness_score FLOAT DEFAULT 0.0,
  is_lame BOOLEAN DEFAULT FALSE,
  milking_status TEXT DEFAULT 'unknown',  -- 'lactating' | 'dry' | 'unknown'
  bcs_score FLOAT,
  feeding_alert BOOLEAN DEFAULT FALSE,
  source TEXT DEFAULT 'camera',     -- 'camera' | 'demo'
  detected_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE animals ENABLE ROW LEVEL SECURITY;
ALTER TABLE cattle_detections ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Animals: only owner can read/write
CREATE POLICY "animals_owner" ON animals
  FOR ALL USING (auth.uid() = user_id);

-- Detections: users see own detections
CREATE POLICY "detections_owner" ON cattle_detections
  FOR SELECT USING (auth.uid() = user_id);

-- Allow service_role full access (bypasses RLS automatically)

-- Enable Realtime on cattle_detections
ALTER PUBLICATION supabase_realtime ADD TABLE cattle_detections;
```

---

## 📁 Files Changed / Created

### Python Backend (`python_backend/`)

| File | Action | What Changes |
|---|---|---|
| `config.py` | **Rewrite** | Add `ROBOFLOW_API_KEY`, `ROBOFLOW_MODEL_ID`, `CAMERA_SOURCE`, `ALERT_FEEDING_HOURS`, `FRAME_INTERVAL`; fix PORT env var for Railway |
| `main.py` | **Rewrite** | Remove old video upload endpoints; add `/api/detect-image` (Roboflow); add demo-mode loop; simplify to only: health, detect-image, stats, realtime WS |
| `services/detection_service.py` | **Rewrite** | Replace YOLOv8 local inference with Roboflow HTTP API; implement `demo` mode that generates synthetic detections |
| `services/database_service.py` | **Rewrite** | Use `SUPABASE_SERVICE_KEY` (not anon key); save detections to `cattle_detections` table; provide `get_daily_stats()` |
| `.env.example` | **Update** | Add all new variables with explanations |
| `requirements.txt` | **Update** | Add `roboflow`, `inference-sdk`; remove unused packages |
| `Procfile` | **Create** | `web: uvicorn main:app --host 0.0.0.0 --port $PORT` |
| `runtime.txt` | **Create** | `python-3.11.9` |

### Flutter (`lib/`)

| File | Action | What Changes |
|---|---|---|
| `pubspec.yaml` | **Update** | Add `supabase_flutter`, `flutter_dotenv`; remove `firebase_*` dependencies |
| `.env` (root) | **Create** | `SUPABASE_URL` + `SUPABASE_ANON_KEY` |
| `main.dart` | **Rewrite** | Initialize Supabase instead of Django service; load `.env`; replace providers |
| `lib/services/cattle_service.dart` | **Create** | Single service for all Supabase operations + Realtime subscription |
| `lib/providers/auth_provider.dart` | **Rewrite** | Use `supabase_flutter` auth instead of Django JWT |
| `lib/providers/cattle_provider.dart` | **Create** | Replaces `animal_provider` + `ai_detection_provider`; holds detections & stats |
| `lib/screens/dashboard/dashboard_screen.dart` | **Update** | Wire to `CattleProvider`; real-time `cattle_detections` updates |
| `lib/screens/animals/animals_list_screen.dart` | **Update** | Wire to `CattleProvider.animals` |
| `lib/screens/animals/cattle_information_screen.dart` | **Update** | Wire to `CattleProvider` |
| `lib/screens/animals/milking_cows_information_screen.dart` | **Update** | Wire to `CattleProvider` |
| `lib/core/constants/app_constants.dart` | **Update** | Point `apiBaseUrl` to Railway URL; add Supabase constants |
| **DELETED:** `lib/screens/monitoring/ai_monitoring_screen.dart` | **Delete** | Removed per requirement |
| **DELETED:** `lib/screens/video/` (entire folder) | **Delete** | Removed per requirement |
| **DELETED:** `lib/services/django_api_service.dart` | **Delete** | No longer needed |
| **DELETED:** `lib/services/firebase_service.dart` | **Delete** | No longer needed |
| **DELETED:** `lib/services/video_processing_service.dart` | **Delete** | No longer needed |
| **DELETED:** `lib/services/ml_service.dart` | **Delete** | No longer needed |
| **DELETED:** `lib/services/camera_detection_service.dart` | **Delete** | Simplified to cattle service |
| **DELETED:** `lib/providers/ai_detection_provider.dart` | **Delete** | Replaced by `cattle_provider` |

---

## 📱 New Screen Map (after cleanup)

```
HomeScreen (Scaffold with Drawer)
├── DashboardScreen          ← real-time stats from Supabase
├── AnimalsListScreen        ← CRUD list from Supabase `animals` table
├── CattleInformationScreen  ← detailed view per animal
├── MilkingCowsScreen        ← filtered from `cattle_detections`
└── SettingsScreen           ← farm name, camera source, Railway URL
```

**Removed:** `AIMonitoringScreen`, `CameraScreen`, `VideoProcessingScreen`

---

## 🔄 Data Flow (End-to-End)

```
[Railway FastAPI]
   │  every 5s in demo mode OR on real camera frame
   │  calls Roboflow API with image/frame
   │  receives detections (cattle_count, confidence, bounding boxes)
   │  runs lameness heuristic (from pose keypoints or rule-based)
   │  runs milking classifier
   │  inserts row into Supabase `cattle_detections` (using SERVICE_KEY)
   │
[Supabase Realtime]
   │  broadcasts INSERT on cattle_detections table
   │
[Flutter CattleService.subscribeToDetections()]
   │  receives realtime payload
   │  updates CattleProvider state
   │
[DashboardScreen]
   └  rebuilds with latest stats (total cattle, lameness cases, milking cows)
```

---

## 🚀 Railway Deployment Steps

1. Push `python_backend/` to a separate GitHub repo (or use monorepo)
2. Create new Railway project → "Deploy from GitHub"
3. Set **root directory** to `python_backend/`
4. Add all environment variables in Railway dashboard:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_KEY`
   - `ROBOFLOW_API_KEY`
   - `ROBOFLOW_MODEL_ID` = `cattle-detection/1`
   - `CAMERA_SOURCE` = `demo`
   - `ALERT_FEEDING_HOURS` = `12`
   - `FRAME_INTERVAL` = `30`
5. Railway auto-reads `Procfile` and starts `uvicorn`
6. Copy the Railway public URL (e.g. `https://cattle-ai.up.railway.app`)
7. Set that URL in Flutter `.env` as `PYTHON_BACKEND_URL`

---

## ✅ Implementation Order

1. **`python_backend/` rewrite** (config → detection → database → main)
2. **Supabase SQL** — run schema once
3. **Flutter pubspec** — swap Firebase for Supabase + dotenv
4. **Delete old files** — Django service, Firebase service, video screens, AI monitoring screen
5. **`CattleService`** — new unified Dart service
6. **`AuthProvider`** — rewrite for Supabase auth
7. **`CattleProvider`** — new provider wiring realtime
8. **`main.dart`** — initialize Supabase, load dotenv
9. **Screens** — dashboard, animals list, cattle info, milking cows
10. **`HomeScreen`** — remove AI monitoring tab
11. **Test** — verify realtime updates appear in Flutter when Python inserts rows

# Cattle AI Monitor — Project Documentation

**Version:** 2.0.0+4 (from `pubspec.yaml`)  
**Last updated from codebase:** June 2026  
**Repository layout:** Monorepo — Flutter client + Python FastAPI inference server + Supabase SQL migrations

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack](#2-tech-stack)
3. [Architecture & System Design](#3-architecture--system-design)
4. [Project Structure](#4-project-structure)
5. [Features (Detailed)](#5-features-detailed)
6. [API Reference](#6-api-reference)
7. [Database / Data Models](#7-database--data-models)
8. [Authentication & Authorization](#8-authentication--authorization)
9. [State Management & Data Flow](#9-state-management--data-flow)
10. [Environment Variables & Configuration](#10-environment-variables--configuration)
11. [Installation & Local Setup](#11-installation--local-setup)
12. [Deployment](#12-deployment)
13. [Known Issues / Limitations](#13-known-issues--limitations)
14. [Future Improvements](#14-future-improvements)

---

## 1. Project Overview

### What this project does

**Cattle AI Monitor** is a cross-platform farm monitoring application that uses computer vision to analyze cattle from live IP camera frames and uploaded videos. It detects ear tags, estimates body condition score (BCS), lameness, feeding behavior, and overall health, then persists results to **Supabase** for dashboards, history, and real-time updates.

The AI inference runs in a separate **Python FastAPI** process that loads PyTorch/YOLO weights from `assets/models/`. The Flutter app communicates with that backend over HTTP and with Supabase for auth, PostgreSQL storage, and realtime subscriptions.

### Core problem it solves

Manual cattle health monitoring (lameness, BCS, milking status) is slow and inconsistent at scale. This system automates visual assessment from barn cameras or phone/desktop video uploads, centralizes detection history per farmer account, and surfaces alerts (lameness, feeding, health) in a single dashboard.

### Target users and use cases

| User | Use case |
|------|----------|
| **Dairy / beef farmers** | Monitor herd health from barn cameras; review daily detections and lameness cases |
| **Farm technicians** | Upload walk-through videos for batch cattle analysis |
| **Researchers / developers** | Extend PyTorch pipelines; schema includes research-paper-aligned tables (migrations 06–07) |
| **Desktop operators (Windows)** | Primary target for live camera monitoring (`CameraScreen` is oriented to desktop IP cameras) |

---

## 2. Tech Stack

### Frontend (Flutter)

| Technology | Version (pubspec) | Role |
|------------|-------------------|------|
| **Flutter / Dart** | SDK ^3.10.1 | Cross-platform UI (Android, iOS, Windows, etc.) |
| **provider** | ^6.1.2 | App-wide state management |
| **supabase_flutter** | ^2.3.0 | Auth, Postgres client, Realtime |
| **flutter_dotenv** | ^5.1.0 | Bundled `.env.development` / `.env.production` |
| **http** | ^1.2.2 | Calls Python `/health`, `/api/analyze-*` |
| **fl_chart** | ^1.1.1 | Dashboard health charts |
| **connectivity_plus** | ^5.0.2 | Wi‑Fi-only sync gate |
| **file_picker, video_thumbnail, video_compress** | various | Video upload pipeline |
| **shared_preferences** | ^2.4.0 | Local settings + camera list + dedup hashes |
| **crypto** | ^3.0.3 | Image hash for analysis cache |
| **intl** | ^0.20.2 | i18n (en, es, fr, de, zh) |

**Why Provider:** Lightweight `ChangeNotifier` pattern already used consistently across 6 providers; no code generation, fits app size.

**Why Supabase:** Managed Postgres + Auth + Realtime + RLS; Flutter SDK handles session and row-level security with anon key.

**Why separate Python backend:** Flutter cannot load `.pth`/`.pt` PyTorch weights natively; `LocalModelService` runs YOLO + custom CNN/BiLSTM models unchanged from training.

### AI Backend (Python)

| Technology | Role |
|------------|------|
| **FastAPI** | HTTP API for inference |
| **Uvicorn** | ASGI server |
| **PyTorch / torchvision / timm** | Model loading |
| **Ultralytics YOLO** | Ear-tag detection + pose (`eartag_detector.pt`, `yolov8n-pose.pt`) |
| **Pillow, numpy** | Image decoding |

### Database & Infrastructure

| Technology | Role |
|------------|------|
| **Supabase (PostgreSQL)** | Primary data store |
| **Supabase Realtime** | Live inserts on `cattle_detections` |
| **Render** (optional) | Hosted Python backend via `render.yaml` |

### ML assets

Weights live in `assets/models/` (referenced by both Flutter bundle metadata JSON and Python `MODELS_DIR`):

- `eartag_detector.pt`, `yolov8n-pose.pt`, `behavior_classifier.pth`, `bcs_scorer.pth`, `muzzle_embedder.pth`, `lameness_detector.pth`
- Companion `*_meta.json` files define input sizes, class names, thresholds

---

## 3. Architecture & System Design

### High-level architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Flutter App (cattle_ai)                          │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────────────────┐ │
│  │   Screens   │→ │  Providers   │→ │ Services (Cattle, HTTP, AI, …) │ │
│  └─────────────┘  └──────────────┘  └───────────┬──────────┬─────────┘ │
└──────────────────────────────────────────────────│──────────│───────────┘
                                                   │          │
                    HTTP (multipart)               │          │ Supabase SDK
                    /health, /api/*                │          │ (Auth, CRUD, Realtime)
                                                   ▼          ▼
                              ┌────────────────────────┐  ┌──────────────────┐
                              │ Python FastAPI Backend │  │     Supabase     │
                              │  LocalModelService     │  │  PostgreSQL+RLS  │
                              │  PyTorch models        │  │  Realtime pub    │
                              └────────────────────────┘  └──────────────────┘
```

### Architectural patterns

| Pattern | Where |
|---------|--------|
| **Layered / feature folders** | `lib/screens`, `lib/providers`, `lib/services`, `lib/models` |
| **Repository** | `CattleAnalysisRepository` + `CattleAnalysisRepositoryImpl` abstracts HTTP model calls |
| **Provider (MVVM-ish)** | UI watches `ChangeNotifier` providers |
| **Monorepo** | Flutter + `python_backend/` + `supabase/migrations/` in one repo |
| **Gate / fail-fast** | `_BackendGate` in `main.dart` blocks app until Python `/health` succeeds |

### Major module interactions

1. **Startup:** `main.dart` → load dotenv → `Supabase.initialize` → `BackendConnectionProvider.check()` → `_AuthWrapper` → `HomeScreen`.
2. **Live camera:** `CameraProvider` → `CameraService` (MJPEG/snapshot stream) → periodic `_runAnalysis` → `HttpModelService.analyzeImage` → `CattleService.insertDetection` → Supabase Realtime → `CattleProvider`.
3. **Video upload:** `CameraScreen` → `CameraProvider.processVideoFile` → extract frames (`VideoPreviewService`) → `HttpModelService.analyzeVideoFile` → batch insert `cattle_detections` + optional `AiStorageService.saveVideoAnalysesBatchFast` → `CattleProvider.ingestDetections`.
4. **Dashboard:** `CattleProvider.todaysDetections` + `DashboardStats.fromDetections` → `DashboardScreen` charts/tables.

### Data flow (user → output)

```
User uploads video / live frame
        │
        ▼
Flutter extracts JPEG bytes (camera frame or FFmpeg/video_thumbnail)
        │
        ▼
POST → Python /api/analyze-image or /api/analyze-video-preview
        │
        ▼
LocalModelService: detect cattle regions → run 5 model heads → JSON
        │
        ▼
Flutter maps to VideoAnimalDetection / CattleAnalysisResult
        │
        ├──► cattle_detections (dashboard rows, realtime)
        ├──► animals (auto-register ear tag if missing)
        └──► cattle_ai_analyses + bcs/feeding/lameness/vet tables (if enabled)
        │
        ▼
Dashboard / Animals / Milking screens refresh via Provider + Realtime
```

---

## 4. Project Structure

Source-focused tree (excludes `build/`, `.dart_tool/`, `python_backend/.venv/`).

```
cattle-ai/
├── lib/                              # Flutter application
│   ├── main.dart                     # Entry: dotenv, Supabase, BackendGate, MultiProvider
│   ├── config/
│   │   └── app_config.dart           # Cache/camera timing constants
│   ├── core/
│   │   ├── app_messenger.dart        # Global ScaffoldMessenger key
│   │   ├── config/backend_config.dart # Local backend URL resolution (platform-aware)
│   │   ├── constants/                # Table names, health enums
│   │   ├── theme/                    # AppTheme, extensions
│   │   ├── ui/                       # Skeleton, error/empty views, stat cards, swiper
│   │   └── utils/                    # cattle_id_util, status formatting, helpers
│   ├── data/repositories/
│   │   └── cattle_analysis_repository_impl.dart  # HTTP + cache wrapper
│   ├── domain/
│   │   ├── exceptions/analysis_exceptions.dart
│   │   └── repositories/cattle_analysis_repository.dart
│   ├── l10n/
│   │   └── app_localizations.dart    # 5-language strings (inline map)
│   ├── models/                       # Dart data classes (see §7)
│   ├── providers/                    # ChangeNotifier state (see §9)
│   ├── screens/
│   │   ├── auth/                     # login, signup
│   │   ├── backend/                  # BackendOfflineScreen (startup gate)
│   │   ├── home/                     # HomeScreen shell (5 tabs)
│   │   ├── dashboard/                # Stats, charts, today's detections
│   │   ├── animals/                  # List, cattle info, milking views
│   │   ├── cameras/                  # IP cameras + video upload
│   │   └── settings/                 # Preferences UI
│   ├── services/                     # Supabase, HTTP, AI storage, video, cameras
│   ├── widgets/                      # Sidebar, backend status chip, HomeShellScope
│   └── iot_simulation/               # Simulated movement data (not wired to UI)
│
├── python_backend/
│   ├── main.py                       # FastAPI app + 5 routes
│   ├── config.py                     # MODELS_DIR, weight paths, load_meta()
│   ├── requirements.txt
│   ├── render-build.sh               # Render deploy build
│   ├── services/
│   │   ├── local_model_service.py    # Full inference pipeline (~770 lines)
│   │   └── model_architectures.py    # PyTorch module definitions
│   └── README.md
│
├── supabase/
│   ├── migrations/                   # 01–11 SQL migrations
│   └── APPLY_CATTLE_DETECTIONS.sql   # Manual dashboard script
│
├── assets/
│   ├── models/                       # PyTorch weights + *_meta.json
│   └── images/                       # App icon
│
├── docs/                             # Additional guides (ARCHITECTURE, RELEASE_MODE, this file)
├── .env.development                  # Debug env (bundled)
├── .env.production                   # Release env (bundled)
├── .env.example
├── pubspec.yaml
├── render.yaml                       # Render Blueprint for Python service
└── README.md                         # Quick start (partially outdated vs current API)
```

### Key file responsibilities

| Path | Purpose |
|------|---------|
| `lib/main.dart` | App bootstrap, provider tree, backend gate, auth routing |
| `lib/services/cattle_service.dart` | Supabase CRUD for animals/detections, Realtime subscribe, stats |
| `lib/services/http_model_service.dart` | Python backend client, health check, analyze endpoints |
| `lib/services/ai_storage_service.dart` | Persist full AI JSON to `cattle_ai_analyses` + auxiliary tables |
| `lib/providers/camera_provider.dart` | IP cameras, live analysis timers, video processing orchestration |
| `lib/providers/cattle_provider.dart` | Unified animals + detections + dashboard stats + Realtime |
| `lib/services/supabase_service.dart` | **Fully commented out** — legacy wrapper, unused |

---

## 5. Features (Detailed)

### 5.1 Backend connection gate

| | |
|---|---|
| **What** | App will not proceed past splash until local Python `/health` returns `status: ok` |
| **Files** | `main.dart` (`_BackendGate`), `BackendConnectionProvider`, `BackendOfflineScreen`, `backend_status_indicator.dart` |
| **UX** | Offline screen shows URL, start command, **Try again**; after login, sidebar + app bar **AI** chip shows Online/Offline with detail sheet |

### 5.2 Authentication (email/password)

| | |
|---|---|
| **What** | Sign up, sign in, sign out, password reset, profile metadata (name, farm) |
| **Files** | `auth_provider.dart`, `login_screen.dart`, `signup_screen.dart` |
| **How** | Supabase Auth `signUp` / `signInWithPassword`; handles email-confirmation-pending state |
| **UX** | Login/signup forms; session restored on cold start |

### 5.3 Dashboard

| | |
|---|---|
| **What** | Welcome header, stat cards (total/milking/lameness), monthly chart, searchable today's detection table |
| **Files** | `dashboard_screen.dart`, `cattle_provider.dart`, `premium_stat_card.dart`, `detection_swiper.dart` |
| **Data** | `CattleProvider.todaysDetections`, `DashboardStats.fromDetections(_allDetections)` |
| **UX** | Pull-to-refresh; green dot when Realtime active; AI server status chip |

### 5.4 Animals list (CRUD)

| | |
|---|---|
| **What** | Manual animal records: add, edit, delete |
| **Files** | `animals_list_screen.dart`, `CattleProvider.addAnimal/updateAnimal/deleteAnimal`, `cattle_service.dart` |
| **Table** | `animals` |
| **UX** | Form dialogs; merged display with detection data via `cattleDisplayRows` |

### 5.5 Cattle information screen

| | |
|---|---|
| **What** | Per-animal/detection detail views, recent detection history |
| **Files** | `cattle_information_screen.dart` |
| **Data** | `CattleProvider.allDetections`, `Animal` records |

### 5.6 Milking cows information

| | |
|---|---|
| **What** | Filtered view for lactating cattle from detection history |
| **Files** | `milking_cows_information_screen.dart` |
| **Data** | `CattleProvider.milkingDetections` (`milking_status == 'lactating'`) |

### 5.7 IP camera monitoring + live AI

| | |
|---|---|
| **What** | Add MJPEG/snapshot IP cameras; periodic frame analysis |
| **Files** | `camera_screen.dart`, `camera_provider.dart`, `camera_service.dart`, `camera_model.dart` |
| **How** | Stream bytes → `analyzeImage` → optional `AiStorageService.saveAnalysis` → `insertDetection` |
| **Storage** | Camera list in `SharedPreferences`; `camera_feeds` upsert via `AiStorageService.upsertCameraFeed` |
| **UX** | Grid of feeds, connection state, analysis overlay drawer |

### 5.8 Video upload & analysis

| | |
|---|---|
| **What** | Pick video file → extract best frame(s) → multi-cattle detection → save to Supabase |
| **Files** | `camera_screen.dart` (`_showVideoUploadDialog`), `camera_provider.processVideoFile`, `video_preview_service.dart`, `video_dedup_service.dart` |
| **How** | Dedup by file hash; confidence filter from settings; batch `insertDetectionsBatch`; navigate to Dashboard tab |
| **UX** | Progress dialog; success snackbar; duplicate video rejected (`VideoAlreadyProcessedException`) |

### 5.9 Real-time detection sync

| | |
|---|---|
| **What** | New `cattle_detections` rows appear without manual refresh |
| **Files** | `cattle_service.subscribeToDetections`, `cattle_provider._handleRealtimeDetection` |
| **Requirement** | `autoSync` setting ON; Realtime publication on table (migration 11) |
| **UX** | Live indicator on dashboard; in-app notifications via `NotificationService` |

### 5.10 Settings

| | |
|---|---|
| **What** | Notifications, AI thresholds, camera FPS/quality, sync interval, Wi‑Fi-only sync, dark mode, language |
| **Files** | `settings_screen.dart`, `settings_provider.dart`, `settings_service.dart` |
| **Storage** | `SharedPreferences` only (not Supabase) |

### 5.11 Analysis result caching

| | |
|---|---|
| **What** | Avoid re-calling Python for identical frame bytes within TTL |
| **Files** | `analysis_cache_service.dart`, `cattle_analysis_repository_impl.dart` |
| **TTL** | 8 hours (`AppConfig.cacheExpiry`) |

### 5.12 Localization

| | |
|---|---|
| **What** | UI strings in English, Spanish, French, German, Chinese |
| **Files** | `app_localizations.dart`, `SettingsProvider.locale` |

### 5.13 IoT simulation (dormant)

| | |
|---|---|
| **What** | Generates synthetic step count, accelerometer, heart rate per animal |
| **Files** | `iot_simulation/iot_simulation_service.dart` |
| **Status** | **Not imported by any provider or screen** — scaffolding only |

---

## 6. API Reference

All routes are defined in `python_backend/main.py`. **No authentication** on Python endpoints — intended for trusted local network or private deploy.

### `GET /`

| | |
|---|---|
| **Response 200** | `{"status": "backend running", "backend": "pytorch"}` |

### `GET /health`

| | |
|---|---|
| **Used by** | `HttpModelService.initialize()`, `BackendConnectionProvider` |
| **Response 200** | `{ "status": "ok" \| "loading", "env", "models_dir", "backend": "pytorch", "weights": [6 filenames] }` |
| **Note** | Flutter treats `status != "ok"` as not ready (models still loading) |

### `POST /api/count-cattle`

| | |
|---|---|
| **Body** | `multipart/form-data`, field `image` (file) |
| **Response 200** | `{"cattle_count": int}` |
| **Errors** | 400 empty upload; 422 no cattle; 500 server error |

### `POST /api/analyze-image`

| | |
|---|---|
| **Body** | `multipart/form-data`, field `image` (JPEG) |
| **Response 200** | Full analysis object: `image_hash`, `cattle_id`, `eartag`, `muzzle`, `bcs`, `lameness`, `feeding`, `overall_health` (see `LocalModelService._merge_partials`) |
| **Errors** | 422 `No cattle found in this image`; 400 other ValueError; 500 |

### `POST /api/analyze-video-preview`

| | |
|---|---|
| **Body** | `preview` (file) + `video_file_name` (form string, default `video.mp4`) |
| **Response 200** | `{ "cattle_count", "buffalo_count": 0, "video_file_name", "animals": [{ cattle_id, milking_status, bcs_score, lameness_score, is_lame, confidence, feeding_alert, health_status }] }` |
| **Errors** | Same as analyze-image |

### Flutter client timeouts (`BackendConfig`)

| Setting | Value |
|---------|-------|
| Health timeout | 10 s |
| Health retries | 3 × 2 s delay |
| Analyze timeout | 2 minutes |

### Supabase (client-side, not REST document here)

Flutter uses `supabase_flutter` with **anon key** and RLS — see §8. No custom REST layer in the app.

---

## 7. Database / Data Models

Migrations are incremental; **production apps must apply 01–11** (and resolve duplicate `09_*` ordering manually if needed). The **actively used** Flutter tables are:

### `animals` (migration 01, extended in 04/08)

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| animal_id | VARCHAR(20) UNIQUE | Ear tag / human ID |
| species, age, health_status | | Required on create |
| user_id | UUID FK → auth.users | RLS: `auth.uid() = user_id` |
| ear_tag, breed, weight, notes, image_url | | Optional |
| milking_status | VARCHAR(20) | Added in 08: `milking/dry/unknown` |

**Dart model:** `lib/models/animal.dart`

### `cattle_detections` (migration 11) — **primary dashboard feed**

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| cattle_id | TEXT | Ear tag or `VID-NNN` placeholder |
| user_id | UUID FK | RLS SELECT/INSERT own rows |
| confidence, bcs_score, lameness_score | FLOAT | |
| is_lame, feeding_alert | BOOLEAN | |
| milking_status | TEXT | `lactating`, `dry`, `unknown` |
| source | TEXT | `video_upload`, `camera`, etc. |
| detected_at | TIMESTAMPTZ | |

**Realtime:** `ALTER PUBLICATION supabase_realtime ADD TABLE cattle_detections`

**Dart model:** `CattleDetection` in `cattle_service.dart`

### `cattle_ai_analyses` (migration 10, RLS in 11)

Stores denormalized AI fields + `full_result JSONB` per frame. Linked to `animals.id` via `animal_id` UUID when resolvable.

**Written by:** `AiStorageService` when `saveProcessedVideos` setting is true.

### Auxiliary AI tables (migration 04, written by `AiStorageService`)

| Table | Purpose |
|-------|---------|
| `camera_feeds` | Registered IP cameras |
| `bcs_records` | BCS history per animal |
| `feeding_records` | Behavior sessions |
| `lameness_records` | Lameness events |
| `veterinary_alerts` | Critical/urgent alerts |

### Legacy / research schemas (migrations 01–07)

| Table(s) | Status in app |
|----------|----------------|
| `movement_data`, `video_records` | Schema exists; limited/no active Flutter writes |
| `cow`, `ear_tag_camera`, `depth_camera`, … | Research paper schema (06–07); not used by current Flutter services |
| `milking_status` | Separate table in 08; app uses detection column instead |
| `user_profiles` | Trigger on signup (09); profile updates go to Auth metadata in app |

### Dart models (reference)

| File | Role |
|------|------|
| `cattle_analysis_result.dart` | Full live-analysis shape (EarTag, Bcs, Lameness, …) |
| `video_analysis_result.dart` | Video batch results + `toDetectionRow()` |
| `camera_model.dart` | IP camera state, frames, last analysis |
| `user_model.dart` | Auth user wrapper |
| `ai_models.dart`, `research_models.dart` | Schema-aligned documentation types |

---

## 8. Authentication & Authorization

### Implementation

- **Provider:** Supabase Auth via `supabase_flutter`
- **Flow:** `AuthProvider.initialize()` restores `currentSession`, listens to `onAuthStateChange`
- **Credentials:** Email + password only (no OAuth in code)
- **Profile:** `name`, `farm_name` stored in `user.userMetadata` via `updateUser`

### Roles and permissions

**No custom roles** in application code. Security is **Supabase RLS**:

- All farmer data scoped by `user_id = auth.uid()`
- Flutter uses **anon key** — users can only access their rows
- Python backend has **no Supabase service role** in current `main.py` — it does not write to DB

### Protected resources

| Resource | Protection |
|----------|------------|
| Supabase tables | RLS policies per migration |
| Python API | None (local trust model) |
| App screens | `_AuthWrapper` shows `LoginScreen` when `!isAuthenticated` |
| Backend gate | Runs **before** auth — Python must be up first |

---

## 9. State Management & Data Flow

### Provider registry (`main.dart`)

| Provider | Responsibility |
|----------|----------------|
| `BackendConnectionProvider` | Python `/health`, 45 s background ping, reconnect |
| `AuthProvider` | Session, login/signup/logout errors |
| `CattleProvider` | Animals, detections (today + all), stats, Realtime, sync timer |
| `SettingsProvider` | UI wrapper over `SettingsService` |
| `CattleAnalysisProvider` | Single-image analysis UI state (loading/result/report) |
| `CameraProvider` | Cameras, streams, live + video processing |

`AnimalProvider` re-exports `CattleProvider` for backward compatibility.

### Key data flows

**Realtime detection insert**

```
Supabase INSERT cattle_detections
  → Realtime callback (cattle_service.dart)
  → CattleProvider._handleRealtimeDetection (dedupe by id)
  → ingestDetections → notifyListeners
  → Dashboard / Animals rebuild
```

**Settings change affecting sync**

```
SettingsProvider → CattleProvider.applySyncSettings()
  → stop/start Realtime channel + periodic loadDetections timer
```

**Video upload success**

```
CameraProvider.processVideoFile → insertDetectionsBatch
  → camera_screen calls CattleProvider.ingestDetections + loadAnimals
  → HomeShellScope.setTab(0)  // Dashboard
```

### Local persistence (non-Supabase)

| Key | Service |
|-----|---------|
| Settings | `SharedPreferences` via `SettingsService` |
| Analysis cache | Disk + memory, MD5 key |
| IP cameras | `SharedPreferences` JSON list |
| Processed video hashes | `VideoDedupService` |

---

## 10. Environment Variables & Configuration

### Flutter (`.env.development` / `.env.production`, bundled in `pubspec.yaml`)

| Variable | Required | Used in | Purpose |
|----------|----------|---------|---------|
| `APP_ENV` | Optional | `BackendConfig` (legacy) | `development` / `production` label |
| `SUPABASE_URL` | **Yes** | `main.dart` | Supabase project URL |
| `SUPABASE_ANON_KEY` | **Yes** | `main.dart` | Public anon JWT for client |
| `LOCAL_MODEL_BACKEND_URL` | **Yes** | `BackendConfig.modelBackendUrl` | Python server base URL |
| `MODEL_BACKEND_URL` | No | Unused in current local-only config | Legacy Render URL |
| `RENDER_MODEL_BACKEND_URL` | No | Unused | Legacy Render URL |

**Platform URL resolution** (`backend_config.dart`):

- Windows/desktop: `http://127.0.0.1:8000`
- Android emulator: auto-maps `127.0.0.1` → `http://10.0.2.2:8000`
- Physical Android: set PC LAN IP in `LOCAL_MODEL_BACKEND_URL`

**Load order:** debug → `.env.development`; release → `.env.production`; fallback `.env`. Override with `--dart-define=ENV_FILE=...`.

### Python (`python_backend/.env.example`)

| Variable | Default | Purpose |
|----------|---------|---------|
| `ENV` | `development` | Logged in `/health` |
| `PORT` | `8000` | Uvicorn bind port |
| `MODELS_DIR` | `assets/models` | Weight directory (repo-relative) |
| `ALLOWED_ORIGINS` | `*` | CORS origins (comma-separated) |

### Render (`render.yaml`)

Sets `PYTHON_VERSION=3.11.0`, `MODELS_DIR`, `ENV=production`, `WEB_CONCURRENCY=1`, `ALLOWED_ORIGINS=*`.

---

## 11. Installation & Local Setup

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | 3.10+ |
| Dart | 3.10+ |
| Python | 3.10+ (3.11 on Render) |
| Supabase project | Free tier OK |
| FFmpeg | Recommended for video frame extraction on desktop |
| GPU | Optional; backend uses CUDA if available else CPU |

### 1. Clone and install Flutter deps

```bash
git clone <repository-url>
cd cattle-ai
flutter pub get
```

### 2. Configure Flutter environment

```bash
cp .env.example .env.development
# Edit SUPABASE_URL, SUPABASE_ANON_KEY, LOCAL_MODEL_BACKEND_URL
```

Ensure model metadata is present under `assets/models/` (weights may be large — obtain per project README / Kaggle export docs).

### 3. Apply Supabase migrations

In **Supabase Dashboard → SQL Editor**, run migrations in order:

`01_create_tables.sql` → `02_enable_rls.sql` → … → `11_cattle_detections.sql`

If `cattle_detections` already exists without Realtime:

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE cattle_detections;
```

Or run `supabase/APPLY_CATTLE_DETECTIONS.sql` as a consolidated script.

### 4. Start Python backend

```bash
pip install -r python_backend/requirements.txt
python -m uvicorn python_backend.main:app --host 0.0.0.0 --port 8000
```

Verify:

```bash
curl http://127.0.0.1:8000/health
# Expect: "status": "ok"
```

### 5. Run Flutter app

```bash
# Debug
flutter run

# Windows release
flutter build windows --release

# Android
flutter run -d android
```

**Startup order:** Python backend **first**, then Flutter. App shows `BackendOfflineScreen` until `/health` succeeds.

### 6. Create account

Use **Sign up** in app → confirm email if Supabase confirmation is enabled → sign in.

---

## 12. Deployment

### Flutter client

| Platform | Command | Notes |
|----------|---------|-------|
| Android | `flutter build apk --release` | Set `LOCAL_MODEL_BACKEND_URL` to PC IP for field testing |
| Windows | `flutter build windows --release` | Output in `build/windows/x64/runner/Release/` |
| iOS / macOS / Linux | Standard Flutter build | Camera/video features vary by platform |

Bundled env: `.env.production` is included as a Flutter asset.

### Python backend

**Local (current default):** Run on farmer/dev PC with `--host 0.0.0.0` so mobile devices on LAN can reach it.

**Render (optional, `render.yaml`):**

1. Connect GitHub repo → New Blueprint
2. Service `cattle-ai-backend` builds via `python_backend/render-build.sh`
3. Starts `uvicorn python_backend.main:app` on `$PORT`
4. Health check: `/health`
5. **Note:** Current Flutter config uses **local backend only**; Render deploy is available but not wired in `.env.production` by default

### Supabase

- Hosted; no self-deploy
- Enable Realtime on `cattle_detections`
- Configure Auth email templates / redirect URLs for production

### Not deployed from this repo

- No Dockerfile in root (Render uses native Python runtime)
- No CI/CD workflows found in explored tree

---

## 13. Known Issues / Limitations

| Issue | Evidence |
|-------|----------|
| **README API list is outdated** | README lists `/api/detect`, WebSockets, etc.; actual API has 5 HTTP routes in `main.py` |
| **`supabase_service.dart` is dead code** | Entire file commented out |
| **IoT simulation unused** | `IoTSimulationService` not referenced by providers/screens |
| **Research schema unused by Flutter** | Migrations 06–07 tables not queried in `lib/services/` |
| **Ear-tag OCR is placeholder** | Python uses random `ET-XXXX` when OCR not implemented |
| **Physical Android requires LAN IP** | `127.0.0.1` does not reach host PC without explicit env |
| **Migration conflicts** | Two `09_*.sql` files; duplicate storage policy names possible between 03 and 09 |
| **`dashboard_statistics` view** | Migration 04 references columns that may not exist (`detected_at`, `is_milking`) |
| **No on-device inference** | Release builds still need Python server; `.pth` not runnable in Dart (see `docs/RELEASE_MODE_ON_DEVICE_MODELS.md`) |
| **Camera screen desktop-oriented** | Comment in `camera_screen.dart`: "Windows desktop only" for live monitoring |
| **Python backend has no auth** | Any client on network can call inference endpoints |
| **Dual notification paths** | Live camera may notify via Realtime; video upload notifies via `ingestDetections` (deduped in Realtime handler) |

---

## 14. Future Improvements

Based on codebase gaps and existing docs:

1. **On-device inference** — Export models to TFLite/ONNX per `docs/RELEASE_MODE_ON_DEVICE_MODELS.md`; remove Python dependency for release mobile builds.
2. **Wire IoT simulation or remove it** — Either connect `IoTSimulationService` to dashboard charts or delete unused code.
3. **Real ear-tag OCR** — Replace placeholder IDs in `LocalModelService._predict_eartag`.
4. **Consolidate Supabase schema** — Choose `animals` vs research `cow` model; drop unused tables or generate typed Dart from one schema.
5. **Secure Python API** — API key or mTLS when backend exposed beyond localhost.
6. **Revive or delete `supabase_service.dart`** — Reduce confusion for contributors.
7. **Automated migration runner** — Supabase CLI + single ordered migration chain (fix `09` duplicate prefix).
8. **Integration tests** — Mock `HttpModelService` and Supabase for provider/widget tests (only `test/widget_test.dart` exists today).
9. **Offline queue** — Buffer detections when Supabase unreachable; sync when online.
10. **Update root README** — Align endpoint table and architecture diagram with `main.py` and local-backend-first config.

---

## Appendix: Quick reference commands

```bash
# Backend
python -m uvicorn python_backend.main:app --host 0.0.0.0 --port 8000

# Flutter debug
flutter run

# Analyze Dart
dart analyze lib/

# Health check
curl http://127.0.0.1:8000/health
```

---

*This document is generated from the repository source at `cattle-ai` v2.0.0+4. For ML export and on-device roadmap, see `docs/RELEASE_MODE_ON_DEVICE_MODELS.md` and `python_backend/README.md`.*

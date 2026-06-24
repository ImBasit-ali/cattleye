# Cattle AI Monitor 🐄📱

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart)](https://dart.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109+-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![YOLOv8](https://img.shields.io/badge/YOLOv8-Ultralytics-FF6B35)](https://ultralytics.com)

> **IoT-Based Cattle Monitoring System** with AI-powered lameness detection, real-time movement analysis, and comprehensive health tracking.

---

## ✨ Key Features

- 🐄 **Animal Identification** — Unique tracking with QR/RFID ready
- 📊 **Movement Analysis** — Real-time activity monitoring with IoT simulation
- 🤖 **AI Lameness Detection** — YOLOv8 pose estimation + gait analysis
- 🥛 **Milking Status Detection** — Automated lactating/dry classification
- 📸 **Video Processing** — Upload and analyze cattle movement videos
- 🌐 **Real-time Streaming** — WebSocket-based live camera feed processing
- 📈 **Interactive Charts** — Daily/weekly health trends visualization
- 🎨 **Professional UI** — Glassy design with smooth animations
- 🖥️ **Multi-Platform** — Android, iOS, Web, Windows, Linux, macOS

---

## 🏗️ Architecture

```
AI-Cattle-Monitoring-System/
├── lib/                    # Flutter frontend (Dart)
│   ├── core/               # Constants, theme, utilities
│   ├── models/             # Data models
│   ├── services/           # Supabase & API services
│   ├── providers/          # State management (Provider)
│   ├── screens/            # UI screens
│   └── main.dart           # Entry point
│
├── python_backend/         # FastAPI AI backend (Python)
│   ├── main.py             # FastAPI app & all endpoints
│   ├── config.py           # Environment configuration
│   ├── services/           # Detection, tracking, milking, lameness
│   ├── models/             # Pydantic schemas
│   ├── requirements.txt    # Python dependencies
│   └── .env                # Backend environment variables
│
└── supabase/               # Database schema & migrations
```

---

## 🔧 Tech Stack

| Layer       | Technology                              |
|-------------|-----------------------------------------|
| **Frontend**  | Flutter, Dart, Provider              |
| **AI Backend**| FastAPI, Uvicorn, WebSockets         |
| **ML / Vision** | YOLOv8 (Ultralytics), OpenCV, PyTorch |
| **Database**  | Supabase (PostgreSQL)                |
| **Storage**   | Supabase Storage                     |
| **Auth**      | Supabase Auth                        |
| **Charts**    | FL Chart, Syncfusion                 |

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.10+
- Python 3.10+
- A [Supabase](https://supabase.com) project

---

### 1. Flutter Frontend

```bash
# Install Flutter dependencies
flutter pub get

# Run the app
flutter run
```

---

### 2. FastAPI Python Backend

```bash
cd python_backend

# Create and activate virtual environment
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # macOS / Linux

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your Supabase credentials and settings

# Start the server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

The API will be available at `http://localhost:8000`.  
Interactive docs at `http://localhost:8000/docs`.

---

### 3. Environment Variables

**`python_backend/.env`**

```env
# API Settings
API_HOST=0.0.0.0
API_PORT=8000
API_RELOAD=true

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key

# ML Models
YOLO_MODEL_PATH=yolov8n.pt
YOLO_POSE_MODEL_PATH=yolov8n-pose.pt

# Camera
CAMERA_FPS=10
```

---

## 📡 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | Health check |
| `GET` | `/health` | Detailed service health |
| `POST` | `/api/detect` | Detect animals in image |
| `POST` | `/api/detect-video` | Detect & track animals in video |
| `POST` | `/api/video/process` | Full ML pipeline (detection + milking + lameness) |
| `POST` | `/api/milking/detect` | Detect milking status from image |
| `POST` | `/api/lameness/detect` | Detect lameness from gait video |
| `GET` | `/api/tracking/stats` | Tracking statistics |
| `GET` | `/api/tracking/animals` | Currently tracked animals |
| `GET` | `/api/stats/daily` | Daily statistics |
| `GET` | `/api/stats/health` | Health monitoring statistics |
| `WS` | `/ws/camera/{camera_id}` | Real-time camera stream |

---

## 🛠️ Windows Build Troubleshooting

### CMake / Firebase compatibility error

If the Windows build fails with:

```
Compatibility with CMake < 3.5 has been removed from CMake
```

Add this line near the top of [`windows/CMakeLists.txt`](windows/CMakeLists.txt) (after `cmake_minimum_required`):

```cmake
set(CMAKE_POLICY_VERSION_MINIMUM 3.5)
```

Then rebuild:

```bash
flutter clean
flutter pub get
flutter build windows --debug
```

> `LNK4099` warnings from Firebase/native libraries in Debug builds are non-fatal and can be safely ignored.

---

## 📚 Documentation

- **[Project Documentation (full)](docs/PROJECT_DOCUMENTATION.md)** — architecture, API, database, setup, deployment
- [ML Pipeline Guide](python_backend/SETUP_YOLOV8.md)
- [Python Backend README](python_backend/README.md)
- [Release / on-device models](docs/RELEASE_MODE_ON_DEVICE_MODELS.md)
- [Database Schema](supabase/)

---

**Made with ❤️ for cattle welfare and farming innovation**

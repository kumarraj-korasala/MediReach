# MediReach — Digital Rural Healthcare & Care-Continuity Platform

[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![WebRTC](https://img.shields.io/badge/WebRTC-333333?logo=webrtc&logoColor=white)](https://webrtc.org)
[![SQLite](https://img.shields.io/badge/SQLite-003B57?logo=sqlite&logoColor=white)](https://sqlite.org)

MediReach is an offline-first, production-grade digital healthcare continuity and tele-triage platform designed for underserved, remote, and bandwidth-constrained rural environments. It combines a feature-rich Flutter client with an SQLite local-first database, a Node.js API Gateway, Python FastAPI ML microservices for clinical decision support, and low-latency WebRTC teleconsultation.

---

## Key Features

- 🏥 **Offline-First Data Layer**: Full relational SQLite storage with automatic background synchronization when network connectivity is restored.
- 🩺 **Clinical Vitals & Dual-Layer Triage**: Deterministic clinical safety rules backed by machine learning models for early risk detection.
- 🔄 **Closed-Loop Referral Lifecycle**: QR-code referral tokens with end-to-end facility tracking and state persistence.
- 📹 **Adaptive WebRTC Teleconsultation**: Low-latency peer-to-peer audio/video calling with network-adaptive bitrates (5G, 4G, 3G, and 2G Voice-only fallback).
- 🌐 **Multilingual Localization & TTS**: Real-time Telugu, Hindi, and English support with text-to-speech narration for low-literacy patients.
- 💊 **Pharmacy Inventory & Diagnostics**: Real-time drug stock search and digital diagnostic test reports.
- 🛡️ **ABHA Digital Health ID Integration**: M4/M5 compliance scaffolding for Indian National Health Stack interoperability.

---

## System Architecture

```text
               +--------------------------------------------------+
               |              Flutter Mobile Client               |
               |  (Local SQLite DB, WebRTC, TTS, QR Scanner, UI)  |
               +-------------------+------------------------------+
                                   |
                     HTTPS / WSS   |   (Auto-Discovered Cloudflare Tunnel)
                                   v
+-------------------------------------------------------------------------+
|                         Local / Cloud Backend                           |
|                                                                         |
|  +---------------------+   Internal HTTP   +-------------------------+  |
|  |   Node.js Gateway   | ----------------> |  Python ML Microservice |  |
|  |     (Port 5000)     |                   |       (Port 8001)       |  |
|  +----------+----------+                   +-------------------------+  |
|             |                                                           |
|             +---------> Supabase Cloud (PostgreSQL, Storage, Auth)      |
|                                                                         |
|  +-------------------------------------------------------------------+  |
|  |               Python WebRTC Signaling Server (Port 8000)          |  |
|  +-------------------------------------------------------------------+  |
+-------------------------------------------------------------------------+
```

---

## Repository Structure

```text
├── android/                   # Native Android configuration & wrappers
├── assets/images/             # App icons, vectors, and UI illustrations
├── backend/
│   ├── database/              # Supabase SQL schemas & Firebase setup guides
│   ├── ml_service/            # Python FastAPI ML microservice (Triage, NLP)
│   ├── node_api/              # Node.js Express Gateway (Auth, Sync, ABHA)
│   │   ├── .env.example       # Template for backend environment variables
│   │   ├── routes/            # REST API route handlers
│   │   └── server.js          # Express gateway entry point
│   ├── requirements.txt       # WebRTC signaling Python dependencies
│   └── server.py              # WebRTC signaling server
├── ios/                       # Native iOS configuration
├── lib/                       # Flutter Core application code
│   ├── core/                  # Audio/TTS, localization, API client, theme
│   ├── data/                  # SQLite helper, repositories, models
│   ├── features/              # Feature screens (Triage, Patient, Teleconsult, etc.)
│   └── views/                 # Authentication & onboarding pages
├── MASTER_ARCHITECTURE.md     # Deep-dive architecture & data flows
├── PROJECT_DOCUMENTATION.md   # Complete system specification
└── start_servers.bat          # 1-click launcher for all 3 backend services
```

---

## Getting Started

### 1. Prerequisites
- **Flutter SDK**: `>= 3.3.0`
- **Node.js**: `>= 18.x`
- **Python**: `>= 3.10`
- **Cloudflared** *(Optional, for remote device testing)*:
  ```bash
  winget install --id Cloudflare.cloudflared
  ```

---

### 2. Backend Setup

#### A. Node.js Gateway
```bash
cd backend/node_api
npm install
cp .env.example .env
# Edit .env and fill in your Supabase credentials & JWT secret
```

#### B. Python WebRTC & ML Services
```bash
# Setup Python virtual environment
cd backend
python -m venv venv

# Windows activate:
.\venv\Scripts\activate
# macOS/Linux activate:
# source venv/bin/activate

# Install signaling server dependencies
pip install -r requirements.txt

# Install ML service dependencies
pip install -r ml_service/requirements.txt
```

---

### 3. Running the Backend Services

#### Option A: Quick Launch (Windows)
Double-click `start_servers.bat` or run:
```cmd
start_servers.bat
```
To stop all servers and release ports:
```cmd
stop_servers.bat
```

#### Option B: Manual Execution
Open three separate terminal tabs:

1. **Node.js API Gateway** (Port 5000):
   ```bash
   cd backend/node_api && npm start
   ```
2. **Python WebRTC Signaling** (Port 8000):
   ```bash
   cd backend && python -m uvicorn server:app --host 0.0.0.0 --port 8000
   ```
3. **Python Clinical ML Microservice** (Port 8001):
   ```bash
   cd backend/ml_service && python -m uvicorn ml_server:app --host 0.0.0.0 --port 8001
   ```

---

### 4. Remote Device Tunneling (Optional)
To expose the local API gateway to real mobile devices on cellular data or outside the local Wi-Fi:
```cmd
start_tunnel.bat
```
This launches a Cloudflare Tunnel and automatically registers the live public endpoint in Supabase.

---

### 5. Running the Flutter App

```bash
# From the project root
flutter pub get
flutter run
```

---

## Documentation

- **[MASTER_ARCHITECTURE.md](MASTER_ARCHITECTURE.md)**: Comprehensive architectural blueprint, protocol specifications, SQLite relational schemas, and sync conflict resolution strategies.
- **[PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md)**: Complete system design document and component inventory.

---

## Security & Privacy Note
Never commit `.env` configuration files, Firebase service account keys, or mobile keystores. This repository includes strict `.gitignore` rules and sample templates (`.env.example`) for secure local onboarding.

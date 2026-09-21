# MediReach — Digital Rural Healthcare & Care-Continuity Platform

A production-grade, offline-first digital healthcare continuity and tele-triage platform built with Flutter, SQLite, Node.js API Gateway, Python FastAPI ML Microservices, and WebRTC.

## Key Features
* 🏥 **Offline-First Patient Records & SQLite Data Layer**: Full relational data storage with automatic batch synchronization.
* 🩺 **Clinical Vitals & Dual-Layer Triage**: Deterministic safety rules and ML risk classification.
* 🔄 **Closed-Loop Referral Lifecycle**: Cryptographic QR referral tokens with real-time transfer tracking.
* 📹 **WebRTC Video & Audio Calling**: Low-latency P2P calling powered by `flutter_webrtc` and Metered TURN cloud relays.
* 📶 **Adaptive Network Profile Engine**: Dynamic resolution & bitrate adaptation for 5G, 4G, 3G, and Edge/Voice-Only networks.
* 🌐 **Multilingual Localization & TTS**: Instant English, Telugu, and Hindi translation with speech readout for low-literacy patients.
* 💊 **Pharmacy Inventory & Diagnostics**: Real-time essential drug stock search and clinical laboratory report registry.

For the complete architectural design, database schemas, RBAC matrix, and API references, see [MASTER_ARCHITECTURE.md](MASTER_ARCHITECTURE.md).


cd c:\Users\kumar\StudioProjects\miracle\backend\node_api
npm start


cd c:\Users\kumar\StudioProjects\miracle\backend
venv\Scripts\uvicorn.exe server:app --host 0.0.0.0 --port 8000


cd c:\Users\kumar\StudioProjects\miracle\backend\ml_service
..\venv\Scripts\uvicorn.exe ml_server:app --host 0.0.0.0 --port 8001


cd c:\Users\kumar\StudioProjects\miracle
.\cloudflared.exe tunnel --url http://localhost:5000

# Miracle (Medicare - SIH2026 P-133) Project Documentation

## 📌 Project Overview
**Miracle (Medicare)** is a state-of-the-art tele-health and real-time medical communication application developed for **Smart India Hackathon (SIH 2026 - Problem Statement 133)**. 

The platform connects healthcare workers—including **Auxiliary Nurse Midwives (ANMs)**, **Doctors**, **Nurses**, and **Patients/Users**—via real-time end-to-end encrypted video/audio consultations, instant messaging, and secure file sharing.

Designed specifically for real-world field conditions, Miracle includes a proprietary **Adaptive Network Profile Engine** that dynamically adjusts resolution, frame rate, and bitrate to maintain clear communication across **5G, 4G, 3G, and low-bandwidth edge networks**.

---

## 🚀 Key Features

### 1. 🔐 Role-Based Authentication & Onboarding
* **Glassmorphism Design**: Sleek, modern blurred translucent glass cards (`BackdropFilter`) for Login and Signup screens.
* **Healthcare Persona Selection**: Support for **ANM**, **Doctor**, **Nurse**, and **General User** roles.
* **ABHA ID Integration**: Field for **Ayushman Bharat Health Account (ABHA)** identifier to ensure seamless alignment with national health stack data standards.
* **Admin vs User Toggle**: Built-in access control mode switching.

### 2. 📹 Real-Time WebRTC Video & Audio Calling
* **Peer-to-Peer Calls**: Built with `flutter_webrtc` using Unified-Plan SDP semantics.
* **Metered TURN/STUN Cloud Relay**: Production-grade TURN credential integration (`medicare.metered.live`) supporting UDP, TCP (`?transport=tcp`), and TLS (`turns:`), with automatic fallback to Metered open relay (`relay.metered.ca`).
* **Robust ICE Candidate Management**: Queuing mechanism (`_pendingIceCandidates`) that buffers candidate messages arriving before `setRemoteDescription()`, eliminating signaling race conditions.
* **Full In-Call Control Suite**:
  * Microphone Mute/Unmute
  * Video Camera Toggle
  * Front / Rear Camera Switch
  * Speakerphone Toggle
  * ICE Manual Reconnect (`restartIce()`)
* **Incoming Call Alerts**: Non-intrusive modal dialogs showing caller identity, call type, decline, and accept options.

### 3. 📶 Adaptive Network Profile Engine
Dynamic bitrate and video encoder control matching mobile connection quality:
* 🟢 **5G / Fiber HD**: 2.5 Mbps | 30 fps | Full HD resolution (1.0x scale)
* 🔵 **4G / LTE Balanced**: 800 kbps | 24 fps | Standard mobile video (1.25x scale)
* 🟡 **3G / Low Bandwidth**: 250 kbps | 15 fps | Data saver mode (2.0x scale)
* 🟠 **Voice-Only Saver**: Disables video streams to keep crystal-clear audio at ~30 kbps on weak mobile edge signals.

### 4. 💬 WhatsApp-Style Chat & Attachment Sharing
* **Instant Messaging**: Real-time peer-to-peer text messages via WebSockets (`ChatPage`).
* **Rich Attachments**: Send and receive Photos, Documents (PDFs, files), Audio clips, and Video files.
* **In-Chat Media Viewers**: Native Base64 encoding/decoding with image preview cards and direct device file downloads (`FileTransferService`).
* **System Notifications**: In-app SnackBar alerts for incoming messages and file transfers while on other screens.

### 5. ⚡ FastAPI Asynchronous Signaling Backend
* **Python Backend**: High-concurrency **FastAPI** + **Uvicorn** server (`backend/server.py`).
* **WebSocket Router (`/ws/calls`)**: Real-time WebSocket multiplexing for SDP offers/answers, ICE candidate relaying, text chats, and file payloads.
* **Heartbeat & Status Monitoring**: Built-in ping/pong keepalives and online/offline user discovery.

---

## 🛠️ Architecture & Project Structure

```
miracle/
├── backend/
│   ├── server.py              # FastAPI WebSocket signaling server
│   ├── requirements.txt        # Python dependencies (fastapi, uvicorn, websockets)
│   └── venv/                  # Python Virtual Environment
├── lib/
│   ├── main.dart              # Application entry point & theme management
│   ├── data/
│   │   ├── constants.dart     # UI styling & text constants
│   │   └── notifiers.dart     # Global ValueNotifiers (dark mode, page selection)
│   ├── features/
│   │   └── calling/
│   │     ├── active_call_page.dart     # WebRTC call UI & controls
│   │     ├── chat_page.dart            # Messaging & file sharing UI
│   │     ├── file_transfer_service.dart # File picking, base64 encoding & storage
│   │     ├── signaling_service.dart    # WebSocket client manager
│   │     └── webrtc_service.dart       # PeerConnection & media track orchestrator
│   └── views/
│       ├── widget_tree.dart   # Main app scaffold & navbar container
│       ├── pages/
│       │   ├── home_page.dart          # Home dashboard
│       │   ├── login_page.dart         # Glassmorphism login screen
│       │   ├── profile_page.dart       # User profile details & logout
│       │   ├── settings_page.dart      # Application settings
│       │   ├── signup_page.dart        # Account registration with ABHA ID
│       │   ├── videocall_page.dart     # Network setup, direct call & speed dial hub
│       │   └── welcome_page.dart       # App splash & getting started screen
│       └── widgets/
│           ├── hero_widget.dart        # Custom branding widget
│           └── navbar.dart             # Bottom navigation bar
└── pubspec.yaml               # Flutter dependencies & assets
```

---

## 🧪 Technology Stack

| Layer | Technology |
|---|---|
| **Frontend Framework** | Flutter (Dart SDK >= 3.13) |
| **Real-Time Video/Audio** | `flutter_webrtc` |
| **Signaling Protocol** | WebSockets via `web_socket_channel` |
| **Backend Framework** | FastAPI (Python 3.10+) |
| **ASGI Server** | Uvicorn |
| **TURN / STUN Services** | Metered Cloud (`medicare.metered.live`) & Google STUN |
| **Hardware & Media Permissions** | `permission_handler` |
| **File Management** | `file_picker` & `path_provider` |

---

## 💻 Setup & Execution Guide

### 1. Running the Signaling Backend
```bash
# Navigate to backend directory
cd backend

# Activate virtual environment (Windows)
.\venv\Scripts\activate

# Install dependencies if needed
pip install -r requirements.txt

# Start FastAPI Uvicorn Server
uvicorn server:app --host 0.0.0.0 --port 8000
```

### 2. Running the Flutter App
```bash
# Get dependencies
flutter pub get

# Run on target Android device / emulator
flutter run
```

---

## 📈 Recent Work Completed

1. **Metered TURN Integration**: Updated and verified `webrtc_service.dart` with valid Metered cloud domain credentials (`medicare.metered.live`), ensuring successful TURN allocations across strict NAT/Firewall environments.
2. **ICE Queuing Fix**: Implemented pre-description candidate buffering in `WebRTCService` to eliminate SDP/ICE timing conflicts.
3. **Glassmorphism Auth Screens**: Redesigned `LoginPage` and `SignupPage` with blurred frosted-glass aesthetics, ABHA ID input, and role dropdown selectors.
4. **Adaptive Bandwidth Controls**: Built real-time network profile toggles (5G, 4G, 3G, Audio-Only) directly inside `ActiveCallPage`.
5. **In-App Messaging & Attachments**: Wired `ChatPage` and `FileTransferService` to enable image, audio, video, and PDF file exchanges alongside live calls.

@echo off
title MediReach Backend Launcher
echo ============================================================
echo   MediReach Microservices Launcher
echo ============================================================
echo.

set "SCRIPT_DIR=%~dp0"
set "UVICORN_CMD=python -m uvicorn"

if exist "%SCRIPT_DIR%backend\venv\Scripts\uvicorn.exe" (
    set "UVICORN_CMD='%SCRIPT_DIR%backend\venv\Scripts\uvicorn.exe'"
)

echo Starting Node.js API Gateway (Port 5000)...
start "MediReach API Gateway [5000]" powershell -NoExit -Command "cd '%SCRIPT_DIR%backend/node_api'; npm start"

echo Starting Python WebRTC Signaling Server (Port 8000)...
start "MediReach WebRTC Signaling [8000]" powershell -NoExit -Command "cd '%SCRIPT_DIR%backend'; & %UVICORN_CMD% server:app --host 0.0.0.0 --port 8000"

echo Starting Python ML Clinical Triage Server (Port 8001)...
start "MediReach ML Triage [8001]" powershell -NoExit -Command "cd '%SCRIPT_DIR%backend/ml_service'; & %UVICORN_CMD% ml_server:app --host 0.0.0.0 --port 8001"

echo.
echo ============================================================
echo   All 3 backend microservices are launching!
echo   - Gateway:    http://localhost:5000
echo   - WebRTC:     http://localhost:8000
echo   - ML Triage:  http://localhost:8001
echo ============================================================
pause


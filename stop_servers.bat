@echo off
title Stop MediReach Backend
echo ============================================================
echo   Stopping MediReach Backend Microservices (5000, 8000, 8001)...
echo ============================================================
powershell -Command "Stop-Process -Id (Get-NetTCPConnection -LocalPort 5000, 8000, 8001 -ErrorAction SilentlyContinue).OwningProcess -Force -ErrorAction SilentlyContinue; Stop-Process -Name cloudflared -Force -ErrorAction SilentlyContinue"
echo.
echo All backend servers and tunnels have been stopped. Ports released!
echo ============================================================
pause

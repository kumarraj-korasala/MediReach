@echo off
title Cloudflare Tunnel - MediReach Auto-Sync
echo ============================================================
echo   Starting Cloudflare Tunnel with Automatic Supabase Sync
echo ============================================================

set CMD_CLOUDFLARE=
if exist "%~dp0cloudflared.exe" (
    set "CMD_CLOUDFLARE=%~dp0cloudflared.exe"
) else (
    where cloudflared >nul 2>&1
    if not errorlevel 1 (
        set "CMD_CLOUDFLARE=cloudflared"
    )
)

if "%CMD_CLOUDFLARE%"=="" (
    echo [ERROR] cloudflared executable not found!
    echo Please install it using:
    echo    winget install --id Cloudflare.cloudflared
    echo Or download cloudflared.exe and place it in the project root:
    echo    https://github.com/cloudflare/cloudflared/releases
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { & '%CMD_CLOUDFLARE%' tunnel --url http://localhost:5000 2>&1 | ForEach-Object { Write-Host $_; if ($_ -match '(https://[a-zA-Z0-9-]+\.trycloudflare\.com)') { $url = $matches[1]; Write-Host ('`n[OK] Registering ' + $url + ' in Supabase...') -ForegroundColor Green; node backend/node_api/scripts/update_tunnel_url.js $url } } }"
pause


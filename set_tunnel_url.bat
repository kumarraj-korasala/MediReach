@echo off
title Set Active Cloudflare Tunnel URL
cls
echo ============================================================
echo   MediReach - Manually Set Active Cloudflare Tunnel URL
echo ============================================================
echo.

set /p TUNNEL_URL="Paste your Cloudflare URL (e.g. https://xxx.trycloudflare.com): "

if "%TUNNEL_URL%"=="" (
    echo [ERROR] No URL entered. Aborted.
    pause
    exit /b 1
)

echo.
echo Registering %TUNNEL_URL% in Supabase...
node backend\node_api\scripts\update_tunnel_url.js "%TUNNEL_URL%"

echo.
pause

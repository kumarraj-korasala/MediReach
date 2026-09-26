param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$Url
)

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  MediReach - Manually Set Active Cloudflare Tunnel URL     " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

if (-not $Url) {
    $Url = Read-Host "`nPaste your Cloudflare URL (e.g. https://xxx.trycloudflare.com)"
}

$Url = $Url.Trim().Trim('"').Trim("'")

if (-not $Url) {
    Write-Host "[ERROR] No URL provided. Aborted." -ForegroundColor Red
    exit 1
}

Write-Host "`nRegistering $Url in Supabase..." -ForegroundColor Yellow
node backend/node_api/scripts/update_tunnel_url.js $Url

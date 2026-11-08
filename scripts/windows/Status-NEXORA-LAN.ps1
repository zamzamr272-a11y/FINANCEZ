[CmdletBinding()]
param()
$ErrorActionPreference = 'Continue'
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$EnvFile = Join-Path $ProjectRoot '.env'
$port = '8000'
if (Test-Path $EnvFile) {
    $line = Get-Content $EnvFile | Where-Object { $_ -match '^\s*NEXORA_PORT=' } | Select-Object -Last 1
    if ($line) { $port = ($line -replace '^\s*NEXORA_PORT=', '').Trim() }
}
Push-Location $ProjectRoot
try {
    docker compose ps
    Write-Host ''
    try {
        $health = Invoke-RestMethod -Uri "http://127.0.0.1:$port/health" -TimeoutSec 4
        Write-Host "API: $($health.status) — $($health.time)" -ForegroundColor Green
    } catch {
        Write-Warning "API belum dapat dijangkau pada localhost:$port. Periksa Docker Desktop dan log container."
    }
    Write-Host 'Alamat IPv4 aktif:'
    Get-NetConnectionProfile -ErrorAction SilentlyContinue | Where-Object { $_.IPv4Connectivity -ne 'Disconnected' } | ForEach-Object {
        $profile = $_
        Get-NetIPAddress -InterfaceIndex $profile.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.AddressState -eq 'Preferred' -and $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
            ForEach-Object { Write-Host "  $($_.IPAddress) [$($profile.InterfaceAlias), $($profile.NetworkCategory)]  API: http://$($_.IPAddress):$port/api/v1" }
    }
} finally { Pop-Location }

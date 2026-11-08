[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Push-Location $ProjectRoot
try {
    # 'down' removes containers/network, but intentionally keeps named database and file volumes.
    docker compose down
    if ($LASTEXITCODE -ne 0) { throw 'Gagal menghentikan service NEXORA.' }
    Write-Host 'NEXORA dihentikan. Database dan file tetap tersimpan di Docker volumes.' -ForegroundColor Green
} finally { Pop-Location }

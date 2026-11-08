[CmdletBinding()]
param(
    [switch]$RegenerateSecrets
)
$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$EnvFile = Join-Path $ProjectRoot '.env'

function New-CryptoHex([int]$ByteCount) {
    $bytes = New-Object byte[] $ByteCount
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) }
    finally { $rng.Dispose() }
    return ([System.BitConverter]::ToString($bytes)).Replace('-', '').ToLowerInvariant()
}

if ((Test-Path $EnvFile) -and -not $RegenerateSecrets) {
    Write-Host 'File .env sudah ada. Saya tidak menimpa secret atau pengaturan yang ada.' -ForegroundColor Yellow
    Write-Host 'Periksa bahwa POSTGRES_PASSWORD dan JWT_SECRET bukan nilai contoh.'
    return
}

if ((Test-Path $EnvFile) -and $RegenerateSecrets) {
    Write-Warning 'Mengganti secret dapat membuat konfigurasi akses token lama tidak berlaku. Password database existing juga berubah; lakukan hanya untuk instalasi baru atau setelah backup.'
    $confirm = Read-Host 'Ketik REGENERATE untuk melanjutkan'
    if ($confirm -cne 'REGENERATE') { Write-Host 'Dibatalkan.'; return }
}

$postgresPassword = New-CryptoHex 32
$jwtSecret = New-CryptoHex 64
$lines = @(
    '# Generated locally by scripts/windows/Setup-NEXORA-LAN.ps1. Never commit this file.'
    "POSTGRES_PASSWORD=$postgresPassword"
    "JWT_SECRET=$jwtSecret"
    'CORS_ORIGINS=https://appassets.androidplatform.net,http://localhost:8000,http://127.0.0.1:8000'
    'NEXORA_BIND_IP=0.0.0.0'
    'NEXORA_PORT=8000'
    'ENVIRONMENT=production'
    'AUTH_RATE_LIMIT_PER_MINUTE=12'
    'APP_TIMEZONE=Asia/Makassar'
    'OCR_LANG=ind+eng'
    'RECURRING_POLL_SECONDS=900'
)
$utf8NoBom = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
[System.IO.File]::WriteAllText($EnvFile, (($lines -join [Environment]::NewLine) + [Environment]::NewLine), $utf8NoBom)

Write-Host 'Konfigurasi .env lokal berhasil dibuat.' -ForegroundColor Green
Write-Host 'Secret dibuat secara acak dan tidak ditampilkan di layar.'
Write-Host 'Pastikan .env tidak pernah diunggah ke GitHub atau dibagikan.' -ForegroundColor Yellow

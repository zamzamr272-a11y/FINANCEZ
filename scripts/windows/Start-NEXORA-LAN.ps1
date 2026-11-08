[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$EnvFile = Join-Path $ProjectRoot '.env'

function Read-EnvValue([string]$Name, [string]$DefaultValue) {
    if (Test-Path $EnvFile) {
        $line = Get-Content $EnvFile | Where-Object { $_ -match "^\s*$([regex]::Escape($Name))=" } | Select-Object -Last 1
        if ($line) { return ($line -replace "^\s*$([regex]::Escape($Name))=", '').Trim() }
    }
    return $DefaultValue
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Docker CLI tidak ditemukan. Instal dan jalankan Docker Desktop terlebih dahulu: https://www.docker.com/products/docker-desktop/'
}
if (-not (Test-Path $EnvFile)) {
    Write-Host 'Membuat secret dan file .env untuk instalasi pertama...' -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot 'Setup-NEXORA-LAN.ps1')
    if (-not (Test-Path $EnvFile)) { throw 'Setup .env gagal membuat file konfigurasi.' }
}

$postgresPassword = Read-EnvValue 'POSTGRES_PASSWORD' ''
$jwtSecret = Read-EnvValue 'JWT_SECRET' ''
$corsOrigins = Read-EnvValue 'CORS_ORIGINS' ''
if ($postgresPassword -match '^REPLACE_' -or $postgresPassword.Length -lt 32) {
    throw 'POSTGRES_PASSWORD belum berupa secret kuat. Untuk instalasi baru, hapus .env template lalu jalankan Start-NEXORA-LAN.bat agar secret dibuat otomatis. Jangan lakukan ini jika volume database sudah berisi data.'
}
if ($jwtSecret -match '^REPLACE_' -or $jwtSecret.Length -lt 64) {
    throw 'JWT_SECRET harus berupa secret acak minimal 64 karakter. Jalankan Setup-NEXORA-LAN.ps1 hanya pada instalasi baru atau atur secret sendiri dengan aman.'
}
if ($corsOrigins -notmatch 'https://appassets\.androidplatform\.net') {
    throw 'CORS_ORIGINS harus menyertakan https://appassets.androidplatform.net agar APK Android dapat mengakses API.'
}
$port = Read-EnvValue 'NEXORA_PORT' '8000'
if ($port -notmatch '^\d{1,5}$' -or [int]$port -lt 1 -or [int]$port -gt 65535) { throw 'NEXORA_PORT di .env tidak valid.' }

Write-Host 'Memeriksa Docker Engine...' -ForegroundColor Cyan
& docker info --format '{{.ServerVersion}}' | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Docker Engine belum berjalan. Buka Docker Desktop, tunggu status Running, lalu jalankan ulang script ini.' }

Push-Location $ProjectRoot
try {
    Write-Host 'Memvalidasi Docker Compose...' -ForegroundColor Cyan
    & docker compose config --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Konfigurasi Docker Compose tidak valid. Periksa file .env dan docker-compose.yml.' }

    Write-Host 'Membangun dan menjalankan NEXORA API, database, dan recurring worker...' -ForegroundColor Cyan
    & docker compose up -d --build
    if ($LASTEXITCODE -ne 0) { throw 'Docker Compose gagal menjalankan service. Jalankan docker compose logs --tail=150.' }

    $healthOk = $false
    for ($i = 1; $i -le 40; $i++) {
        try {
            $health = Invoke-RestMethod -Uri "http://127.0.0.1:$port/health" -TimeoutSec 3
            if ($health.status -eq 'ok') { $healthOk = $true; break }
        } catch { }
        Start-Sleep -Seconds 2
    }
    if (-not $healthOk) {
        Write-Warning 'Container sudah dijalankan tetapi health check belum berhasil.'
        & docker compose ps
        Write-Host 'Periksa log dengan: docker compose logs --tail=150 api db recurring-worker'
        exit 2
    }

    Write-Host ''
    Write-Host 'NEXORA SERVER BERHASIL BERJALAN' -ForegroundColor Green
    Write-Host "Status API : http://localhost:$port/health"
    Write-Host "Dashboard : http://localhost:$port/"
    Write-Host "API Base  : http://localhost:$port/api/v1"
    Write-Host ''

    $profiles = @(Get-NetConnectionProfile -ErrorAction SilentlyContinue | Where-Object { $_.IPv4Connectivity -ne 'Disconnected' })
    $lanAddresses = @()
    foreach ($profile in $profiles) {
        $ips = @(Get-NetIPAddress -InterfaceIndex $profile.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.AddressState -eq 'Preferred' -and $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' })
        foreach ($ip in $ips) {
            $lanAddresses += [PSCustomObject]@{ IP = $ip.IPAddress; Alias = $profile.InterfaceAlias; Category = $profile.NetworkCategory }
        }
    }
    $lanAddresses = @($lanAddresses | Sort-Object IP -Unique)
    if ($lanAddresses.Count -eq 0) {
        Write-Warning 'Alamat IPv4 Wi-Fi/Ethernet tidak terdeteksi. Sambungkan laptop ke Wi-Fi lalu jalankan Status-NEXORA-LAN.bat.'
    } else {
        Write-Host 'Alamat yang digunakan HP pada Wi-Fi yang sama:' -ForegroundColor Cyan
        foreach ($item in $lanAddresses) {
            Write-Host "  $($item.Alias) [$($item.Category)]"
            Write-Host "  Dashboard : http://$($item.IP):$port/"
            Write-Host "  Android   : http://$($item.IP):$port/api/v1"
            if ($item.Category -ne 'Private') {
                Write-Warning "Jaringan $($item.Alias) masih berprofil $($item.Category). Gunakan profil Private untuk jaringan rumah tepercaya sebelum membuka firewall LAN."
            }
        }
    }
    Write-Host ''
    Write-Host 'Jika HP belum dapat terhubung: jalankan Allow-NEXORA-Firewall.ps1 sebagai Administrator.' -ForegroundColor Yellow
    Write-Host 'Jangan membuat port forwarding pada router. Database PostgreSQL tidak diekspos ke jaringan.' -ForegroundColor Yellow
} finally {
    Pop-Location
}

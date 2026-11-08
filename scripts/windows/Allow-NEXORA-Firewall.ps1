[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Meminta izin Administrator untuk menambahkan aturan Windows Firewall...' -ForegroundColor Cyan
    $elevatedArguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $PSCommandPath + '"'
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $elevatedArguments
    exit
}
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$EnvFile = Join-Path $ProjectRoot '.env'
$port = '8000'
if (Test-Path $EnvFile) {
    $line = Get-Content $EnvFile | Where-Object { $_ -match '^\s*NEXORA_PORT=' } | Select-Object -Last 1
    if ($line) { $port = ($line -replace '^\s*NEXORA_PORT=', '').Trim() }
}
if ($port -notmatch '^\d{1,5}$' -or [int]$port -lt 1 -or [int]$port -gt 65535) { throw 'NEXORA_PORT tidak valid.' }
$ruleName = 'NEXORA LAN API TCP ' + $port
Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName $ruleName -Description 'Allow NEXORA API only from local private subnet; PostgreSQL remains unexposed.' -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port -Profile Private -RemoteAddress LocalSubnet | Out-Null
Write-Host "Aturan firewall dibuat: TCP $port, profil Private, sumber LocalSubnet." -ForegroundColor Green
Write-Host 'Ubah profil Wi-Fi rumah menjadi Private pada Windows Settings jika saat ini Public.'
Write-Host 'Aturan ini tidak membuka port router dan tidak mengizinkan akses dari internet.'

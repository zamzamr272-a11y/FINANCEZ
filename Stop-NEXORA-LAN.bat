@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows\Stop-NEXORA-LAN.ps1"
echo.
pause

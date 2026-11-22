@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Prepare-Client.ps1"
if errorlevel 1 (
    pause
    exit /b 1
)
start "" "%~dp0minecraft"

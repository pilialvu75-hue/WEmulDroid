@echo off
setlocal
title WEmulDroid - Verifica prerequisiti
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\Check-Requirements.ps1"
echo.
pause

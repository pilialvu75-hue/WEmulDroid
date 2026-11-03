@echo off
setlocal
title WEmulDroid - Test Android di base
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\Test-Android.ps1"
echo.
if errorlevel 1 (
  echo Verifica il messaggio di errore e il report in AppData\Local\WEmulDroid\Reports.
) else (
  echo Comandi completati. Conferma che Impostazioni si veda nella finestra Android.
)
pause

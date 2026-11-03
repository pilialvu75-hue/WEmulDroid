@echo off
setlocal
title WEmulDroid - Installazione Android con Google Play Store
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\Setup-Android.ps1" -PlayStore
echo.
if errorlevel 1 (
  echo Installazione del profilo Google Play non completata. Leggi gli errori sopra.
) else (
  echo Profilo Google Play predisposto. Avvia Avvia-PlayStore.cmd.
)
pause

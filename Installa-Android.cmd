@echo off
setlocal
title AIVEXUS Android Desktop Lab - Installazione
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\Setup-Android.ps1"
echo.
if errorlevel 1 (
  echo Installazione non completata. Leggi il messaggio sopra.
) else (
  echo Installazione terminata. Ora esegui Avvia-Android.cmd.
)
pause

@echo off
setlocal
title WEmulDroid - Android Desktop Lab
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0src\Lab.ps1"
if errorlevel 1 (
  echo Avvio non riuscito. Controlla il messaggio precedente.
  pause
)

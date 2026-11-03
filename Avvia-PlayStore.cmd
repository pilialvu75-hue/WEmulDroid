@echo off
setlocal
title WEmulDroid - Google Play Store
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0src\Lab.ps1" -AvdName "WEmulDroid_Play_API_35"
if errorlevel 1 (
  echo Apertura WEmulDroid Google Play non riuscita.
  pause
)

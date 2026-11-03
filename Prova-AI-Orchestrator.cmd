@echo off
setlocal
title WEmulDroid - Primo test AI-Orchestrator
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\Test-AiOrchestrator.ps1"
echo.
if errorlevel 1 (
  echo La prova non e completa. Controlla il messaggio e il report.
) else (
  echo Comandi completati. Controlla l'interfaccia di AI-Orchestrator nella finestra Android.
)
pause

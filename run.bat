@echo off
setlocal
echo Starting DeepLiveCam...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run.ps1"
if errorlevel 1 (
  echo.
  echo Run failed. Press any key to close.
  pause >nul
)
endlocal

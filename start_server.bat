@echo off
cd /d %~dp0backend\ecoalert-backend

if exist ".venv\Scripts\uvicorn.exe" (
  set "UVICORN=.venv\Scripts\uvicorn.exe"
) else if exist "venv\Scripts\uvicorn.exe" (
  set "UVICORN=venv\Scripts\uvicorn.exe"
) else (
  echo No backend virtual environment found.
  echo Create one with: py -3.12 -m venv .venv
  pause
  exit /b 1
)

echo Starting EcoAlert backend on http://0.0.0.0:5000 ...
"%UVICORN%" app:asgi_app --host 0.0.0.0 --port 5000 --reload
pause

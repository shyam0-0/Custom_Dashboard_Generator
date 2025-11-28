@echo off
setlocal

REM ALWAYS run from the script’s directory
cd /d "%~dp0"

echo ============================================
echo   STARTING DOCKER SERVICES FOR THE PROJECT   
echo ============================================

REM Check Docker
docker info >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Docker Desktop is not running.
    echo Please start Docker Desktop and re-run this script.
    pause
    exit /b
)

echo.
echo Building and starting containers...
docker compose up -d --build

IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Docker Compose failed!
    pause
    exit /b
)

echo.
echo ============================================
echo            ALL SERVICES RUNNING
echo ============================================
echo.
echo Grafana:     http://localhost:3001
echo Prometheus:  http://localhost:9090
echo Pushgateway: http://localhost:9091
echo.
echo Predictor AI is running inside Docker.
echo ============================================

pause

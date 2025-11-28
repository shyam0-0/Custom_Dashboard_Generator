@echo off
REM --------------------------------------------------------
REM                GLOBAL MONITORING CLI
REM --------------------------------------------------------

SETLOCAL ENABLEDELAYEDEXPANSION

REM Path to this script's directory
SET SCRIPT_DIR=%~dp0

REM Colors (Windows CMD ANSI colors)
FOR /F "delims=" %%a IN ('echo prompt $E^| cmd') DO SET "ESC=%%a"

SET BLUE=%ESC%[94m
SET GREEN=%ESC%[92m
SET YELLOW=%ESC%[93m
SET RED=%ESC%[91m
SET RESET=%ESC%[0m

REM --------------------------------------------------------
REM                    START COMMAND
REM --------------------------------------------------------
if /I "%1"=="start" (

    echo %BLUE%[ Monitoring ]%RESET% Starting full monitoring system...
    echo.

    REM Run your existing startup script
    call "%SCRIPT_DIR%start.cmd"

    echo.
    echo %YELLOW%Waiting 5 seconds for Grafana to initialize...%RESET%
    timeout /t 5 >nul

    echo %GREEN%Opening Grafana Dashboard...%RESET%
    start http://localhost:3001

    echo.
    echo %GREEN%System successfully started!%RESET%
    exit /b
)

REM --------------------------------------------------------
REM              INSTALL WINDOWS EXPORTER
REM --------------------------------------------------------
if /I "%1"=="install-exporter" (
    echo %BLUE%[ Monitoring ]%RESET% Installing Windows Exporter...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install_exporter.ps1"
    echo %GREEN%Done.%RESET%
    exit /b
)

REM --------------------------------------------------------
REM                    STOP COMMAND
REM --------------------------------------------------------
if /I "%1"=="stop" (
    echo %YELLOW%Stopping monitoring system...%RESET%
    docker-compose -f "%SCRIPT_DIR%docker-compose.yml" down
    echo %GREEN%Stopped.%RESET%
    exit /b
)

REM --------------------------------------------------------
REM                    STATUS COMMAND
REM --------------------------------------------------------
if /I "%1"=="status" (
    echo %BLUE%[ Monitoring ]%RESET% Checking Docker container status...
    docker ps
    exit /b
)

REM --------------------------------------------------------
REM                    LOGS COMMAND
REM --------------------------------------------------------
if /I "%1"=="logs" (
    echo %BLUE%[ Monitoring ]%RESET% Showing live logs...
    docker-compose -f "%SCRIPT_DIR%docker-compose.yml" logs -f
    exit /b
)

REM --------------------------------------------------------
REM                    UNKNOWN / HELP
REM --------------------------------------------------------
echo %YELLOW%Monitoring CLI Usage:%RESET%
echo --------------------------------------------------------
echo %GREEN%monitor start%RESET%             = Start full system + auto-open Grafana
echo %GREEN%monitor stop%RESET%              = Stop entire monitoring stack
echo %GREEN%monitor status%RESET%            = Show running containers
echo %GREEN%monitor logs%RESET%              = Live logs from all services
echo %GREEN%monitor install-exporter%RESET%  = Install Windows Exporter
echo.
exit /b

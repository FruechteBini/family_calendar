@echo off
echo ============================================
echo   Familienkalender - Server beenden
echo ============================================
echo.

set FOUND=0
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000 ^| findstr LISTENING 2^>nul') do (
    echo Beende Prozess PID %%a auf Port 8000...
    taskkill /PID %%a /F >nul 2>&1
    set FOUND=1
)

if "%FOUND%"=="0" (
    echo Kein Server auf Port 8000 gefunden.
) else (
    echo.
    echo Server wurde beendet.
)

echo.
pause

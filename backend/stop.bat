@echo off
echo ============================================
echo   Familienkalender - Server beenden
echo ============================================
echo.

call :kill_port_8000

echo.
pause
exit /b 0

:kill_port_8000
set FOUND=0
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000 ^| findstr ABH 2^>nul') do (
    if not "%%a"=="0" (
        echo Beende Prozessbaum PID %%a auf Port 8000...
        taskkill /PID %%a /T /F >nul 2>&1
        set FOUND=1
    )
)
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000 ^| findstr LISTEN 2^>nul') do (
    if not "%%a"=="0" (
        echo Beende Prozessbaum PID %%a auf Port 8000...
        taskkill /PID %%a /T /F >nul 2>&1
        set FOUND=1
    )
)

if "%FOUND%"=="0" (
    echo Kein Server auf Port 8000 gefunden.
) else (
    :: Kurz warten und pruefen ob alles weg ist
    timeout /t 2 /nobreak >nul
    set STILL_RUNNING=0
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000 2^>nul') do (
        if not "%%a"=="0" (
            echo Hartkill PID %%a...
            taskkill /PID %%a /F >nul 2>&1
            set STILL_RUNNING=1
        )
    )
    if "!STILL_RUNNING!"=="1" (
        timeout /t 1 /nobreak >nul
    )
    echo.
    echo Server wurde beendet.
)
exit /b 0

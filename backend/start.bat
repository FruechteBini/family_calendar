@echo off
cd /d "%~dp0"

echo ============================================
echo   Familienkalender - Server starten
echo ============================================
echo.

:: --- Virtual Environment ---
if exist "venv\Scripts\python.exe" (
    set PYTHON=venv\Scripts\python
    set PIP=venv\Scripts\pip
) else (
    echo Kein venv gefunden. Erstelle virtuelle Umgebung...
    echo.
    python -m venv venv
    if errorlevel 1 (
        echo [FEHLER] Konnte venv nicht erstellen. Ist Python installiert?
        pause
        exit /b 1
    )
    echo Installiere Abhaengigkeiten aus requirements.txt...
    venv\Scripts\pip install -r requirements.txt
    if errorlevel 1 (
        echo [FEHLER] pip install fehlgeschlagen.
        pause
        exit /b 1
    )
    echo.
    echo venv erfolgreich erstellt und Pakete installiert.
    echo.
    set PYTHON=venv\Scripts\python
    set PIP=venv\Scripts\pip
)

:: --- PostgreSQL pruefen ---
echo Pruefe PostgreSQL-Verbindung...
sc query postgresql-x64-16 | findstr RUNNING >nul 2>&1
if errorlevel 1 (
    echo [WARNUNG] PostgreSQL-Service scheint nicht zu laufen.
    echo Versuche Service zu starten...
    net start postgresql-x64-16 >nul 2>&1
    if errorlevel 1 (
        echo [FEHLER] PostgreSQL konnte nicht gestartet werden.
        echo Bitte starte PostgreSQL manuell oder pruefe die Installation.
        pause
        exit /b 1
    )
    echo PostgreSQL-Service gestartet.
)
echo PostgreSQL laeuft.
echo.

:: --- Abhaengigkeiten synchronisieren ---
echo Pruefe Abhaengigkeiten...
%PIP% install -r requirements.txt --quiet
if errorlevel 1 (
    echo [WARNUNG] Einige Pakete konnten nicht installiert werden.
)

:: --- .env pruefen ---
if not exist ".env" (
    echo [WARNUNG] Keine .env-Datei gefunden. Kopiere .env.example oder erstelle eine.
)

echo.
echo Python: %PYTHON%
echo DB:     PostgreSQL (localhost:5432/kalender)
echo Port:   8000
echo URL:    http://localhost:8000
echo.
echo Zum Beenden: Ctrl+C oder stop.bat in neuem Terminal
echo ============================================
echo.

%PYTHON% -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload --reload-include "*.env"

pause

@echo off
cd /d "%~dp0"

echo ============================================
echo   Familienkalender - Server starten
echo ============================================
echo.

if exist "venv_new\Scripts\python.exe" (
    set PYTHON=venv_new\Scripts\python
    set PIP=venv_new\Scripts\pip
) else if exist "venv\Scripts\python.exe" (
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

echo Pruefe Abhaengigkeiten...
%PIP% install -r requirements.txt --quiet
if errorlevel 1 (
    echo [WARNUNG] Einige Pakete konnten nicht installiert werden.
)

if not exist "data" mkdir data

echo Python: %PYTHON%
echo Port:   8000
echo URL:    http://localhost:8000
echo.
echo Zum Beenden: Ctrl+C oder stop.bat in neuem Terminal
echo ============================================
echo.

%PYTHON% -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload --reload-include "*.env"

pause

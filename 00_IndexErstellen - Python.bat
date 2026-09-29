@echo off
setlocal

pushd "%~dp0" || (
    echo Der Skriptordner konnte nicht geoeffnet werden.
    pause
    exit /b 1
)

:: Prüfen, ob der Befehl 'py' existiert (Windows Python Launcher)
:: Hinweis: "if errorlevel 1" wird zur Laufzeit ausgewertet, %errorlevel% in
:: Klammerbloecken dagegen schon beim Einlesen des Blocks.
where py >nul 2>&1
if not errorlevel 1 (
    py -3 ".\00_index_erstellen.py"
    goto :done
)

:: Fallback: Prüfen, ob 'python' existiert
where python >nul 2>&1
if errorlevel 1 (
    echo Python wurde nicht gefunden.
    echo Bitte Python installieren oder zur PATH-Variable hinzufuegen.
    popd
    pause
    exit /b 1
)
python ".\00_index_erstellen.py"

:done
set "exitCode=%errorlevel%"
popd

if not "%exitCode%"=="0" (
    echo.
    echo Beim Erstellen des Index ist ein Fehler aufgetreten.
    pause
) else (
    echo.
    echo Dieses Fenster schliesst sich in 5 Sekunden.
    timeout /t 5 >nul
)

exit /b %exitCode%
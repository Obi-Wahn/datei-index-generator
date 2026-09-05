@echo off
setlocal

pushd "%~dp0" || (
    echo Der Skriptordner konnte nicht geoeffnet werden.
    pause
    exit /b 1
)

:: Prüfen, ob der Befehl 'py' existiert (Windows Python Launcher)
where py >nul 2>&1
if "%errorlevel%"=="0" (
    py -3 ".\00_index_erstellen.py"
) else (
    :: Fallback: Prüfen, ob 'python' existiert
    where python >nul 2>&1
    if not "%errorlevel%"=="0" (
        echo Python wurde nicht gefunden.
        echo Bitte Python installieren oder zur PATH-Variable hinzufuegen.
        popd
        pause
        exit /b 1
    )
    python ".\00_index_erstellen.py"
)

set "exitCode=%errorlevel%"
popd

if not "%exitCode%"=="0" (
    echo.
    echo Beim Erstellen des Index ist ein Fehler aufgetreten.
    pause
)

exit /b %exitCode%
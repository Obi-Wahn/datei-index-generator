@echo off
setlocal

pushd "%~dp0" || (
    echo Der Skriptordner konnte nicht geoeffnet werden.
    pause
    exit /b 1
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass ^
    -File ".\00_IndexErstellen.ps1"

set "exitCode=%errorlevel%"
popd

if not "%exitCode%"=="0" (
    echo.
    echo Beim Erstellen des Index ist ein Fehler aufgetreten.
    pause
)

exit /b %exitCode%
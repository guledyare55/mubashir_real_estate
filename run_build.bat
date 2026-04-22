@echo off
REM Mubashir Real Estate - Build Helper Launcher
REM This file allows you to run the build automation with a double-click.

echo Initializing Build Environment...
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1"

echo.
echo Press any key to exit...
pause > nul

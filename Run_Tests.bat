@echo off
title Cyberstack — Automated Test Suite Runner
echo ========================================================
echo         RUNNING CYBERSTACK AUTOMATED TEST SUITE          
echo ========================================================
echo.

set "GODOT_EXE=C:\Godot\Godot_v4.6.3-stable_win64_console.exe"

if not exist "%GODOT_EXE%" (
    set "GODOT_EXE=C:\Godot\Godot_v4.6.3-stable_win64.exe"
)

if not exist "%GODOT_EXE%" (
    echo [ERROR] Could not locate Godot 4.6 executable in C:\Godot\
    pause
    exit /b 1
)

"%GODOT_EXE%" --path "%~dp0." --headless -s tests/test_runner.gd
echo.
pause

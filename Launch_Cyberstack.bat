@echo off
title Cyberstack — Launch Game
echo ========================================================
echo               LAUNCHING CYBERSTACK                      
echo ========================================================
echo.

set "GODOT_EXE=C:\Godot\Godot_v4.6.3-stable_win64_console.exe"

if not exist "%GODOT_EXE%" (
    set "GODOT_EXE=C:\Godot\Godot_v4.6.3-stable_win64.exe"
)

if not exist "%GODOT_EXE%" (
    echo [ERROR] Could not locate Godot 4.6 executable in C:\Godot\
    echo Please verify that Godot is installed at C:\Godot\
    pause
    exit /b 1
)

echo Starting Cyberstack...
start "" "%GODOT_EXE%" --path "%~dp0." res://src/ui/screens/Main.tscn
exit /b 0

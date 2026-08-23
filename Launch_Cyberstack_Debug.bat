@echo off
title Cyberstack — Developer Mode Console
echo ========================================================
echo         CYBERSTACK — DEVELOPER DEBUG LAUNCHER           
echo ========================================================
echo.
echo Press ~ (Tilde) or F12 in-game to toggle the Developer Console.
echo Console commands: /gold, /district, /spawn, /grant, /win, /crt
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

"%GODOT_EXE%" --path "%~dp0." res://src/ui/screens/Main.tscn
pause

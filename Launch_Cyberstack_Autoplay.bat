@echo off
title Cyberstack — Autoplay Spectator Mode
echo ========================================================
echo         CYBERSTACK — AUTOPLAY SPECTATOR LAUNCHER
echo ========================================================
echo.
echo Boots straight into a live run driven by AutoplayDirector.
echo Picks a random strategy from the top 5 measured winrate
echo archetypes in data\strategy_metrics.json each run (falls
echo back to curated archetypes if that file doesn't exist yet
echo -- generate it with src/tools/StrategyMetricsSimulator.gd).
echo.
echo One shop/reroll/placement action every 2s by default.
echo Override pacing with: Launch_Cyberstack_Autoplay.bat 3.5
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

set "AUTOPLAY_SPEED=2.0"
if not "%~1"=="" set "AUTOPLAY_SPEED=%~1"

"%GODOT_EXE%" --path "%~dp0." res://src/ui/screens/Main.tscn --autoplay --autoplay-speed=%AUTOPLAY_SPEED%
pause

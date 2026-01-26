@echo off
REM Six Strong - Quick Test Runner
REM Runs the comprehensive test suite

set GODOT="C:\Program Files\Godot\Godot_v4.5.1-stable_win64.exe"
set PROJECT="C:\Users\glenn\Dev\six-strong"

echo Running Six Strong Test Suite...
echo.

%GODOT% --headless --path %PROJECT% res://tests/test_runner_scene.tscn

echo.
if %ERRORLEVEL% EQU 0 (
    echo ===================================
    echo ALL TESTS PASSED
    echo ===================================
) else (
    echo ===================================
    echo TESTS FAILED - See output above
    echo ===================================
)

pause

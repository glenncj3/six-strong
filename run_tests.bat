@echo off
REM Six Strong - Comprehensive Test Runner
REM Runs all test suites: unit, integration, and functional

set GODOT="C:\Program Files\Godot\Godot_v4.5.1-stable_win64.exe"
set PROJECT="C:\Users\glenn\Dev\six-strong"
set TOTAL_FAILED=0

echo ============================================================
echo SIX STRONG - COMPREHENSIVE TEST SUITE
echo ============================================================
echo.

echo [1/2] Running Core Tests...
echo ============================================================
%GODOT% --headless --path %PROJECT% res://tests/test_runner_scene.tscn
if %ERRORLEVEL% NEQ 0 set /A TOTAL_FAILED+=%ERRORLEVEL%
echo.

echo [2/2] Running Encounter Functional Tests...
echo ============================================================
%GODOT% --headless --path %PROJECT% res://tests/functional/run_all_encounter_tests.tscn
if %ERRORLEVEL% NEQ 0 set /A TOTAL_FAILED+=%ERRORLEVEL%
echo.

echo ============================================================
if %TOTAL_FAILED% EQU 0 (
    echo ALL TESTS PASSED!
) else (
    echo TOTAL FAILURES: %TOTAL_FAILED%
    echo See output above for details.
)
echo ============================================================

pause

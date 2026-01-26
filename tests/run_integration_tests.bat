@echo off
REM Integration test runner for Six Strong
REM Run all integration tests and report results

set GODOT="C:\Program Files\Godot\Godot_v4.5.1-stable_win64.exe"
set PROJECT="C:\Users\glenn\Dev\six-strong"

echo ============================================================
echo SIX STRONG - INTEGRATION TEST SUITE
echo ============================================================
echo.

set TOTAL_FAILED=0

echo Running: Data Integrity Tests
%GODOT% --headless --path %PROJECT% --script res://tests/integration/test_data_integrity.gd
if %ERRORLEVEL% NEQ 0 set /A TOTAL_FAILED+=%ERRORLEVEL%
echo.

echo Running: Full Game Flow Tests
%GODOT% --headless --path %PROJECT% --script res://tests/integration/test_full_game_flow.gd
if %ERRORLEVEL% NEQ 0 set /A TOTAL_FAILED+=%ERRORLEVEL%
echo.

echo Running: Encounter UI Tests
%GODOT% --headless --path %PROJECT% --script res://tests/integration/test_encounter_uis.gd
if %ERRORLEVEL% NEQ 0 set /A TOTAL_FAILED+=%ERRORLEVEL%
echo.

echo ============================================================
echo INTEGRATION TESTS COMPLETE
if %TOTAL_FAILED% EQU 0 (
    echo ALL TESTS PASSED
) else (
    echo TOTAL FAILURES: %TOTAL_FAILED%
)
echo ============================================================

exit /B %TOTAL_FAILED%

@echo off
REM Six Strong - Complete Test Suite
REM Runs ALL tests: core, functional, and path coverage

set GODOT="C:\Program Files\Godot\Godot_v4.5.1-stable_win64.exe"
set PROJECT="C:\Users\glenn\Dev\six-strong"
set TOTAL_FAILED=0

echo ============================================================
echo SIX STRONG - COMPLETE TEST SUITE
echo ============================================================
echo.

echo [1/11] Core Integration Tests...
echo ------------------------------------------------------------
%GODOT% --headless --path %PROJECT% res://tests/test_runner_scene.tscn
if %ERRORLEVEL% NEQ 0 set /A TOTAL_FAILED+=%ERRORLEVEL%
echo.

echo [2/11] Encounter Functional Tests...
echo ------------------------------------------------------------
%GODOT% --headless --path %PROJECT% res://tests/functional/run_all_encounter_tests.tscn
if %ERRORLEVEL% NEQ 0 set /A TOTAL_FAILED+=%ERRORLEVEL%
echo.

echo [3/11] Wheel of Fortune Path Tests...
echo ------------------------------------------------------------
%GODOT% --headless --path %PROJECT% res://tests/functional/test_wheel_of_fortune_paths.tscn
if %ERRORLEVEL% NEQ 0 set /A TOTAL_FAILED+=%ERRORLEVEL%
echo.

echo [4/11] Slot Machine Path Tests...
echo ------------------------------------------------------------
%GODOT% --headless --path %PROJECT% res://tests/functional/test_slot_machine_paths.tscn
if %ERRORLEVEL% NEQ 0 set /A TOTAL_FAILED+=%ERRORLEVEL%
echo.

echo [5/11] Matching Game Path Tests...
echo ------------------------------------------------------------
%GODOT% --headless --path %PROJECT% res://tests/functional/test_matching_game_paths.tscn
if %ERRORLEVEL% NEQ 0 set /A TOTAL_FAILED+=%ERRORLEVEL%
echo.

echo [6/11] Shop Path Tests...
echo ------------------------------------------------------------
%GODOT% --headless --path %PROJECT% res://tests/functional/test_shop_paths.tscn
if %ERRORLEVEL% NEQ 0 set /A TOTAL_FAILED+=%ERRORLEVEL%
echo.

echo [7/11] Health Restore Path Tests...
echo ------------------------------------------------------------
%GODOT% --headless --path %PROJECT% res://tests/functional/test_health_restore_paths.tscn
if %ERRORLEVEL% NEQ 0 set /A TOTAL_FAILED+=%ERRORLEVEL%
echo.

echo [8/11] Treasure Chest Path Tests...
echo ------------------------------------------------------------
%GODOT% --headless --path %PROJECT% res://tests/functional/test_treasure_chest_paths.tscn
if %ERRORLEVEL% NEQ 0 set /A TOTAL_FAILED+=%ERRORLEVEL%
echo.

echo [9/11] Character Shop Path Tests...
echo ------------------------------------------------------------
%GODOT% --headless --path %PROJECT% res://tests/functional/test_character_shop_paths.tscn
if %ERRORLEVEL% NEQ 0 set /A TOTAL_FAILED+=%ERRORLEVEL%
echo.

echo [10/11] Skill Trainer Path Tests...
echo ------------------------------------------------------------
%GODOT% --headless --path %PROJECT% res://tests/functional/test_skill_trainer_paths.tscn
if %ERRORLEVEL% NEQ 0 set /A TOTAL_FAILED+=%ERRORLEVEL%
echo.

echo [11/11] Gamble Path Tests...
echo ------------------------------------------------------------
%GODOT% --headless --path %PROJECT% res://tests/functional/test_gamble_paths.tscn
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

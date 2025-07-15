@echo off
echo === Startup Crash Fix ===
echo.
echo This script will try to fix the startup crash by:
echo 1. Backing up current files
echo 2. Applying safe versions
echo 3. Testing with minimal scene
echo.

REM Backup current files
if exist project.godot (
    copy project.godot project.godot.original_backup
    echo ✓ Backed up project.godot
) else (
    echo ❌ project.godot not found
)

if exist scripts\AudioManager.gd (
    copy scripts\AudioManager.gd scripts\AudioManager.gd.original_backup
    echo ✓ Backed up AudioManager.gd
) else (
    echo ❌ AudioManager.gd not found
)

echo.
echo Choose a fix option:
echo 1. Use recovery project.godot (removes OpenGL renderer)
echo 2. Use backup AudioManager.gd (disables audio loading)
echo 3. Both (recommended)
echo 4. Cancel
echo.

set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" goto use_recovery_project
if "%choice%"=="2" goto use_backup_audio
if "%choice%"=="3" goto use_both
if "%choice%"=="4" goto cancel

:use_recovery_project
if exist recovery_project.godot (
    copy recovery_project.godot project.godot
    echo ✓ Applied recovery project.godot
) else (
    echo ❌ recovery_project.godot not found
)
goto test_game

:use_backup_audio
if exist backup_AudioManager.gd (
    copy backup_AudioManager.gd scripts\AudioManager.gd
    echo ✓ Applied backup AudioManager.gd
) else (
    echo ❌ backup_AudioManager.gd not found
)
goto test_game

:use_both
if exist recovery_project.godot (
    copy recovery_project.godot project.godot
    echo ✓ Applied recovery project.godot
) else (
    echo ❌ recovery_project.godot not found
)

if exist backup_AudioManager.gd (
    copy backup_AudioManager.gd scripts\AudioManager.gd
    echo ✓ Applied backup AudioManager.gd
) else (
    echo ❌ backup_AudioManager.gd not found
)
goto test_game

:test_game
echo.
echo === Testing Game ===
echo.
echo Now try running the game:
echo 1. Open Godot Editor
echo 2. Run minimal_test.tscn (F6) first
echo 3. If that works, try running the main project (F5)
echo.
echo If the game still crashes, check STARTUP_CRASH_FIX.md for more options.
echo.
goto end

:cancel
echo Operation cancelled.

:end
pause 
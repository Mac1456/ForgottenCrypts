@echo off
echo Starting Crypts of the Forgotten with OpenGL renderer...
echo This avoids the Epic Games Vulkan overlay issues.

REM Set environment variables to disable Vulkan validation layers
set VK_LAYER_PATH=
set VK_INSTANCE_LAYERS=
set DISABLE_VK_LAYER_VALVE_steam_overlay_1=1
set GODOT_DISABLE_VULKAN=1
set GODOT_FORCE_OPENGL3=1

REM Launch Godot with OpenGL renderer
"C:\Program Files\Godot\godot.exe" --rendering-driver opengl3 --path . --main-pack .

REM Alternative launch methods (uncomment one if the above doesn't work):
REM godot --rendering-driver opengl3 --path .
REM godot.exe --rendering-driver opengl3 --path .

echo.
echo Game closed.
pause 
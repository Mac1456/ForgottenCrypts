Write-Host "Starting Crypts of the Forgotten with OpenGL renderer..." -ForegroundColor Green
Write-Host "This avoids the Epic Games Vulkan overlay issues." -ForegroundColor Yellow

# Set environment variables to disable Vulkan validation layers
$env:VK_LAYER_PATH = ""
$env:VK_INSTANCE_LAYERS = ""
$env:DISABLE_VK_LAYER_VALVE_steam_overlay_1 = "1"
$env:GODOT_DISABLE_VULKAN = "1"
$env:GODOT_FORCE_OPENGL3 = "1"

# Try to find Godot executable
$GodotPaths = @(
    "C:\Program Files\Godot\godot.exe",
    "C:\Program Files (x86)\Godot\godot.exe",
    "godot.exe"
)

$GodotPath = $null
foreach ($path in $GodotPaths) {
    if (Test-Path $path) {
        $GodotPath = $path
        break
    }
}

if ($GodotPath) {
    Write-Host "Found Godot at: $GodotPath" -ForegroundColor Green
    
    # Launch with OpenGL renderer
    & $GodotPath --rendering-driver opengl3 --path .
} else {
    Write-Host "Godot not found. Please install Godot 4.4.1 or update the path in this script." -ForegroundColor Red
    Write-Host "You can also run from Godot Editor with OpenGL renderer enabled." -ForegroundColor Yellow
}

Write-Host "Game closed." -ForegroundColor Green
Read-Host "Press Enter to exit" 
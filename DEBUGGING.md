# 🐛 ForgottenCrypts - Debugging Guide

## 🔧 Cursor + Godot Integration Setup

### Prerequisites
1. **Install Godot Tools Extension in Cursor**
   - Open Cursor
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "Godot Tools" 
   - Install the extension

2. **Configure Godot Editor**
   - Open Godot
   - Go to `Editor → Editor Settings`
   - Navigate to `Network → Language Server`
   - Enable "Use Language Server"
   - Set Host to `127.0.0.1` and Port to `6008`

### 🚀 Running Debug Scripts

#### Method 1: Direct Debug Script
```bash
# In Cursor terminal (Ctrl+`)
godot --headless --script debug_game_loading.gd --quit
```

#### Method 2: Debug Scene (Recommended)
1. Open Godot
2. Press `F6` (Run Scene)
3. Select `debug_scene.tscn`
4. Check the console output for detailed debug information

#### Method 3: Using Cursor Tasks
1. Press `Ctrl+Shift+P` in Cursor
2. Type "Tasks: Run Task"
3. Select "Run Godot Headless Test"

### 🛠️ Available Debug Commands

#### From Cursor Terminal:
- **Run Game**: `godot --path . --debug`
- **Run Tests**: `godot --path . --headless --script test_basic_functionality.gd --quit`
- **Validate Project**: `godot --path . --check-only --quit`
- **Debug Loading**: `godot --path . --headless --script debug_game_loading.gd --quit`

#### From Godot Editor:
- **F5**: Run main scene
- **F6**: Run current scene
- **F7**: Step into (when debugging)
- **F8**: Step over (when debugging)
- **F9**: Toggle breakpoint

### 📊 Debug Output Interpretation

#### ✅ Success Messages
- `✓ SUCCESS: ...` - Component is working correctly

#### ⚠️ Warning Messages  
- `⚠ WARNING: ...` - Non-critical issues that might cause problems

#### ❌ Error Messages
- `✗ ERROR: ...` - Critical issues that will prevent game loading

### 🔍 Common Issues and Solutions

#### Issue: "godot command not found"
**Solution**: Add Godot to your PATH or use full path:
```bash
# Use full path instead
"C:\\Program Files\\Godot\\godot.exe" --path . --debug
```

#### Issue: Character selection hangs
**Potential Causes**:
1. Missing character scripts (check `scripts/characters/`)
2. Missing Player.tscn scene
3. NetworkManager not properly initialized
4. GameManager state issues

#### Issue: Audio errors
**Solution**: Audio files are now created as placeholders. Replace with real audio files:
- Music: `assets/audio/music/`
- SFX: `assets/audio/sfx/`

#### Issue: Scene loading fails
**Potential Causes**:
1. Missing GameLevel.tscn
2. Missing GameWorld.tscn
3. Script compilation errors
4. Missing @onready node references

### 🎯 Debugging Character Selection Issues

#### Step 1: Check Autoloads
Run debug script and verify all autoload nodes are present:
- GameManager
- NetworkManager
- ProgressionManager
- AudioManager

#### Step 2: Check Scene Files
Verify all required scenes exist:
- MainMenu.tscn
- GameWorld.tscn
- Player.tscn
- GameLevel.tscn

#### Step 3: Check Character Scripts
Verify all character scripts exist and compile:
- Player.gd
- Wizard.gd
- Barbarian.gd
- Rogue.gd
- Knight.gd

#### Step 4: Test Network Flow
Use the debug script to simulate character selection:
1. Add player
2. Set character type
3. Set ready state
4. Start game

### 🔧 Advanced Debugging

#### Enable Verbose Logging
In `project.godot`, add:
```ini
[debug]
settings/stdout/print_fps=true
settings/stdout/verbose_stdout=true
```

#### Use Godot Remote Inspector
1. Run game with `--remote-debug`
2. In Godot Editor: `Remote → Remote Inspector`
3. Connect to running game instance

#### Breakpoint Debugging
1. Set breakpoints in Cursor (click left of line numbers)
2. Run game in debug mode
3. Game will pause at breakpoints

### 📝 Error Log Analysis

#### Common Error Patterns:
- `Parse Error`: Syntax issues in GDScript
- `Method not found`: Missing or renamed functions
- `Node not found`: Missing scene nodes or incorrect paths
- `Resource not found`: Missing assets or incorrect paths

#### Log Locations:
- **Windows**: `%APPDATA%/Godot/app_userdata/[project_name]/logs/`
- **Console Output**: In Cursor terminal or Godot output panel

### 🎮 Testing Workflow

1. **Quick Test**: Run debug script to check all systems
2. **Scene Test**: Run debug_scene.tscn in Godot
3. **Full Test**: Run main game and attempt character selection
4. **Identify Issues**: Check console for specific error messages
5. **Fix & Repeat**: Address issues and re-test

### 📞 Getting Help

If you're still having issues:
1. Run the debug script and share the output
2. Check the Godot console for specific error messages
3. Look for parse errors or missing resources
4. Verify all autoload nodes are properly configured

The debug system will provide detailed information about what's failing during the character selection process. 
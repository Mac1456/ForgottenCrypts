# Startup Crash Fix Guide

## Problem: "Debug session stopped" - Game crashes immediately on startup

This means there's a compilation error or critical issue preventing the game from starting.

## 🔧 **Step-by-Step Recovery**

### **Step 1: Test with Minimal Scene**
1. **In Godot Editor**: Open `minimal_test.tscn` and run it (F6)
2. **Check console output** - if this works, the issue is with the main scene
3. **If this also crashes**, continue to Step 2

### **Step 2: Use Recovery Project Settings**
1. **Backup current project.godot**:
   - Rename `project.godot` to `project.godot.backup`
2. **Use recovery version**:
   - Rename `recovery_project.godot` to `project.godot`
3. **Try running again** - this removes the OpenGL renderer changes

### **Step 3: Check for Compilation Errors**
1. **In Godot Editor**: Look at the "Output" panel (bottom)
2. **Check for red error messages** - these indicate compilation failures
3. **Common issues**:
   - Missing semicolons
   - Incorrect indentation
   - Missing dependencies

### **Step 4: Disable Autoloads Temporarily**
If the minimal test still crashes, temporarily disable autoloads:

1. **Open project.godot** in a text editor
2. **Comment out autoloads** by adding `#` at the start:
   ```
   #NetworkManager="*res://scripts/NetworkManager.gd"
   #GameManager="*res://scripts/GameManager.gd"
   #ProgressionManager="*res://scripts/ProgressionManager.gd"
   #AudioManager="*res://scripts/AudioManager.gd"
   ```
3. **Save and try running** the minimal test

### **Step 5: Re-enable Autoloads One by One**
1. **Uncomment one autoload** at a time
2. **Test after each one** to identify which is causing the crash
3. **Most likely culprit**: AudioManager (recently modified)

## 🛠️ **Quick Recovery Options**

### **Option A: Revert AudioManager Changes**
If AudioManager is the problem:
1. **Check git history** and revert AudioManager.gd
2. **Or manually remove** the recent changes to `_load_audio_file()`

### **Option B: Bypass Audio System**
1. **Temporarily disable AudioManager** in project.godot
2. **Test if game starts** without audio
3. **Fix audio issues** later

### **Option C: Use Original Project Settings**
1. **Restore original project.godot** from backup
2. **Keep the AudioManager fixes** but revert renderer changes
3. **Test with default Vulkan renderer**

## 📋 **Diagnostic Commands**

### **Check Console Output**
Look for these error patterns:
- `Parse Error`: Syntax errors in scripts
- `Script class not found`: Missing or broken script files
- `Autoload script failed`: Issues with autoload scripts
- `Resource not found`: Missing scene or script files

### **Check File Integrity**
Verify these files exist and are readable:
- `scripts/AudioManager.gd`
- `scripts/GameManager.gd`
- `scripts/NetworkManager.gd`
- `scripts/ProgressionManager.gd`
- `scenes/MainMenu.tscn`

## 🎯 **Most Likely Solutions**

### **If AudioManager is the issue:**
```gdscript
# In AudioManager.gd, temporarily simplify _load_audio_file():
func _load_audio_file(path: String) -> AudioStream:
    return null  # Disable audio temporarily
```

### **If OpenGL renderer is the issue:**
```ini
# In project.godot, remove the [rendering] section entirely
```

### **If main scene is the issue:**
```ini
# In project.godot, change:
run/main_scene="res://minimal_test.tscn"
```

## 🔍 **Debug Process**

1. **Start with minimal_test.tscn**
2. **Check console output for errors**
3. **Isolate the problem** (autoload, renderer, or main scene)
4. **Apply targeted fix**
5. **Test with original main scene**

## 📞 **If All Else Fails**

1. **Create a new Godot project**
2. **Copy over working scripts** one by one
3. **Test after each addition**
4. **Rebuild project.godot** from scratch

The key is to **isolate the problem** systematically. Start with the minimal test, then work your way up to the full game.

**Most common cause**: The OpenGL renderer changes in project.godot might not be compatible with your system. Use the recovery version to test! 
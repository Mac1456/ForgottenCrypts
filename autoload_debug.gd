extends Node

# Debug script to test autoloads individually
# This will help identify which autoload is causing the startup crash

func _ready():
	print("=== AUTOLOAD DEBUG TEST ===")
	print("Testing each autoload script individually...")
	
	# Test each autoload file by trying to load it
	var autoload_paths = {
		"NetworkManager": "res://scripts/NetworkManager.gd",
		"GameManager": "res://scripts/GameManager.gd", 
		"ProgressionManager": "res://scripts/ProgressionManager.gd",
		"AudioManager": "res://scripts/AudioManager.gd"
	}
	
	for autoload_name in autoload_paths:
		var script_path = autoload_paths[autoload_name]
		print("\nTesting ", autoload_name, " (", script_path, ")...")
		
		# Test 1: Check if file exists
		if not ResourceLoader.exists(script_path):
			print("❌ FAIL: File does not exist: ", script_path)
			continue
		else:
			print("✅ File exists")
		
		# Test 2: Try to load the script
		var script = load(script_path)
		if script:
			print("✅ Script loaded successfully")
		else:
			print("❌ FAIL: Script load returned null")
			continue
		
		# Test 3: Try to create an instance
		var instance = script.new()
		if instance:
			print("✅ Script instantiated successfully")
			# Clean up
			instance.queue_free()
		else:
			print("❌ FAIL: Script instantiation returned null")
	
	print("\n=== COMPILATION CHECK ===")
	print("If you see this message, all autoload scripts can be loaded individually.")
	print("The issue might be with:")
	print("1. Autoload initialization order")
	print("2. Cross-dependencies between autoloads")
	print("3. Project settings configuration")
	
	print("\n=== RECOMMENDATION ===")
	print("Try using no_autoloads_project.godot as project.godot to bypass autoloads entirely.")
	
	await get_tree().create_timer(2.0).timeout
	print("Debug test completed.") 
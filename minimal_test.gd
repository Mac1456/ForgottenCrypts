extends Node

# Minimal test script to isolate startup crash
# This will help identify what's causing the immediate crash

func _ready():
	print("=== MINIMAL TEST START ===")
	
	# Test 1: Basic functionality
	print("Test 1: Basic GDScript working")
	
	# Test 2: Check if autoloads are causing the crash
	print("Test 2: Checking autoloads...")
	
	var autoloads = ["NetworkManager", "GameManager", "ProgressionManager", "AudioManager"]
	
	for autoload_name in autoloads:
		var node = get_node_or_null("/root/" + autoload_name)
		if node:
			print("✅ Autoload OK: ", autoload_name)
		else:
			print("❌ Autoload FAILED: ", autoload_name)
	
	# Test 3: Check for script compilation errors
	print("Test 3: Script compilation test passed")
	
	# Test 4: Check renderer
	print("Test 4: Current renderer: ", RenderingServer.get_rendering_device())
	
	print("=== MINIMAL TEST COMPLETE ===")
	print("If you see this message, the basic system is working")
	
	# Wait a bit then quit
	await get_tree().create_timer(3.0).timeout
	print("Minimal test completed - quitting")
	get_tree().quit() 
extends Node

# Ultra minimal test - no autoloads, no complex logic
# This will help us isolate whether the issue is with autoloads or project settings

func _ready():
	print("=== ULTRA MINIMAL TEST ===")
	print("If you see this, basic GDScript is working")
	print("Godot version: ", Engine.get_version_info())
	print("Platform: ", OS.get_name())
	print("Test successful!")
	
	# Simple countdown
	for i in range(5, 0, -1):
		print("Test will complete in: ", i, " seconds")
		await get_tree().create_timer(1.0).timeout
	
	print("Ultra minimal test completed successfully!")
	print("=== END TEST ===")
	
	# Don't quit automatically - let user see the result
	# get_tree().quit() 
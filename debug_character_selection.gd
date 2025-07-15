extends Node

# Debug script for testing character selection flow
# Run this from the debug scene to test character selection without UI

func _ready():
	print("=== CHARACTER SELECTION DEBUG TEST ===")
	
	# Wait a frame for autoloads to initialize
	await get_tree().process_frame
	
	# Run the test
	test_character_selection_flow()

func test_character_selection_flow():
	print("Starting character selection flow test...")
	
	# Step 1: Validate autoloads
	print("\n1. Validating autoloads...")
	if not validate_autoloads():
		print("❌ FAILED: Autoloads not available")
		return
	print("✅ Autoloads validated")
	
	# Step 2: Test NetworkManager setup
	print("\n2. Testing NetworkManager setup...")
	if not test_network_manager():
		print("❌ FAILED: NetworkManager test failed")
		return
	print("✅ NetworkManager test passed")
	
	# Step 3: Test GameManager setup
	print("\n3. Testing GameManager setup...")
	if not test_game_manager():
		print("❌ FAILED: GameManager test failed")
		return
	print("✅ GameManager test passed")
	
	# Step 4: Test character selection
	print("\n4. Testing character selection...")
	if not test_character_selection():
		print("❌ FAILED: Character selection test failed")
		return
	print("✅ Character selection test passed")
	
	# Step 5: Test scene loading
	print("\n5. Testing scene loading...")
	if not test_scene_loading():
		print("❌ FAILED: Scene loading test failed")
		return
	print("✅ Scene loading test passed")
	
	# Step 6: Test game start
	print("\n6. Testing game start...")
	if not test_game_start():
		print("❌ FAILED: Game start test failed")
		return
	print("✅ Game start test passed")
	
	print("\n🎉 ALL TESTS PASSED! Character selection should work correctly.")
	print("If you're still experiencing crashes, the issue is likely the Vulkan overlay problem.")

func validate_autoloads() -> bool:
	var required_autoloads = [
		"NetworkManager",
		"GameManager", 
		"ProgressionManager",
		"AudioManager"
	]
	
	for autoload_name in required_autoloads:
		var node = get_node_or_null("/root/" + autoload_name)
		if not node:
			print("❌ Missing autoload: ", autoload_name)
			return false
		print("✅ Found autoload: ", autoload_name)
	
	return true

func test_network_manager() -> bool:
	var nm = get_node_or_null("/root/NetworkManager")
	if not nm:
		return false
	
	# Test adding a player
	nm.add_player(999, "DebugPlayer")
	var players = nm.get_all_players()
	if not players.has(999):
		print("❌ Failed to add player")
		return false
	print("✅ Player added successfully")
	
	# Test character selection
	nm.set_player_character(999, "Wizard")
	var player_data = nm.get_player(999)
	if player_data.get("character_type") != "Wizard":
		print("❌ Failed to set character type")
		return false
	print("✅ Character type set successfully")
	
	# Test ready state
	nm.set_player_ready(999, true)
	if not nm.all_players_ready():
		print("❌ Failed to set ready state")
		return false
	print("✅ Ready state set successfully")
	
	# Clean up
	nm.remove_player(999)
	return true

func test_game_manager() -> bool:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return false
	
	# Test game state
	gm.set_game_state(GameManager.GameState.MENU)
	if gm.current_state != GameManager.GameState.MENU:
		print("❌ Failed to set game state")
		return false
	print("✅ Game state set successfully")
	
	# Test level info
	var level_info = gm.get_current_level_info()
	if level_info.is_empty():
		print("❌ Failed to get level info")
		return false
	print("✅ Level info retrieved successfully: ", level_info)
	
	return true

func test_character_selection() -> bool:
	# Test character scripts exist
	var character_scripts = [
		"res://scripts/characters/Wizard.gd",
		"res://scripts/characters/Barbarian.gd", 
		"res://scripts/characters/Rogue.gd",
		"res://scripts/characters/Knight.gd"
	]
	
	for script_path in character_scripts:
		if not ResourceLoader.exists(script_path):
			print("❌ Missing character script: ", script_path)
			return false
		
		var script = load(script_path)
		if not script:
			print("❌ Failed to load character script: ", script_path)
			return false
		print("✅ Character script loaded: ", script_path)
	
	return true

func test_scene_loading() -> bool:
	# Test critical scenes exist and can be loaded
	var critical_scenes = [
		"res://scenes/GameWorld.tscn",
		"res://scenes/characters/Player.tscn",
		"res://scenes/levels/GameLevel.tscn"
	]
	
	for scene_path in critical_scenes:
		if not ResourceLoader.exists(scene_path):
			print("❌ Missing scene: ", scene_path)
			return false
		
		var scene = load(scene_path)
		if not scene:
			print("❌ Failed to load scene: ", scene_path)
			return false
		
		# Test instantiation
		var instance = scene.instantiate()
		if not instance:
			print("❌ Failed to instantiate scene: ", scene_path)
			return false
		
		instance.queue_free()
		print("✅ Scene loaded and instantiated: ", scene_path)
	
	return true

func test_game_start() -> bool:
	var gm = get_node_or_null("/root/GameManager")
	var nm = get_node_or_null("/root/NetworkManager")
	
	if not gm or not nm:
		return false
	
	# Set up a test player
	nm.add_player(999, "TestPlayer")
	nm.set_player_character(999, "Wizard")
	nm.set_player_ready(999, true)
	
	# Test game start
	gm.start_new_run()
	
	# Check if game state changed
	if gm.current_state != GameManager.GameState.PLAYING:
		print("❌ Game state did not change to PLAYING")
		nm.remove_player(999)
		return false
	
	print("✅ Game started successfully")
	
	# Clean up
	nm.remove_player(999)
	gm.set_game_state(GameManager.GameState.MENU)
	
	return true 
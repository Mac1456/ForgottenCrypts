extends Node
class_name GameDebugger

# Debug output
var debug_output = []
var error_count = 0
var warning_count = 0

func _ready():
	print("=== FORGOTTEN CRYPTS - COMPREHENSIVE DEBUG CHECK ===")
	run_comprehensive_debug()

func run_comprehensive_debug():
	print("Starting comprehensive debug check...")
	
	# Check 1: Autoload nodes
	debug_section("AUTOLOAD NODES")
	check_autoload_nodes()
	
	# Check 2: Scene files
	debug_section("SCENE FILES")
	check_scene_files()
	
	# Check 3: Character scripts and scenes
	debug_section("CHARACTER SYSTEMS")
	check_character_systems()
	
	# Check 4: Network Manager
	debug_section("NETWORK MANAGER")
	check_network_manager()
	
	# Check 5: Game Manager
	debug_section("GAME MANAGER")
	check_game_manager()
	
	# Check 6: Audio files
	debug_section("AUDIO SYSTEM")
	check_audio_system()
	
	# Check 7: Level system
	debug_section("LEVEL SYSTEM")
	check_level_system()
	
	# Check 8: Simulate character selection flow
	debug_section("CHARACTER SELECTION FLOW")
	test_character_selection_flow()
	
	# Final report
	print_debug_summary()

func debug_section(section_name: String):
	print("\\n--- ", section_name, " ---")

func log_success(message: String):
	print("✓ SUCCESS: ", message)
	debug_output.append("✓ " + message)

func log_warning(message: String):
	print("⚠ WARNING: ", message)
	debug_output.append("⚠ " + message)
	warning_count += 1

func log_error(message: String):
	print("✗ ERROR: ", message)
	debug_output.append("✗ " + message)
	error_count += 1

func check_autoload_nodes():
	# Check GameManager
	if get_node_or_null("/root/GameManager"):
		log_success("GameManager autoload found")
	else:
		log_error("GameManager autoload missing")
	
	# Check NetworkManager
	if get_node_or_null("/root/NetworkManager"):
		log_success("NetworkManager autoload found")
	else:
		log_error("NetworkManager autoload missing")
	
	# Check ProgressionManager
	if get_node_or_null("/root/ProgressionManager"):
		log_success("ProgressionManager autoload found")
	else:
		log_error("ProgressionManager autoload missing")
	
	# Check AudioManager
	if get_node_or_null("/root/AudioManager"):
		log_success("AudioManager autoload found")
	else:
		log_error("AudioManager autoload missing")

func check_scene_files():
	var scenes_to_check = [
		"res://scenes/MainMenu.tscn",
		"res://scenes/GameWorld.tscn",
		"res://scenes/characters/Player.tscn",
		"res://scenes/levels/GameLevel.tscn",
		"res://scenes/enemies/Enemy.tscn",
		"res://scenes/enemies/SkeletonGrunt.tscn",
		"res://scenes/enemies/BlueWitch.tscn",
		"res://scenes/projectiles/Fireball.tscn",
		"res://scenes/projectiles/MagicMissile.tscn",
		"res://scenes/projectiles/Meteor.tscn"
	]
	
	for scene_path in scenes_to_check:
		if ResourceLoader.exists(scene_path):
			log_success("Scene found: " + scene_path)
		else:
			log_error("Scene missing: " + scene_path)

func check_character_systems():
	var character_scripts = [
		"res://scripts/characters/Player.gd",
		"res://scripts/characters/Wizard.gd",
		"res://scripts/characters/Barbarian.gd",
		"res://scripts/characters/Rogue.gd",
		"res://scripts/characters/Knight.gd"
	]
	
	for script_path in character_scripts:
		if ResourceLoader.exists(script_path):
			log_success("Character script found: " + script_path)
		else:
			log_error("Character script missing: " + script_path)

func check_network_manager():
	var network_manager = get_node_or_null("/root/NetworkManager")
	if not network_manager:
		log_error("NetworkManager not available")
		return
	
	# Check if NetworkManager has required methods
	if network_manager.has_method("add_player"):
		log_success("NetworkManager.add_player method found")
	else:
		log_error("NetworkManager.add_player method missing")
	
	if network_manager.has_method("get_player"):
		log_success("NetworkManager.get_player method found")
	else:
		log_error("NetworkManager.get_player method missing")
	
	if network_manager.has_method("all_players_ready"):
		log_success("NetworkManager.all_players_ready method found")
	else:
		log_error("NetworkManager.all_players_ready method missing")

func check_game_manager():
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		log_error("GameManager not available")
		return
	
	# Check if GameManager has required methods
	if game_manager.has_method("start_new_run"):
		log_success("GameManager.start_new_run method found")
	else:
		log_error("GameManager.start_new_run method missing")
	
	if game_manager.has_method("set_game_state"):
		log_success("GameManager.set_game_state method found")
	else:
		log_error("GameManager.set_game_state method missing")

func check_audio_system():
	var audio_manager = get_node_or_null("/root/AudioManager")
	if not audio_manager:
		log_error("AudioManager not available")
		return
	
	# Check key audio files
	var audio_files = [
		"res://assets/audio/music/cave_ambient.ogg",
		"res://assets/audio/music/menu_theme.ogg",
		"res://assets/audio/sfx/button_click.ogg"
	]
	
	for audio_file in audio_files:
		if ResourceLoader.exists(audio_file):
			log_success("Audio file found: " + audio_file)
		else:
			log_error("Audio file missing: " + audio_file)

func check_level_system():
	# Check if GameLevel scene can be loaded
	var level_scene_path = "res://scenes/levels/GameLevel.tscn"
	if ResourceLoader.exists(level_scene_path):
		log_success("GameLevel scene found")
		
		# Try to load the scene
		var level_scene = load(level_scene_path)
		if level_scene:
			log_success("GameLevel scene loaded successfully")
			
			# Try to instantiate
			var level_instance = level_scene.instantiate()
			if level_instance:
				log_success("GameLevel scene instantiated successfully")
				
				# Check if it has required methods
				if level_instance.has_method("initialize_level"):
					log_success("GameLevel.initialize_level method found")
				else:
					log_error("GameLevel.initialize_level method missing")
				
				level_instance.queue_free()
			else:
				log_error("GameLevel scene instantiation failed")
		else:
			log_error("GameLevel scene loading failed")
	else:
		log_error("GameLevel scene missing: " + level_scene_path)

func test_character_selection_flow():
	var network_manager = get_node_or_null("/root/NetworkManager")
	var game_manager = get_node_or_null("/root/GameManager")
	
	if not network_manager or not game_manager:
		log_error("Required managers not available for character selection test")
		return
	
	# Test 1: Add player
	print("Testing player addition...")
	network_manager.add_player(1, "TestPlayer")
	log_success("Player added successfully")
	
	# Test 2: Set character selection
	print("Testing character selection...")
	network_manager.set_player_character(1, "Rogue")
	log_success("Character selection set successfully")
	
	# Test 3: Set ready state
	print("Testing ready state...")
	network_manager.set_player_ready(1, true)
	log_success("Ready state set successfully")
	
	# Test 4: Check if all players ready
	print("Testing all players ready check...")
	var all_ready = network_manager.all_players_ready()
	if all_ready:
		log_success("All players ready check passed")
	else:
		log_error("All players ready check failed")
	
	# Test 5: Try to start game
	print("Testing game start...")
	game_manager.start_new_run()
	log_success("Game start completed without errors")
	
	# Test 6: Try to load GameWorld scene
	print("Testing GameWorld scene loading...")
	var game_world_scene = load("res://scenes/GameWorld.tscn")
	if game_world_scene:
		var game_world_instance = game_world_scene.instantiate()
		if game_world_instance:
			log_success("GameWorld scene instantiated successfully")
			game_world_instance.queue_free()
		else:
			log_error("GameWorld scene instantiation failed")
	else:
		log_error("GameWorld scene loading failed")
	
	# Clean up
	print("Cleaning up test player...")
	network_manager.remove_player(1)
	log_success("Test player cleaned up")

func print_debug_summary():
	print("\\n=== DEBUG SUMMARY ===")
	print("Total checks run: ", debug_output.size())
	print("Errors found: ", error_count)
	print("Warnings found: ", warning_count)
	
	if error_count == 0:
		print("🎉 ALL CHECKS PASSED! Game should be able to load properly.")
	else:
		print("❌ ISSUES FOUND! Check the errors above.")
	
	print("\\n=== DETAILED LOG ===")
	for line in debug_output:
		print(line)
	
	print("\\n=== END DEBUG REPORT ===")

# Helper function to run from MainMenu
func _input(event):
	if event.is_action_pressed("ui_accept"):
		run_comprehensive_debug() 

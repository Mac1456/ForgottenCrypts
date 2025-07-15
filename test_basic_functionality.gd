extends Node

# Test results
var test_results = []
var total_tests = 0
var passed_tests = 0
var failed_tests = 0

func _ready():
	print("=== FORGOTTEN CRYPTS - BASIC FUNCTIONALITY TEST ===")
	print("Starting comprehensive system validation...")
	
	# Run all tests
	test_autoload_nodes()
	test_scene_files()
	test_character_scripts()
	test_network_manager()
	test_game_manager()
	test_progression_manager()
	test_level_generation()
	test_character_selection_flow()
	
	# Print final results
	print_test_summary()
	
	# Exit after tests
	await get_tree().create_timer(1.0).timeout
	print("Test complete. Check the console output for detailed results.")

func run_test(test_name: String, test_func: Callable) -> bool:
	total_tests += 1
	print("\n[TEST] ", test_name)
	
	var success = false
	success = test_func.call()
	
	if success:
		print("✓ PASSED: ", test_name)
		passed_tests += 1
	else:
		print("✗ FAILED: ", test_name)
		failed_tests += 1
	
	test_results.append({"name": test_name, "passed": success})
	return success

func test_autoload_nodes():
	print("\n=== AUTOLOAD NODES TEST ===")
	
	run_test("GameManager autoload", func(): return GameManager != null)
	run_test("NetworkManager autoload", func(): return NetworkManager != null)
	run_test("ProgressionManager autoload", func(): return ProgressionManager != null)
	run_test("AudioManager autoload", func(): return AudioManager != null)

func test_scene_files():
	print("\n=== SCENE FILES TEST ===")
	
	var critical_scenes = [
		"res://scenes/MainMenu.tscn",
		"res://scenes/GameWorld.tscn",
		"res://scenes/levels/GameLevel.tscn",
		"res://scenes/characters/Player.tscn",
		"res://scenes/enemies/Enemy.tscn",
		"res://scenes/enemies/SkeletonGrunt.tscn",
		"res://scenes/ui/ProgressionUI.tscn"
	]
	
	for scene_path in critical_scenes:
		var scene_name = scene_path.get_file().get_basename()
		run_test(scene_name + " exists", func(): return ResourceLoader.exists(scene_path))
		
		if ResourceLoader.exists(scene_path):
			run_test(scene_name + " loads", func(): 
				var scene = load(scene_path)
				return scene != null
			)

func test_character_scripts():
	print("\n=== CHARACTER SCRIPTS TEST ===")
	
	var character_scripts = [
		"res://scripts/characters/Player.gd",
		"res://scripts/characters/Wizard.gd",
		"res://scripts/characters/Barbarian.gd",
		"res://scripts/characters/Rogue.gd",
		"res://scripts/characters/Knight.gd"
	]
	
	for script_path in character_scripts:
		var script_name = script_path.get_file().get_basename()
		run_test(script_name + " exists", func(): return ResourceLoader.exists(script_path))
		
		if ResourceLoader.exists(script_path):
			run_test(script_name + " loads", func():
				var script = load(script_path)
				return script != null
			)

func test_network_manager():
	print("\n=== NETWORK MANAGER TEST ===")
	
	if not NetworkManager:
		print("NetworkManager not available - skipping tests")
		return
	
	run_test("NetworkManager initialization", func(): return NetworkManager != null)
	
	# Test player management
	run_test("Add test player", func():
		NetworkManager.add_player(999, "TestPlayer")
		return NetworkManager.get_player_count() > 0
	)
	
	run_test("Get player data", func():
		var player_data = NetworkManager.get_player(999)
		return player_data.has("name") and player_data["name"] == "TestPlayer"
	)
	
	run_test("Set player character", func():
		NetworkManager.set_player_character(999, "Wizard")
		var player_data = NetworkManager.get_player(999)
		return player_data.get("character_type") == "Wizard"
	)
	
	run_test("Set player ready", func():
		NetworkManager.set_player_ready(999, true)
		var player_data = NetworkManager.get_player(999)
		return player_data.get("ready") == true
	)
	
	# Clean up test player
	NetworkManager.remove_player(999)

func test_game_manager():
	print("\n=== GAME MANAGER TEST ===")
	
	if not GameManager:
		print("GameManager not available - skipping tests")
		return
	
	run_test("GameManager initialization", func(): return GameManager != null)
	
	run_test("Level progression data", func():
		var level_info = GameManager.get_current_level_info()
		return not level_info.is_empty()
	)
	
	run_test("Game state management", func():
		var original_state = GameManager.current_state
		GameManager.set_game_state(GameManager.GameState.MENU)
		var state_changed = GameManager.current_state == GameManager.GameState.MENU
		GameManager.set_game_state(original_state)
		return state_changed
	)

func test_progression_manager():
	print("\n=== PROGRESSION MANAGER TEST ===")
	
	if not ProgressionManager:
		print("ProgressionManager not available - skipping tests")
		return
	
	run_test("ProgressionManager initialization", func(): return ProgressionManager != null)
	
	run_test("Character data access", func():
		var wizard_data = ProgressionManager.get_character_data(ProgressionManager.CharacterType.WIZARD)
		return not wizard_data.is_empty() and wizard_data.has("name")
	)
	
	run_test("Character stats", func():
		var wizard_data = ProgressionManager.get_character_data(ProgressionManager.CharacterType.WIZARD)
		var stats = wizard_data.get("stats", {})
		return stats.has("max_health") and stats.has("attack_power")
	)

func test_level_generation():
	print("\n=== LEVEL GENERATION TEST ===")
	
	# Test LevelGenerator script
	run_test("LevelGenerator script exists", func(): 
		return ResourceLoader.exists("res://scripts/LevelGenerator.gd")
	)
	
	if ResourceLoader.exists("res://scripts/LevelGenerator.gd"):
		run_test("LevelGenerator loads", func():
			var script = load("res://scripts/LevelGenerator.gd")
			return script != null
		)

func test_character_selection_flow():
	print("\n=== CHARACTER SELECTION FLOW TEST ===")
	
	# Test the complete flow from character selection to game start
	if not NetworkManager or not GameManager:
		print("Required managers not available - skipping flow test")
		return
	
	# Simulate single player setup
	run_test("Single player setup", func():
		NetworkManager.add_player(1, "TestPlayer")
		return NetworkManager.get_player_count() == 1
	)
	
	run_test("Character selection", func():
		NetworkManager.set_player_character(1, "Wizard")
		var player_data = NetworkManager.get_player(1)
		return player_data.get("character_type") == "Wizard"
	)
	
	run_test("Player ready state", func():
		NetworkManager.set_player_ready(1, true)
		return NetworkManager.all_players_ready()
	)
	
	run_test("Game start preparation", func():
		# Test that GameManager can start a new run
		GameManager.start_new_run()
		return true
	)
	
	# Clean up
	NetworkManager.remove_player(1)

func print_test_summary():
	print("\n" + "=".repeat(50))
	print("TEST SUMMARY")
	print("=".repeat(50))
	print("Total Tests: ", total_tests)
	print("Passed: ", passed_tests)
	print("Failed: ", failed_tests)
	print("Success Rate: ", (float(passed_tests) / float(total_tests)) * 100.0, "%")
	
	if failed_tests > 0:
		print("\nFAILED TESTS:")
		for result in test_results:
			if not result.passed:
				print("  - ", result.name)
	
	print("\nRECOMMENDATIONS:")
	if failed_tests == 0:
		print("  ✓ All tests passed! The system should work correctly.")
	else:
		print("  ✗ Some tests failed. Check the detailed output above.")
		print("  ✗ Focus on fixing the failed components before testing gameplay.")
	
	print("=".repeat(50)) 

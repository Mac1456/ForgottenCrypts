extends Node

# Game state enums
enum GameState {
	MENU,
	CHARACTER_SELECT,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY
}

enum LevelType {
	CAVE,
	CATACOMB,
	CRYPT,
	CASTLE
}

# Current game state
var current_state = GameState.MENU
var current_level = 1
var current_level_type = LevelType.CAVE
var run_start_time = 0
var is_in_rest_area = false

# Level progression configuration
var level_progression = {
	1: {"type": LevelType.CAVE, "name": "Cavern Depths", "boss_type": "elite_skeleton"},
	2: {"type": LevelType.CAVE, "name": "Dark Tunnels", "boss_type": "elite_skeleton"},
	3: {"type": LevelType.CATACOMB, "name": "Bone Chambers", "boss_type": "witch_mini"},
	4: {"type": LevelType.CATACOMB, "name": "Crypt Passages", "boss_type": "witch_mini"},
	5: {"type": LevelType.CRYPT, "name": "Forgotten Tombs", "boss_type": "elite_hard"},
	6: {"type": LevelType.CRYPT, "name": "Shadow Vaults", "boss_type": "elite_hard"},
	7: {"type": LevelType.CASTLE, "name": "Witch's Castle", "boss_type": "witch_final"}
}

# Level choices for certain levels
var level_choices = {
	3: [
		{"type": LevelType.CATACOMB, "name": "Ancient Catacombs", "boss_type": "witch_mini"},
		{"type": LevelType.CATACOMB, "name": "Bone Gardens", "boss_type": "witch_mini"}
	],
	5: [
		{"type": LevelType.CRYPT, "name": "Cursed Crypts", "boss_type": "elite_hard"},
		{"type": LevelType.CRYPT, "name": "Unholy Sepulchers", "boss_type": "elite_hard"}
	]
}

# Run statistics
var run_stats = {
	"enemies_killed": 0,
	"bosses_defeated": 0,
	"items_collected": 0,
	"damage_dealt": 0,
	"damage_taken": 0,
	"deaths": 0,
	"revives": 0
}

# Signals
signal game_state_changed(new_state: GameState)
signal level_changed(new_level: int, level_info: Dictionary)
signal boss_defeated(boss_type: String)
signal run_completed(stats: Dictionary)
signal run_failed(reason: String)
signal player_entered_rest_area()
signal player_exited_rest_area()

func _ready():
	print("GameManager initialized")
	
	# Validate level progression data
	if not _validate_level_progression():
		push_error("Level progression data is invalid")
		return
	
	# Connect to NetworkManager signals
	if NetworkManager:
		if NetworkManager.player_connected.connect(_on_player_connected) == OK:
			print("Connected to NetworkManager.player_connected")
		else:
			push_error("Failed to connect to NetworkManager.player_connected")
		
		if NetworkManager.player_disconnected.connect(_on_player_disconnected) == OK:
			print("Connected to NetworkManager.player_disconnected")
		else:
			push_error("Failed to connect to NetworkManager.player_disconnected")
	else:
		push_error("NetworkManager not available")
	
	print("GameManager initialization complete")

# Set game state
func set_game_state(new_state: GameState):
	if current_state != new_state:
		var old_state = current_state
		current_state = new_state
		print("Game state changed: ", GameState.find_key(old_state), " -> ", GameState.find_key(new_state))
		game_state_changed.emit(new_state)

# Start a new run
func start_new_run():
	print("Starting new run...")
	
	# Validate prerequisites
	if not _validate_new_run_prerequisites():
		push_error("Prerequisites not met for new run")
		return
	
	current_level = 1
	current_level_type = LevelType.CAVE
	run_start_time = Time.get_ticks_msec()
	is_in_rest_area = false
	
	print("Run parameters set - Level: ", current_level, ", Type: ", LevelType.find_key(current_level_type))
	
	# Reset run statistics
	run_stats = {
		"enemies_killed": 0,
		"bosses_defeated": 0,
		"items_collected": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"deaths": 0,
		"revives": 0
	}
	
	print("Run statistics reset")
	
	# Reset all players to alive
	if NetworkManager:
		var players = NetworkManager.get_all_players()
		for player_id in players:
			NetworkManager.revive_player(player_id, 100)
		print("All players revived: ", players.keys())
	else:
		push_error("NetworkManager not available for player revival")
		return
	
	set_game_state(GameState.PLAYING)
	print("Game state set to PLAYING")
	
	advance_to_level(1)
	
	print("New run started successfully")

# Advance to next level
func advance_to_level(level: int):
	print("Advancing to level: ", level)
	
	if level > 7:
		print("Level ", level, " exceeds max level, completing run")
		complete_run()
		return
	
	if not level_progression.has(level):
		push_error("Level ", level, " not found in progression data")
		return
	
	current_level = level
	var level_info = level_progression[level]
	current_level_type = level_info["type"]
	
	print("Level advanced - Current: ", current_level, ", Type: ", LevelType.find_key(current_level_type))
	print("Level info: ", level_info)
	
	level_changed.emit(level, level_info)
	
	# Load appropriate level scene
	_load_level_scene(level_info)

# Get level choices for current level
func get_level_choices() -> Array:
	if current_level in level_choices:
		return level_choices[current_level]
	return []

# Choose level variant
func choose_level_variant(choice_index: int):
	if current_level in level_choices:
		var choices = level_choices[current_level]
		if choice_index < choices.size():
			var chosen_level = choices[choice_index]
			level_progression[current_level] = chosen_level
			print("Level choice made: ", chosen_level["name"])

# Complete current level
func complete_level():
	var level_info = level_progression[current_level]
	print("Level ", current_level, " completed: ", level_info["name"])
	
	# Enter rest area
	enter_rest_area()
	
	# Award experience
	var xp_reward = get_level_xp_reward(current_level)
	ProgressionManager.award_experience(xp_reward)
	
	# Check if this was the final level
	if current_level >= 7:
		complete_run()
	else:
		# Prepare for next level
		current_level += 1

# Enter rest area between levels
func enter_rest_area():
	is_in_rest_area = true
	print("Entered rest area")
	player_entered_rest_area.emit()
	
	# Heal all living players
	for player_id in NetworkManager.get_all_players():
		var player_data = NetworkManager.get_player(player_id)
		if player_data.get("alive", false):
			NetworkManager.sync_player_health(player_id, player_data["max_health"], player_data["max_health"])

# Exit rest area and continue to next level
func exit_rest_area():
	is_in_rest_area = false
	print("Exited rest area")
	player_exited_rest_area.emit()
	
	# Continue to next level
	advance_to_level(current_level)

# Boss defeated
func defeat_boss(boss_type: String):
	run_stats["bosses_defeated"] += 1
	boss_defeated.emit(boss_type)
	
	# Revive all dead players
	for player_id in NetworkManager.get_all_players():
		var player_data = NetworkManager.get_player(player_id)
		if not player_data.get("alive", true):
			NetworkManager.revive_player(player_id, 50)  # Revive with half health
	
	print("Boss defeated: ", boss_type)
	
	# Complete level after boss defeat
	complete_level()

# Complete entire run
func complete_run():
	print("Completing run...")
	
	# Calculate final statistics
	var final_stats = run_stats.duplicate()
	final_stats["total_time"] = (Time.get_ticks_msec() - run_start_time) / 1000.0
	final_stats["levels_completed"] = current_level
	
	print("Final run statistics: ", final_stats)
	
	set_game_state(GameState.VICTORY)
	run_completed.emit(final_stats)
	
	print("Run completed successfully")

# Fail the run
func fail_run(reason: String):
	print("Run failed: ", reason)
	run_failed.emit(reason)
	set_game_state(GameState.GAME_OVER)

# Check if run should fail (all players dead)
func check_run_failure():
	print("Checking for run failure...")
	
	if not NetworkManager:
		push_error("NetworkManager not available for run failure check")
		return
	
	var alive_players = 0
	var all_players = NetworkManager.get_all_players()
	
	for player_id in all_players:
		var player_data = NetworkManager.get_player(player_id)
		if player_data.get("alive", false):
			alive_players += 1
	
	print("Alive players: ", alive_players, "/", all_players.size())
	
	if alive_players == 0:
		print("All players are dead - run failed")
		set_game_state(GameState.GAME_OVER)
		run_failed.emit("All players died")
	else:
		print("Run continues - ", alive_players, " players still alive")

# Get XP reward for completing a level
func get_level_xp_reward(level: int) -> int:
	var base_xp = 100
	var level_multiplier = level * 0.5
	var difficulty_multiplier = NetworkManager.get_difficulty_multiplier()
	
	return int(base_xp * (1.0 + level_multiplier) * difficulty_multiplier)

# Get completion bonus XP
func get_completion_bonus() -> int:
	var base_bonus = 1000
	var time_bonus = max(0, 2400 - (run_stats["run_time"] as int))  # Bonus for completing under 40 minutes
	var difficulty_multiplier = NetworkManager.get_difficulty_multiplier()
	
	return int((base_bonus + time_bonus) * difficulty_multiplier)

# Update run statistics
func update_stat(stat_name: String, value: int):
	if stat_name in run_stats:
		run_stats[stat_name] += value
		print("Stat updated: ", stat_name, " = ", run_stats[stat_name])

# Get current run statistics
func get_run_stats() -> Dictionary:
	return run_stats.duplicate()

# Get current level info
func get_current_level_info() -> Dictionary:
	print("Getting current level info for level: ", current_level)
	
	if not level_progression.has(current_level):
		push_error("Level ", current_level, " not found in progression data")
		return {}
	
	var level_info = level_progression[current_level]
	print("Level info retrieved: ", level_info)
	
	return level_info

# Get estimated run progress (0.0 to 1.0)
func get_run_progress() -> float:
	return float(current_level - 1) / 7.0

# Check if player can advance (for level choice UI)
func can_advance_to_next_level() -> bool:
	return is_in_rest_area and NetworkManager.all_players_ready()

# Load level scene based on level info
func _load_level_scene(level_info: Dictionary):
	print("Loading level scene for level info: ", level_info)
	
	var scene_path = ""
	
	match level_info["type"]:
		LevelType.CAVE:
			scene_path = "res://scenes/levels/CaveLevel.tscn"
		LevelType.CATACOMB:
			scene_path = "res://scenes/levels/CatacombLevel.tscn"
		LevelType.CRYPT:
			scene_path = "res://scenes/levels/CryptLevel.tscn"
		LevelType.CASTLE:
			scene_path = "res://scenes/levels/CastleLevel.tscn"
	
	# For now, we'll use a generic level scene
	scene_path = "res://scenes/levels/GameLevel.tscn"
	
	print("Level scene path determined: ", scene_path)
	
	# Validate scene path
	if not ResourceLoader.exists(scene_path):
		push_error("Level scene not found at: ", scene_path)
		return
	
	print("Level scene validated and exists")
	
	# Note: In a full implementation, we'd load the scene here
	# The actual loading is handled by GameWorld
	print("Level scene loading delegated to GameWorld")

# Network event handlers
func _on_player_connected(id: int):
	print("Player connected to game: ", id)

func _on_player_disconnected(id: int):
	print("Player disconnected from game: ", id)
	# Check if we should pause the game or handle disconnection
	if current_state == GameState.PLAYING:
		# In a full implementation, we might pause here
		pass

# Handle player death
func handle_player_death(player_id: int):
	run_stats["deaths"] += 1
	NetworkManager.player_died(player_id)
	
	# Check if all players are dead
	check_run_failure()

# Handle player revival
func handle_player_revival(player_id: int, reviver_id: int = -1):
	run_stats["revives"] += 1
	NetworkManager.revive_player(player_id, 50)
	
	if reviver_id != -1:
		print("Player ", player_id, " revived by player ", reviver_id)
	else:
		print("Player ", player_id, " revived by NPC or boss defeat")

# Check if level has choices
func level_has_choices(level: int) -> bool:
	return level in level_choices

# Get difficulty description
func get_difficulty_description() -> String:
	var player_count = NetworkManager.get_player_count()
	match player_count:
		1:
			return "Solo Adventure"
		2:
			return "Duo Challenge"
		3:
			return "Team Expedition"
		4:
			return "Full Party Assault"
		_:
			return "Unknown Difficulty" 

func _validate_level_progression() -> bool:
	var validation_passed = true
	
	if level_progression.is_empty():
		push_error("Level progression data is empty")
		validation_passed = false
	
	for level_num in level_progression:
		var level_data = level_progression[level_num]
		
		if not level_data.has("type"):
			push_error("Level ", level_num, " missing 'type' field")
			validation_passed = false
		
		if not level_data.has("name"):
			push_error("Level ", level_num, " missing 'name' field")
			validation_passed = false
		
		if not level_data.has("boss_type"):
			push_error("Level ", level_num, " missing 'boss_type' field")
			validation_passed = false
	
	print("Level progression validation: ", "PASSED" if validation_passed else "FAILED")
	return validation_passed

func _validate_new_run_prerequisites() -> bool:
	var validation_passed = true
	
	if not NetworkManager:
		push_error("NetworkManager required for new run")
		validation_passed = false
	
	if NetworkManager and NetworkManager.get_player_count() == 0:
		push_error("No players available for new run")
		validation_passed = false
	
	if not level_progression.has(1):
		push_error("Level 1 not found in progression data")
		validation_passed = false
	
	print("New run prerequisites: ", "PASSED" if validation_passed else "FAILED")
	return validation_passed 
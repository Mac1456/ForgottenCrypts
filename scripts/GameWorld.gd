extends Node2D

# UI nodes
@onready var level_info = $UILayer/GameHUD/TopPanel/HBoxContainer/LevelInfo
@onready var player_count = $UILayer/GameHUD/TopPanel/HBoxContainer/PlayerCount
@onready var run_time = $UILayer/GameHUD/TopPanel/HBoxContainer/RunTime
@onready var debug_panel = $UILayer/GameHUD/DebugPanel

# Game world nodes
@onready var player_spawns = $GameWorld/PlayerSpawnPoints
@onready var enemy_spawns = $GameWorld/EnemySpawnPoints
@onready var players_node = $GameWorld/Players
@onready var enemies_node = $GameWorld/Enemies
@onready var projectiles_node = $GameWorld/Projectiles
@onready var pickups_node = $GameWorld/Pickups

# Game state
var run_start_time = 0
var current_level_data = {}
var spawned_players = {}

# Timer for UI updates
var ui_update_timer = 0.0
var ui_update_interval = 1.0  # Update every second

func _ready():
	print("GameWorld loaded")
	
	# Validate essential nodes
	if not _validate_essential_nodes():
		push_error("Essential nodes missing - GameWorld cannot function properly")
		return
	
	# Set game state
	if GameManager:
		GameManager.set_game_state(GameManager.GameState.PLAYING)
		print("Game state set to PLAYING")
	else:
		push_error("GameManager not available")
		return
	
	# Connect to signals
	if not _connect_manager_signals():
		push_error("Failed to connect manager signals")
		return
	
	# Initialize the game world with a small delay to ensure everything is ready
	print("Initializing game world...")
	await get_tree().process_frame  # Wait one frame for all nodes to be ready
	initialize_game_world()
	
	# Start UI update timer
	run_start_time = Time.get_ticks_msec()
	print("UI update timer started")
	
	# Hide debug panel in release builds
	if debug_panel:
		debug_panel.visible = OS.is_debug_build()
		print("Debug panel visibility set to: ", OS.is_debug_build())
	else:
		push_error("Debug panel node not found")
	
	print("GameWorld initialization complete")

func _process(delta):
	# Update UI periodically
	ui_update_timer += delta
	if ui_update_timer >= ui_update_interval:
		ui_update_timer = 0.0
		update_ui()

func _validate_essential_nodes() -> bool:
	var validation_passed = true
	var required_nodes = [
		{"name": "player_spawns", "node": player_spawns},
		{"name": "enemy_spawns", "node": enemy_spawns},
		{"name": "players_node", "node": players_node},
		{"name": "enemies_node", "node": enemies_node},
		{"name": "projectiles_node", "node": projectiles_node},
		{"name": "pickups_node", "node": pickups_node}
	]
	
	# Check essential game nodes
	for node_info in required_nodes:
		if not node_info.node:
			push_error("Required node not found: ", node_info.name)
			validation_passed = false
		else:
			print("Node found: ", node_info.name)
	
	# Check UI nodes (optional - just report warnings)
	var ui_nodes = [
		{"name": "level_info", "node": level_info},
		{"name": "player_count", "node": player_count},
		{"name": "run_time", "node": run_time},
		{"name": "debug_panel", "node": debug_panel}
	]
	
	for node_info in ui_nodes:
		if not node_info.node:
			print("Warning: UI node not found: ", node_info.name)
		else:
			print("UI node found: ", node_info.name)
	
	print("Essential nodes validation: ", "PASSED" if validation_passed else "FAILED")
	return validation_passed

func _connect_manager_signals() -> bool:
	var connections_made = 0
	var expected_connections = 6
	
	if GameManager:
		if GameManager.level_changed.connect(_on_level_changed) == OK:
			connections_made += 1
		else:
			push_error("Failed to connect level_changed signal")
		
		if GameManager.boss_defeated.connect(_on_boss_defeated) == OK:
			connections_made += 1
		else:
			push_error("Failed to connect boss_defeated signal")
		
		if GameManager.run_completed.connect(_on_run_completed) == OK:
			connections_made += 1
		else:
			push_error("Failed to connect run_completed signal")
		
		if GameManager.run_failed.connect(_on_run_failed) == OK:
			connections_made += 1
		else:
			push_error("Failed to connect run_failed signal")
	else:
		push_error("GameManager not available for signal connections")
	
	if NetworkManager:
		if NetworkManager.player_connected.connect(_on_player_connected) == OK:
			connections_made += 1
		else:
			push_error("Failed to connect player_connected signal")
		
		if NetworkManager.player_disconnected.connect(_on_player_disconnected) == OK:
			connections_made += 1
		else:
			push_error("Failed to connect player_disconnected signal")
	else:
		push_error("NetworkManager not available for signal connections")
	
	print("Manager signal connections: ", connections_made, "/", expected_connections)
	return connections_made == expected_connections

func initialize_game_world():
	print("Initializing game world...")
	
	# Get current level info
	if GameManager:
		current_level_data = GameManager.get_current_level_info()
		print("Current level data: ", current_level_data)
	else:
		push_error("GameManager not available for level info")
		return
	
	# Validate level data
	if not _validate_level_data(current_level_data):
		push_error("Invalid level data")
		return
	
	# Spawn players
	print("Spawning players...")
	spawn_all_players()
	print("Player spawning completed")
	
	# Update UI
	print("Updating UI...")
	update_ui()
	print("UI update completed")
	
	# Load the actual level using the new level system
	print("Loading generated level...")
	_load_generated_level()
	print("Generated level loading completed")
	
	print("Game world initialized for level: ", current_level_data.get("name", "Unknown"))

func _validate_level_data(level_data: Dictionary) -> bool:
	var validation_passed = true
	
	if level_data.is_empty():
		push_error("Level data is empty")
		validation_passed = false
	
	if not level_data.has("name"):
		push_error("Level data missing 'name' field")
		validation_passed = false
	
	if not level_data.has("type"):
		push_error("Level data missing 'type' field")
		validation_passed = false
	
	if not level_data.has("boss_type"):
		push_error("Level data missing 'boss_type' field")
		validation_passed = false
	
	print("Level data validation: ", "PASSED" if validation_passed else "FAILED")
	return validation_passed

func _load_generated_level():
	print("Loading generated level...")
	
	# Clear any existing level
	var cleared_levels = 0
	for child in get_children():
		if child.name.begins_with("GameLevel"):
			child.queue_free()
			cleared_levels += 1
	
	if cleared_levels > 0:
		print("Cleared ", cleared_levels, " existing GameLevel instances")
	
	# Validate GameLevel scene path
	var level_scene_path = "res://scenes/levels/GameLevel.tscn"
	if not ResourceLoader.exists(level_scene_path):
		push_error("GameLevel scene not found at: ", level_scene_path)
		return
	
	# Load the GameLevel scene which handles procedural generation
	var level_scene = preload("res://scenes/levels/GameLevel.tscn")
	if not level_scene:
		push_error("Failed to preload GameLevel scene")
		return
	
	var level_instance = level_scene.instantiate()
	if not level_instance:
		push_error("Failed to instantiate GameLevel scene")
		return
	
	level_instance.name = "GameLevel"
	print("GameLevel instance created successfully")
	
	# Connect level signals first
	var signals_connected = 0
	if level_instance.has_signal("level_ready"):
		if level_instance.level_ready.connect(_on_level_ready) == OK:
			signals_connected += 1
		else:
			push_error("Failed to connect level_ready signal")
	
	if level_instance.has_signal("level_completed"):
		if level_instance.level_completed.connect(_on_level_completed) == OK:
			signals_connected += 1
		else:
			push_error("Failed to connect level_completed signal")
	
	if level_instance.has_signal("boss_spawned_signal"):
		if level_instance.boss_spawned_signal.connect(_on_boss_spawned) == OK:
			signals_connected += 1
		else:
			push_error("Failed to connect boss_spawned_signal")
	
	if level_instance.has_signal("all_enemies_defeated"):
		if level_instance.all_enemies_defeated.connect(_on_all_enemies_defeated) == OK:
			signals_connected += 1
		else:
			push_error("Failed to connect all_enemies_defeated signal")
	
	print("GameLevel signals connected: ", signals_connected, "/4")
	
	# Add level to the game world
	add_child(level_instance)
	print("GameLevel added to scene tree as child of GameWorld")
	
	# Validate level instance has required method
	if not level_instance.has_method("initialize_level"):
		push_error("GameLevel missing initialize_level method")
		return
	
	# Initialize the level with current level data
	level_instance.initialize_level(current_level_data, GameManager.current_level)
	print("GameLevel initialized successfully")
	
	print("Generated level loaded and initialized")

func _on_level_ready():
	print("Level is ready for gameplay")

func _on_level_completed():
	print("Level completed!")
	GameManager.complete_level()

func _on_boss_spawned():
	print("Boss has spawned!")
	# Play boss spawn sound if AudioManager is available
	if get_node_or_null("/root/AudioManager"):
		get_node("/root/AudioManager").play_environment_sound("boss_spawn")

func _on_all_enemies_defeated():
	print("All enemies defeated!")

func spawn_all_players():
	print("Spawning all players...")
	
	# Clear existing players
	var cleared_players = 0
	for child in players_node.get_children():
		child.queue_free()
		cleared_players += 1
	
	if cleared_players > 0:
		print("Cleared ", cleared_players, " existing players")
	
	spawned_players.clear()
	
	# Get all connected players
	if not NetworkManager:
		push_error("NetworkManager not available for player spawning")
		return
	
	var all_players = NetworkManager.get_all_players()
	print("Connected players: ", all_players.keys())
	
	if all_players.is_empty():
		push_error("No players found in NetworkManager")
		return
	
	var spawn_points = player_spawns.get_children()
	print("Available spawn points: ", spawn_points.size())
	
	if spawn_points.is_empty():
		push_error("No player spawn points found")
		return
	
	var spawn_index = 0
	var spawned_count = 0
	
	for player_id in all_players:
		var player_data = all_players[player_id]
		
		# Only spawn alive players
		if player_data.get("alive", true):
			if spawn_index < spawn_points.size():
				if spawn_player(player_id, player_data, spawn_points[spawn_index]):
					spawned_count += 1
				spawn_index += 1
			else:
				push_error("Not enough spawn points for player: ", player_id)
	
	print("Players spawned: ", spawned_count, "/", all_players.size())

func spawn_player(player_id: int, player_data: Dictionary, spawn_point: Node2D) -> bool:
	print("Spawning player: ", player_data.get("name", "Unknown"), " (ID: ", player_id, ") at ", spawn_point.position)
	
	# Validate player data
	if not _validate_player_data(player_data):
		push_error("Invalid player data for player: ", player_id)
		return false
	
	# Validate spawn point
	if not spawn_point:
		push_error("Invalid spawn point for player: ", player_id)
		return false
	
	# Create the appropriate character class
	var player_scene_path = "res://scenes/characters/Player.tscn"
	if not ResourceLoader.exists(player_scene_path):
		push_error("Player scene not found at: ", player_scene_path)
		return false
	
	var player_scene = preload("res://scenes/characters/Player.tscn")
	if not player_scene:
		push_error("Failed to preload Player scene")
		return false
	
	var player_node = player_scene.instantiate()
	if not player_node:
		push_error("Failed to instantiate Player scene")
		return false
	
	print("Player node created successfully")
	
	# Determine character type
	var character_type = ProgressionManager.CharacterType.WIZARD
	var character_type_str = player_data.get("character_type", "")
	
	match character_type_str:
		"Wizard":
			character_type = ProgressionManager.CharacterType.WIZARD
		"Barbarian":
			character_type = ProgressionManager.CharacterType.BARBARIAN
		"Rogue":
			character_type = ProgressionManager.CharacterType.ROGUE
		"Knight":
			character_type = ProgressionManager.CharacterType.KNIGHT
		_:
			push_error("Unknown character type: ", character_type_str, " for player: ", player_id)
			character_type = ProgressionManager.CharacterType.WIZARD
	
	print("Character type determined: ", ProgressionManager.CharacterType.find_key(character_type))
	
	# Determine which character class to use
	var character_script = _get_character_script(character_type)
	if not character_script:
		push_error("Failed to get character script for type: ", character_type)
		return false
	
	# Set character script
	player_node.set_script(character_script)
	print("Character script set successfully")
	
	# Validate player node has required method
	if not player_node.has_method("initialize_player"):
		push_error("Player node missing initialize_player method")
		player_node.queue_free()
		return false
	
	# Initialize player with error handling
	print("Calling initialize_player...")
	player_node.initialize_player(player_id, player_data["name"], character_type, player_id == NetworkManager.local_player_id)
	print("Player initialized successfully")
	
	# Position player at spawn point
	player_node.global_position = spawn_point.position
	print("Player positioned at: ", spawn_point.position)
	
	# Add player to scene
	players_node.add_child(player_node)
	print("Player added to scene tree")
	
	# Add to players group
	player_node.add_to_group("players")
	print("Player added to 'players' group")
	
	# Connect player signals
	var signals_connected = 0
	if player_node.has_signal("player_died"):
		if player_node.player_died.connect(_on_player_died) == OK:
			signals_connected += 1
		else:
			push_error("Failed to connect player_died signal")
	
	if player_node.has_signal("player_took_damage"):
		if player_node.player_took_damage.connect(_on_player_took_damage) == OK:
			signals_connected += 1
		else:
			push_error("Failed to connect player_took_damage signal")
	else:
		push_error("Player missing player_took_damage signal")
	
	print("Player signals connected: ", signals_connected, "/2")
	
	# Store reference
	spawned_players[player_id] = player_node
	print("Player spawning completed successfully for: ", player_data.get("name", "Unknown"))
	
	return true

func _validate_player_data(player_data: Dictionary) -> bool:
	var validation_passed = true
	
	if not player_data.has("name"):
		push_error("Player data missing 'name' field")
		validation_passed = false
	
	if not player_data.has("character_type"):
		push_error("Player data missing 'character_type' field")
		validation_passed = false
	
	if not player_data.has("alive"):
		push_error("Player data missing 'alive' field")
		validation_passed = false
	
	return validation_passed

func _get_character_script(character_type: ProgressionManager.CharacterType) -> GDScript:
	var script_path = ""
	
	match character_type:
		ProgressionManager.CharacterType.WIZARD:
			script_path = "res://scripts/characters/Wizard.gd"
		ProgressionManager.CharacterType.BARBARIAN:
			script_path = "res://scripts/characters/Barbarian.gd"
		ProgressionManager.CharacterType.ROGUE:
			script_path = "res://scripts/characters/Rogue.gd"
		ProgressionManager.CharacterType.KNIGHT:
			script_path = "res://scripts/characters/Knight.gd"
		_:
			push_error("Unknown character type: ", character_type)
			return null
	
	print("Looking for character script at: ", script_path)
	
	if not ResourceLoader.exists(script_path):
		push_error("Character script not found: ", script_path)
		return null
	
	var script = load(script_path)
	if not script:
		push_error("Failed to load character script: ", script_path)
		return null
	
	print("Character script loaded successfully: ", script_path)
	return script

func update_ui():
	# Update level info
	if level_info:
		level_info.text = "Level " + str(GameManager.current_level) + ": " + current_level_data.get("name", "Unknown")
	else:
		print("Warning: level_info UI node not found")
	
	# Update player count
	if player_count:
		var alive_players = 0
		var total_players = NetworkManager.get_player_count()
		
		for player_id in NetworkManager.get_all_players():
			var player_data = NetworkManager.get_player(player_id)
			if player_data.get("alive", true):
				alive_players += 1
		
		player_count.text = "Players: " + str(alive_players) + "/" + str(total_players)
	else:
		print("Warning: player_count UI node not found")
	
	# Update run time
	if run_time:
		if run_start_time > 0:
			var elapsed_time = (Time.get_ticks_msec() - run_start_time) / 1000.0
			var minutes = int(elapsed_time / 60)
			var seconds = int(elapsed_time) % 60
			run_time.text = "Time: %02d:%02d" % [minutes, seconds]
	else:
		print("Warning: run_time UI node not found")

func spawn_test_enemy():
	print("Spawning test enemy...")
	
	# Create actual enemy
	var enemy_spawns_list = enemy_spawns.get_children()
	if enemy_spawns_list.size() > 0:
		var spawn_point = enemy_spawns_list[randi() % enemy_spawns_list.size()]
		
		# Choose random enemy type
		var enemy_types = ["SkeletonGrunt", "SkeletonArcher"]
		var enemy_type = enemy_types[randi() % enemy_types.size()]
		
		var enemy_node = null
		match enemy_type:
			"SkeletonGrunt":
				var skeleton_scene = preload("res://scenes/enemies/SkeletonGrunt.tscn")
				enemy_node = skeleton_scene.instantiate()
			"SkeletonArcher":
				# For now, use SkeletonGrunt as base
				var skeleton_scene = preload("res://scenes/enemies/SkeletonGrunt.tscn")
				enemy_node = skeleton_scene.instantiate()
				# Apply archer script
				enemy_node.set_script(preload("res://scripts/enemies/SkeletonArcher.gd"))
		
		if enemy_node:
			enemy_node.global_position = spawn_point.position
			enemy_node.name = enemy_type + "_" + str(randi())
			
			# Add to enemies group
			enemy_node.add_to_group("enemies")
			
			# Connect enemy signals
			enemy_node.enemy_died.connect(_on_enemy_died)
			enemy_node.enemy_spotted_player.connect(_on_enemy_spotted_player)
			enemy_node.enemy_lost_player.connect(_on_enemy_lost_player)
			
			# Add to scene
			enemies_node.add_child(enemy_node)
		
		# Add simple AI movement
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(enemy_node, "position", spawn_point.position + Vector2(100, 0), 2.0)
		tween.tween_property(enemy_node, "position", spawn_point.position, 2.0)
		
		enemies_node.add_child(enemy_node)
		print("Test enemy spawned at: ", spawn_point.position)

# Signal handlers
func _on_level_changed(new_level: int, level_info: Dictionary):
	print("Level changed to: ", new_level, " - ", level_info.get("name", "Unknown"))
	current_level_data = level_info
	
	# Respawn players for new level
	spawn_all_players()
	
	# Update UI
	update_ui()

func _on_boss_defeated(boss_type: String):
	print("Boss defeated: ", boss_type)
	# TODO: Show victory screen, collect rewards, etc.

func _on_run_completed(stats: Dictionary):
	print("Run completed! Stats: ", stats)
	# TODO: Show completion screen with stats
	
	# Return to main menu after a delay
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_run_failed(reason: String):
	print("Run failed: ", reason)
	# TODO: Show failure screen
	
	# Return to main menu after a delay
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_player_connected(id: int):
	print("Player connected to game world: ", id)
	# Spawn the new player
	var player_data = NetworkManager.get_player(id)
	if player_data.get("alive", true):
		var spawn_points = player_spawns.get_children()
		var spawn_index = spawned_players.size() % spawn_points.size()
		spawn_player(id, player_data, spawn_points[spawn_index])

func _on_player_disconnected(id: int):
	print("Player disconnected from game world: ", id)
	# Remove the player
	if id in spawned_players:
		spawned_players[id].queue_free()
		spawned_players.erase(id)

# Debug button handlers
func _on_test_button_pressed():
	print("Test button pressed")
	# Test network sync
	NetworkManager.update_player_data(NetworkManager.local_player_id, {"test": "data"})

func _on_add_xp_button_pressed():
	print("Add XP button pressed")
	ProgressionManager.award_experience(100)

func _on_spawn_enemy_button_pressed():
	print("Spawn enemy button pressed")
	spawn_test_enemy()

func _on_next_level_button_pressed():
	print("Next level button pressed")
	
	# Simulate boss defeat to advance level
	var current_level_info = GameManager.get_current_level_info()
	GameManager.defeat_boss(current_level_info.get("boss_type", "test_boss"))

func _on_main_menu_button_pressed():
	print("Main menu button pressed")
	
	# Disconnect from network
	NetworkManager.disconnect_game()
	
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# Handle input
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		# Show pause menu or return to main menu
		_on_main_menu_button_pressed()
	
	# Debug shortcuts
	if OS.is_debug_build():
		if event.is_action_pressed("ui_accept"):
			spawn_test_enemy()
		if event.is_action_pressed("ui_select"):
			ProgressionManager.award_experience(50)

# Network sync for multiplayer
@rpc("any_peer", "call_local", "reliable")
func sync_enemy_spawn(position: Vector2):
	print("Syncing enemy spawn at: ", position)
	# TODO: Implement networked enemy spawning

@rpc("any_peer", "call_local", "reliable")
func sync_player_action(player_id: int, action: String, data: Dictionary):
	print("Player ", player_id, " performed action: ", action, " with data: ", data)
	# TODO: Implement networked player actions

# Player signal handlers
func _on_player_died(player_id: int):
	print("Player ", player_id, " died!")
	GameManager.handle_player_death(player_id)

func _on_player_took_damage(player_id: int, damage: int):
	print("Player ", player_id, " took ", damage, " damage")
	# Update UI or handle damage effects

# Enemy signal handlers
func _on_enemy_died(enemy: Enemy):
	print("Enemy ", enemy.enemy_name, " died!")
	GameManager.update_stat("enemies_killed", 1)

func _on_enemy_spotted_player(enemy: Enemy, player: Node):
	print("Enemy ", enemy.enemy_name, " spotted player ", player.player_name)
	# Could trigger alert music or effects

func _on_enemy_lost_player(enemy: Enemy):
	print("Enemy ", enemy.enemy_name, " lost player")
	# Could return to calm music 

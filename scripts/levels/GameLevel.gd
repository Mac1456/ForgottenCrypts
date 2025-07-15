extends Node2D

# Node references
@onready var level_generator = $LevelGenerator
@onready var tilemap = $TileMapLayer/TileMap
@onready var player_spawns = $GameplayLayer/PlayerSpawns
@onready var enemy_spawns = $GameplayLayer/EnemySpawns
@onready var boss_spawn = $GameplayLayer/BossSpawn
@onready var players_node = $GameplayLayer/Players
@onready var enemies_node = $GameplayLayer/Enemies
@onready var boss_node = $GameplayLayer/Boss
@onready var projectiles_node = $GameplayLayer/Projectiles
@onready var pickups_node = $GameplayLayer/Pickups
@onready var effects_node = $GameplayLayer/Effects
@onready var props_node = $ObjectLayer/Props
@onready var decorations_node = $ObjectLayer/Decorations
@onready var lighting_node = $ObjectLayer/Lighting

# UI references
@onready var level_title = $UILayer/LevelHUD/TopBar/HBoxContainer/LevelTitle
@onready var objective_label = $UILayer/LevelHUD/TopBar/HBoxContainer/ObjectiveLabel
@onready var progress_bar = $UILayer/LevelHUD/TopBar/HBoxContainer/ProgressBar
@onready var boss_warning = $UILayer/LevelHUD/BossWarning
@onready var ambient_sound = $AudioManager/AmbientSound

# Level data
var current_level_info: Dictionary = {}
var level_type: int  # Use int instead of LevelGenerator.LevelType
var total_enemies: int = 0
var enemies_killed: int = 0
var boss_spawned: bool = false
var level_complete: bool = false
var spawned_players: Dictionary = {}
var spawned_enemies: Array = []
var level_seed: int = 0

# Signals
signal level_ready()
signal level_completed()
signal boss_spawned_signal()
signal all_enemies_defeated()

func _ready():
	print("GameLevel initialized")
	
	# Connect level generator signals
	level_generator.level_generated.connect(_on_level_generated)
	level_generator.spawn_points_ready.connect(_on_spawn_points_ready)
	
	# Connect game manager signals
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.boss_defeated.connect(_on_boss_defeated)
	
	# Connect network signals
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)

# Initialize level with given information
func initialize_level(level_info: Dictionary, seed_value: int = -1):
	print("Initializing level: ", level_info.get("name", "Unknown"))
	
	current_level_info = level_info
	level_seed = seed_value if seed_value != -1 else randi()
	
	# Determine level type
	level_type = _get_level_type_from_info(level_info)
	
	# Update UI
	if level_title:
		level_title.text = "Level %d: %s" % [GameManager.current_level, level_info.get("name", "Unknown")]
	else:
		print("Warning: level_title UI node not found")
	
	if objective_label:
		objective_label.text = "Objective: Clear all enemies"
	else:
		print("Warning: objective_label UI node not found")
	
	if progress_bar:
		progress_bar.value = 0
	else:
		print("Warning: progress_bar UI node not found")
	
	# Generate level
	generate_level()

# Generate the level using the level generator
func generate_level():
	var level_type_names = ["CAVE", "CATACOMB", "CRYPT", "CASTLE"]
	print("Generating level of type: ", level_type_names[level_type])
	
	# Clear existing level
	_clear_level()
	
	# Generate new level
	print("Calling level_generator.generate_level...")
	var generated_tilemap = await level_generator.generate_level(level_type, level_seed)
	print("Level generator returned tilemap: ", generated_tilemap)
	
	# Replace tilemap if generation was successful
	if generated_tilemap:
		tilemap.queue_free()
		tilemap = generated_tilemap
		$TileMapLayer.add_child(tilemap)
		tilemap.z_index = -1
	else:
		print("ERROR: Failed to generate tilemap, using empty level")
		# Create a simple empty room as fallback
		_create_fallback_level()
	
	# Debug tilemap info
	print("Tilemap position: ", tilemap.position)
	print("Tilemap scale: ", tilemap.scale)
	print("Tilemap z_index: ", tilemap.z_index)
	print("Tilemap cell count: ", tilemap.get_used_cells(0).size())
	
	# Position tilemap at origin
	tilemap.position = Vector2.ZERO
	
	print("Level generation complete - tilemap added to scene")

# Create a simple fallback level if generation fails
func _create_fallback_level():
	print("Creating fallback level...")
	
	# Create a simple tilemap with a basic room
	var fallback_tilemap = TileMap.new()
	var tileset = TileSet.new()
	
	# Create a simple colored tile source
	var source = TileSetAtlasSource.new()
	
	# Create a simple colored texture
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.GRAY)
	var texture = ImageTexture.create_from_image(image)
	source.texture = texture
	source.texture_region_size = Vector2i(16, 16)
	
	# Add physics layer
	tileset.add_physics_layer(0)
	
	# Create a simple tile
	source.create_tile(Vector2i(0, 0))
	tileset.add_source(source, 0)
	
	fallback_tilemap.tile_set = tileset
	
	# Create a simple 20x15 room
	for x in range(20):
		for y in range(15):
			if x == 0 or x == 19 or y == 0 or y == 14:
				# Wall tiles
				fallback_tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))
	
	# Replace the tilemap
	tilemap.queue_free()
	tilemap = fallback_tilemap
	$TileMapLayer.add_child(tilemap)
	tilemap.z_index = -1
	
	print("Fallback level created")

# Clear existing level data
func _clear_level():
	# Clear enemies
	for enemy in enemies_node.get_children():
		enemy.queue_free()
	spawned_enemies.clear()
	
	# Clear boss
	for boss in boss_node.get_children():
		boss.queue_free()
	
	# Clear projectiles
	for projectile in projectiles_node.get_children():
		projectile.queue_free()
	
	# Clear pickups
	for pickup in pickups_node.get_children():
		pickup.queue_free()
	
	# Clear effects
	for effect in effects_node.get_children():
		effect.queue_free()
	
	# Clear props and decorations
	for prop in props_node.get_children():
		prop.queue_free()
	for decoration in decorations_node.get_children():
		decoration.queue_free()
	
	# Reset level state
	total_enemies = 0
	enemies_killed = 0
	boss_spawned = false
	level_complete = false

# Get level type from level info
func _get_level_type_from_info(level_info: Dictionary) -> int:
	var type_key = level_info.get("type", GameManager.LevelType.CAVE)
	
	match type_key:
		GameManager.LevelType.CAVE:
			return 0  # LevelGenerator.LevelType.CAVE
		GameManager.LevelType.CATACOMB:
			return 1  # LevelGenerator.LevelType.CATACOMB
		GameManager.LevelType.CRYPT:
			return 2  # LevelGenerator.LevelType.CRYPT
		GameManager.LevelType.CASTLE:
			return 3  # LevelGenerator.LevelType.CASTLE
		_:
			return 0  # LevelGenerator.LevelType.CAVE

# Handle level generation completion
func _on_level_generated(generated_tilemap: TileMap):
	print("Level tilemap generated - signal received")
	
	# Add decorative elements
	_add_decorative_elements()
	
	# Add lighting
	_add_lighting_elements()
	
	print("Decorative elements and lighting added")

# Handle spawn points ready
func _on_spawn_points_ready(player_spawn_points: Array, enemy_spawn_points: Array, boss_spawn_point: Vector2):
	print("Spawn points ready - Players: ", player_spawn_points.size(), " Enemies: ", enemy_spawn_points.size())
	
	# Clear existing spawn markers
	for child in player_spawns.get_children():
		child.queue_free()
	for child in enemy_spawns.get_children():
		child.queue_free()
	
	# Create player spawn markers
	for i in range(player_spawn_points.size()):
		var spawn_marker = Marker2D.new()
		spawn_marker.name = "PlayerSpawn" + str(i)
		spawn_marker.position = player_spawn_points[i]
		player_spawns.add_child(spawn_marker)
	
	# Create enemy spawn markers
	for i in range(enemy_spawn_points.size()):
		var spawn_marker = Marker2D.new()
		spawn_marker.name = "EnemySpawn" + str(i)
		spawn_marker.position = enemy_spawn_points[i]
		enemy_spawns.add_child(spawn_marker)
	
	# Set boss spawn point
	boss_spawn.position = boss_spawn_point
	
	# Spawn enemies only (players already spawned by GameWorld)
	_spawn_enemies()
	
	# Level is ready
	level_ready.emit()

# Spawn all players
func _spawn_players():
	print("Spawning players...")
	
	var all_players = NetworkManager.get_all_players()
	var spawn_markers = player_spawns.get_children()
	var spawn_index = 0
	
	for player_id in all_players:
		var player_data = all_players[player_id]
		
		if player_data.get("alive", true) and spawn_index < spawn_markers.size():
			_spawn_player(player_id, player_data, spawn_markers[spawn_index])
			spawn_index += 1

# Spawn a single player
func _spawn_player(player_id: int, player_data: Dictionary, spawn_marker: Marker2D):
	print("Spawning player: ", player_data["name"])
	
	# Create player scene
	var player_scene = preload("res://scenes/characters/Player.tscn")
	var player_node = player_scene.instantiate()
	
	# Determine character type and script
	var character_type = ProgressionManager.CharacterType.WIZARD
	var character_script = null
	
	match player_data.get("character_type", ""):
		"Wizard":
			character_type = ProgressionManager.CharacterType.WIZARD
			character_script = preload("res://scripts/characters/Wizard.gd")
		"Barbarian":
			character_type = ProgressionManager.CharacterType.BARBARIAN
			character_script = preload("res://scripts/characters/Barbarian.gd")
		"Rogue":
			character_type = ProgressionManager.CharacterType.ROGUE
			character_script = preload("res://scripts/characters/Rogue.gd")
		"Knight":
			character_type = ProgressionManager.CharacterType.KNIGHT
			character_script = preload("res://scripts/characters/Knight.gd")
	
	# Set character script
	if character_script:
		player_node.set_script(character_script)
	
	# Initialize player
	player_node.initialize_player(player_id, player_data["name"], character_type, player_id == NetworkManager.local_player_id)
	player_node.global_position = spawn_marker.global_position
	
	# Connect player signals
	player_node.player_died.connect(_on_player_died)
	player_node.player_took_damage.connect(_on_player_took_damage)
	
	# Add to scene
	players_node.add_child(player_node)
	player_node.add_to_group("players")
	
	# Store reference
	spawned_players[player_id] = player_node

# Spawn enemies
func _spawn_enemies():
	print("Spawning enemies...")
	
	var spawn_markers = enemy_spawns.get_children()
	var enemies_per_level = _get_enemies_per_level()
	
	for i in range(min(spawn_markers.size(), enemies_per_level)):
		var spawn_marker = spawn_markers[i]
		_spawn_enemy_at_position(spawn_marker.global_position)

# Get number of enemies for current level
func _get_enemies_per_level() -> int:
	var base_enemies = 8
	var level_multiplier = GameManager.current_level
	var player_count = NetworkManager.get_all_players().size()
	
	return base_enemies + (level_multiplier * 2) + (player_count - 1)

# Spawn an enemy at a specific position
func _spawn_enemy_at_position(spawn_position: Vector2):
	var enemy_types = ["SkeletonGrunt", "SkeletonArcher"]
	var enemy_type = enemy_types[randi() % enemy_types.size()]
	
	var enemy_node = null
	match enemy_type:
		"SkeletonGrunt":
			var skeleton_scene = preload("res://scenes/enemies/SkeletonGrunt.tscn")
			enemy_node = skeleton_scene.instantiate()
		"SkeletonArcher":
			var skeleton_scene = preload("res://scenes/enemies/SkeletonGrunt.tscn")
			enemy_node = skeleton_scene.instantiate()
			enemy_node.set_script(preload("res://scripts/enemies/SkeletonArcher.gd"))
	
	if enemy_node:
		enemy_node.global_position = spawn_position
		enemy_node.name = enemy_type + "_" + str(randi())
		
		# Connect enemy signals
		enemy_node.enemy_died.connect(_on_enemy_died)
		enemy_node.enemy_spotted_player.connect(_on_enemy_spotted_player)
		enemy_node.enemy_lost_player.connect(_on_enemy_lost_player)
		
		# Add to scene
		enemies_node.add_child(enemy_node)
		enemy_node.add_to_group("enemies")
		
		# Track enemy
		spawned_enemies.append(enemy_node)
		total_enemies += 1
	
	# Update progress
	_update_progress()

# Spawn boss
func _spawn_boss():
	if boss_spawned:
		return
	
	print("Spawning boss...")
	
	var boss_type = current_level_info.get("boss_type", "elite_skeleton")
	var boss_instance = null
	
	match boss_type:
		"elite_skeleton":
			# Enhanced skeleton boss
			var skeleton_scene = preload("res://scenes/enemies/SkeletonGrunt.tscn")
			boss_instance = skeleton_scene.instantiate()
			# Make it elite
			boss_instance.max_health = 200
			boss_instance.health = 200
			boss_instance.attack_damage = 40
			boss_instance.scale = Vector2(1.5, 1.5)
		"witch_mini":
			# Witch mini-boss
			boss_instance = _create_witch_boss(false)
		"witch_final":
			# Final witch boss
			boss_instance = _create_witch_boss(true)
		"elite_hard":
			# Hard elite enemy
			var skeleton_scene = preload("res://scenes/enemies/SkeletonGrunt.tscn")
			boss_instance = skeleton_scene.instantiate()
			boss_instance.max_health = 300
			boss_instance.health = 300
			boss_instance.attack_damage = 50
			boss_instance.scale = Vector2(2.0, 2.0)
	
	if boss_instance:
		boss_instance.global_position = boss_spawn.global_position
		boss_instance.name = "Boss_" + boss_type
		
		# Connect boss signals
		boss_instance.enemy_died.connect(_on_boss_died)
		boss_instance.enemy_spotted_player.connect(_on_enemy_spotted_player)
		
		# Add to scene
		boss_instance.add_to_group("boss")
		boss_instance.add_to_group("enemies")
		boss_node.add_child(boss_instance)
		
		boss_spawned = true
		boss_spawned_signal.emit()
		
		# Show boss warning
		_show_boss_warning()

# Create witch boss
func _create_witch_boss(is_final: bool) -> Node2D:
	# TODO: Create proper witch boss scene
	# For now, create enhanced skeleton
	var skeleton_scene = preload("res://scenes/enemies/SkeletonGrunt.tscn")
	var witch_boss = skeleton_scene.instantiate()
	
	if is_final:
		witch_boss.max_health = 500
		witch_boss.health = 500
		witch_boss.attack_damage = 60
		witch_boss.scale = Vector2(2.5, 2.5)
	else:
		witch_boss.max_health = 250
		witch_boss.health = 250
		witch_boss.attack_damage = 45
		witch_boss.scale = Vector2(1.8, 1.8)
	
	return witch_boss

# Show boss warning
func _show_boss_warning():
	boss_warning.visible = true
	
	# Hide after 3 seconds
	await get_tree().create_timer(3.0).timeout
	boss_warning.visible = false

# Add decorative elements
func _add_decorative_elements():
	print("Adding decorative elements...")
	
	# Add torches, candles, and other props based on level type
	var rooms = level_generator.rooms
	
	for room in rooms:
		if not room.is_spawn_room and not room.is_boss_room:
			_add_room_decorations(room)

# Add decorations to a room
func _add_room_decorations(room):
	var decoration_count = randi_range(1, 3)
	
	for i in range(decoration_count):
		var decoration = _create_random_decoration()
		if decoration:
			# Place at random position in room
			var pos_x = room.x + randi_range(2, room.width - 2)
			var pos_y = room.y + randi_range(2, room.height - 2)
			decoration.global_position = Vector2(pos_x * 16, pos_y * 16)
			decorations_node.add_child(decoration)

# Create random decoration
func _create_random_decoration() -> Node2D:
	var decoration_types = ["torch", "candle", "skull", "bones"]
	var decoration_type = decoration_types[randi() % decoration_types.size()]
	
	var decoration = Sprite2D.new()
	
	match decoration_type:
		"torch":
			decoration.texture = load("res://assets/torch_1.png")
		"candle":
			decoration.texture = load("res://assets/candleA_01.png")
		"skull":
			decoration.texture = load("res://assets/decorative.png")
		"bones":
			decoration.texture = load("res://assets/decorative.png")
	
	return decoration

# Add lighting elements
func _add_lighting_elements():
	print("Adding lighting elements...")
	
	# Add ambient lighting based on level type
	var light_color = Color.WHITE
	match level_type:
		0:  # CAVE
			light_color = Color(0.8, 0.7, 0.6)  # Warm cave light
		1:  # CATACOMB
			light_color = Color(0.6, 0.6, 0.8)  # Cool stone light
		2:  # CRYPT
			light_color = Color(0.5, 0.5, 0.7)  # Dark crypt light
		3:  # CASTLE
			light_color = Color(0.9, 0.8, 0.7)  # Warm castle light
	
	# Create ambient light
	var ambient_light = PointLight2D.new()
	ambient_light.color = light_color
	ambient_light.energy = 0.5
	ambient_light.texture_scale = 10.0
	lighting_node.add_child(ambient_light)

# Update progress bar
func _update_progress():
	if total_enemies > 0:
		var progress = float(enemies_killed) / float(total_enemies) * 100.0
		if progress_bar:
			progress_bar.value = progress
		else:
			print("Warning: progress_bar UI node not found")
		
		# Check if all enemies are defeated
		if enemies_killed >= total_enemies and not boss_spawned:
			_trigger_boss_encounter()

# Trigger boss encounter
func _trigger_boss_encounter():
	print("All enemies defeated - triggering boss encounter")
	if objective_label:
		objective_label.text = "Objective: Defeat the boss!"
	else:
		print("Warning: objective_label UI node not found")
	_spawn_boss()

# Signal handlers
func _on_level_changed(_new_level: int, level_info: Dictionary):
	if is_inside_tree():
		initialize_level(level_info)

func _on_player_connected(player_id: int):
	print("Player connected: ", player_id)
	# Respawn players if level is active
	if is_inside_tree():
		_spawn_players()

func _on_player_disconnected(player_id: int):
	print("Player disconnected: ", player_id)
	if player_id in spawned_players:
		spawned_players[player_id].queue_free()
		spawned_players.erase(player_id)

func _on_player_died(player_id: int):
	print("Player died: ", player_id)
	GameManager.handle_player_death(player_id)

func _on_player_took_damage(player_id: int, damage: int):
	print("Player took damage: ", player_id, " - ", damage)

func _on_enemy_died(enemy_node: Node2D):
	print("Enemy died: ", enemy_node.name)
	
	if enemy_node in spawned_enemies:
		spawned_enemies.erase(enemy_node)
		enemies_killed += 1
		_update_progress()
		
		# Update game stats
		GameManager.run_stats["enemies_killed"] += 1
		
		# Check if all enemies are defeated
		if enemies_killed >= total_enemies and not boss_spawned:
			all_enemies_defeated.emit()

func _on_boss_died(defeated_boss: Node2D):
	print("Boss defeated!")
	
	# Complete level
	level_complete = true
	level_completed.emit()
	
	# Notify game manager
	var boss_type = current_level_info.get("boss_type", "elite_skeleton")
	GameManager.defeat_boss(boss_type)

func _on_boss_defeated(boss_type: String):
	print("Boss defeated signal received: ", boss_type)

func _on_enemy_spotted_player(enemy_node: Node2D, player_node: Node2D):
	print("Enemy spotted player: ", enemy_node.name, " -> ", player_node.name)

func _on_enemy_lost_player(enemy_node: Node2D, player_node: Node2D):
	print("Enemy lost player: ", enemy_node.name, " -> ", player_node.name)

# Get projectiles container
func get_projectiles_container() -> Node2D:
	return projectiles_node

# Get effects container
func get_effects_container() -> Node2D:
	return effects_node

# Get pickups container
func get_pickups_container() -> Node2D:
	return pickups_node

# Check if level is complete
func is_level_complete() -> bool:
	return level_complete

# Get current level type
func get_level_type() -> int:
	return level_type 

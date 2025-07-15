extends Player
class_name Wizard

# Wizard-specific variables
var fireball_damage: int = 35
var magic_missile_damage: int = 25
var meteor_storm_damage: int = 80

# Projectile scenes (to be loaded)
var fireball_scene: PackedScene
var magic_missile_scene: PackedScene
var meteor_scene: PackedScene

func _ready():
	# Set character type
	character_type = ProgressionManager.CharacterType.WIZARD
	
	# Load projectile scenes
	fireball_scene = preload("res://scenes/projectiles/Fireball.tscn")
	magic_missile_scene = preload("res://scenes/projectiles/MagicMissile.tscn")
	meteor_scene = preload("res://scenes/projectiles/Meteor.tscn")
	
	# Call parent ready
	super._ready()
	
	print("Wizard initialized with character type: ", character_type)

# Override ability functions with wizard-specific implementations
func use_ability_1():
	if current_state == PlayerState.DEAD or not ability1_ready or current_mana < 20:
		return
	
	print("Wizard casting Fireball!")
	
	# Set state
	current_state = PlayerState.ATTACKING
	ability1_ready = false
	ability1_timer.start()
	
	# Consume mana
	current_mana -= 20
	
	# Cast fireball
	cast_fireball()
	
	# Network sync
	if is_local_player:
		ability_used.emit(player_id, "fireball")
	
	# Return to idle after cast delay
	await get_tree().create_timer(0.5).timeout
	if current_state == PlayerState.ATTACKING:
		current_state = PlayerState.IDLE

func use_ability_2():
	if current_state == PlayerState.DEAD or not ability2_ready or current_mana < 15:
		return
	
	print("Wizard casting Magic Missile!")
	
	# Set state
	current_state = PlayerState.ATTACKING
	ability2_ready = false
	ability2_timer.start()
	
	# Consume mana
	current_mana -= 15
	
	# Cast magic missile
	cast_magic_missile()
	
	# Network sync
	if is_local_player:
		ability_used.emit(player_id, "magic_missile")
	
	# Return to idle after cast delay
	await get_tree().create_timer(0.3).timeout
	if current_state == PlayerState.ATTACKING:
		current_state = PlayerState.IDLE

func use_ability_3():
	if current_state == PlayerState.DEAD or not ability3_ready or current_mana < 60:
		return
	
	# Check if third ability is unlocked
	var char_data = ProgressionManager.get_character_data(character_type)
	if not char_data.get("third_ability_unlocked", false):
		print("Meteor Storm not unlocked yet!")
		return
	
	print("Wizard casting Meteor Storm!")
	
	# Set state
	current_state = PlayerState.ATTACKING
	ability3_ready = false
	ability3_timer.start()
	
	# Consume mana
	current_mana -= 60
	
	# Cast meteor storm
	cast_meteor_storm()
	
	# Network sync
	if is_local_player:
		ability_used.emit(player_id, "meteor_storm")
	
	# Return to idle after cast delay
	await get_tree().create_timer(1.0).timeout
	if current_state == PlayerState.ATTACKING:
		current_state = PlayerState.IDLE

func cast_fireball():
	# Get target direction
	var target_direction = Vector2.ZERO
	if targets_in_range.size() > 0:
		# Target nearest enemy
		var nearest_enemy = targets_in_range[0]
		target_direction = (nearest_enemy.global_position - global_position).normalized()
	else:
		# Default to mouse position or forward
		target_direction = (get_global_mouse_position() - global_position).normalized()
	
	# Create fireball projectile
	var fireball = create_projectile(fireball_scene, target_direction, 200.0)
	fireball.damage = fireball_damage
	fireball.explosion_radius = 50.0
	
	# Play cast audio
	if attack_audio:
		attack_audio.play()
	
	# Visual effect
	create_cast_effect(Color.RED)

func cast_magic_missile():
	# Get target direction
	var target_direction = Vector2.ZERO
	if targets_in_range.size() > 0:
		# Target nearest enemy
		var nearest_enemy = targets_in_range[0]
		target_direction = (nearest_enemy.global_position - global_position).normalized()
	else:
		# Default to mouse position or forward
		target_direction = (get_global_mouse_position() - global_position).normalized()
	
	# Create magic missile projectile
	var missile = create_projectile(magic_missile_scene, target_direction, 300.0)
	missile.damage = magic_missile_damage
	missile.piercing = true  # Magic missiles can pierce enemies
	
	# Play cast audio
	if attack_audio:
		attack_audio.play()
	
	# Visual effect
	create_cast_effect(Color.BLUE)

func cast_meteor_storm():
	print("Casting Meteor Storm - Area of Effect!")
	
	# Create multiple meteors in an area
	var meteor_count = 8
	var spread_radius = 150.0
	var center_position = global_position
	
	# If there are enemies in range, target them
	if targets_in_range.size() > 0:
		center_position = targets_in_range[0].global_position
	else:
		center_position = get_global_mouse_position()
	
	# Create meteors with delay
	for i in range(meteor_count):
		await get_tree().create_timer(0.1 * i).timeout
		
		# Random position within spread radius
		var offset = Vector2(
			randf_range(-spread_radius, spread_radius),
			randf_range(-spread_radius, spread_radius)
		)
		
		var meteor_position = center_position + offset
		var direction = (meteor_position - global_position).normalized()
		
		# Create meteor
		var meteor = create_projectile(meteor_scene, direction, 150.0)
		meteor.damage = meteor_storm_damage
		meteor.target_position = meteor_position
	
	# Play cast audio
	if attack_audio:
		attack_audio.play()
	
	# Visual effect
	create_cast_effect(Color.ORANGE)

func create_projectile(projectile_scene: PackedScene, direction: Vector2, speed: float) -> Node:
	if not projectile_scene:
		# Create a simple projectile if scene not available
		var projectile = ColorRect.new()
		projectile.size = Vector2(8, 8)
		projectile.color = Color.YELLOW
		projectile.global_position = global_position
		
		# Add simple movement
		var tween = create_tween()
		tween.tween_property(projectile, "global_position", global_position + direction * 300, 1.0)
		tween.tween_callback(projectile.queue_free)
		
		get_parent().add_child(projectile)
		return projectile
	else:
		# Create actual projectile
		var projectile = projectile_scene.instantiate()
		projectile.global_position = global_position
		projectile.direction = direction
		projectile.speed = speed
		projectile.owner_id = player_id
		
		# Add to projectiles node
		var projectiles_node = get_tree().get_first_node_in_group("projectiles")
		if projectiles_node:
			projectiles_node.add_child(projectile)
		else:
			get_parent().add_child(projectile)
		
		return projectile

func create_cast_effect(color: Color):
	# Create a simple casting effect
	var effect = ColorRect.new()
	effect.size = Vector2(32, 32)
	effect.color = color
	effect.position = sprite.position - Vector2(16, 16)
	add_child(effect)
	
	# Animate the effect
	var tween = create_tween()
	tween.tween_property(effect, "scale", Vector2(2, 2), 0.2)
	tween.tween_property(effect, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(effect.queue_free)

# Mana management
func regenerate_mana(delta: float):
	var mana_regen_rate = 10.0  # Mana per second
	current_mana = min(mana, current_mana + mana_regen_rate * delta)

func _process(delta):
	regenerate_mana(delta)

# Network sync for wizard-specific abilities
@rpc("any_peer", "call_local", "reliable")
func sync_wizard_ability(ability_name: String, target_pos: Vector2):
	if not is_local_player:
		match ability_name:
			"fireball":
				var direction = (target_pos - global_position).normalized()
				cast_fireball()
			"magic_missile":
				var direction = (target_pos - global_position).normalized()
				cast_magic_missile()
			"meteor_storm":
				cast_meteor_storm()

# Override character-specific stats loading
func load_character_stats():
	super.load_character_stats()
	
	# Apply wizard-specific upgrades
	var char_data = ProgressionManager.get_character_data(character_type)
	var upgrades = char_data.get("upgrades", {})
	
	# Apply fire mastery upgrade
	if "fire_mastery" in upgrades:
		var fire_level = upgrades["fire_mastery"]
		fireball_damage = 35 + (fire_level * 10)
		meteor_storm_damage = 80 + (fire_level * 20)
	
	# Apply magic missile upgrade
	if "magic_missile_upgrade" in upgrades:
		magic_missile_damage = 25 + 15  # Upgraded version
	
	print("Wizard stats loaded - Fireball: ", fireball_damage, " Magic Missile: ", magic_missile_damage, " Meteor: ", meteor_storm_damage)

# Get ability descriptions for UI
func get_ability_description(ability_index: int) -> String:
	match ability_index:
		1:
			return "Fireball: Launches an explosive fireball that deals " + str(fireball_damage) + " damage. Cost: 20 mana."
		2:
			return "Magic Missile: Fires a piercing magical projectile that deals " + str(magic_missile_damage) + " damage. Cost: 15 mana."
		3:
			return "Meteor Storm: Calls down multiple meteors in an area, each dealing " + str(meteor_storm_damage) + " damage. Cost: 60 mana."
		_:
			return "Unknown ability"

# Check if ability can be used (mana cost)
func can_use_ability(ability_index: int) -> bool:
	if not super.is_ability_ready(ability_index):
		return false
	
	match ability_index:
		1:
			return current_mana >= 20
		2:
			return current_mana >= 15
		3:
			return current_mana >= 60
		_:
			return false 

extends Player
class_name Rogue

# Rogue-specific variables
var stealth_duration: float = 3.0
var poison_damage: int = 15
var poison_duration: float = 5.0
var shadow_clone_duration: float = 8.0
var is_in_stealth: bool = false
var stealth_timer: Timer

# Stealth and speed bonuses
var stealth_speed_bonus: float = 1.5
var stealth_damage_bonus: int = 20

func _ready():
	# Set character type
	character_type = ProgressionManager.CharacterType.ROGUE
	
	# Create stealth timer
	stealth_timer = Timer.new()
	stealth_timer.wait_time = stealth_duration
	stealth_timer.one_shot = true
	stealth_timer.timeout.connect(_on_stealth_timeout)
	add_child(stealth_timer)
	
	# Call parent ready
	super._ready()
	
	print("Rogue initialized with character type: ", character_type)

# Override ability functions with rogue-specific implementations
func use_ability_1():
	if current_state == PlayerState.DEAD or not ability1_ready:
		return
	
	print("Rogue activating Stealth!")
	
	# Set state
	ability1_ready = false
	ability1_timer.start()
	
	# Activate stealth
	activate_stealth()
	
	# Network sync
	if is_local_player:
		ability_used.emit(player_id, "stealth")

func use_ability_2():
	if current_state == PlayerState.DEAD or not ability2_ready:
		return
	
	print("Rogue using Poison Strike!")
	
	# Set state
	current_state = PlayerState.ATTACKING
	ability2_ready = false
	ability2_timer.start()
	
	# Perform poison strike
	perform_poison_strike()
	
	# Network sync
	if is_local_player:
		ability_used.emit(player_id, "poison_strike")
	
	# Return to idle after attack delay
	await get_tree().create_timer(0.4).timeout
	if current_state == PlayerState.ATTACKING:
		current_state = PlayerState.IDLE

func use_ability_3():
	if current_state == PlayerState.DEAD or not ability3_ready:
		return
	
	# Check if third ability is unlocked
	var char_data = ProgressionManager.get_character_data(character_type)
	if not char_data.get("third_ability_unlocked", false):
		print("Shadow Clone not unlocked yet!")
		return
	
	print("Rogue creating Shadow Clone!")
	
	# Set state
	ability3_ready = false
	ability3_timer.start()
	
	# Create shadow clone
	create_shadow_clone()
	
	# Network sync
	if is_local_player:
		ability_used.emit(player_id, "shadow_clone")

func activate_stealth():
	if is_in_stealth:
		print("Already in stealth!")
		return
	
	is_in_stealth = true
	stealth_timer.start()
	
	# Visual effects - make player semi-transparent
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.3)
	
	# Speed boost
	move_speed = int(move_speed * stealth_speed_bonus)
	
	# Reduce collision detection (harder to hit)
	collision_layer = 0  # Temporarily disable collision
	
	print("Stealth activated! Speed increased and visibility reduced.")
	
	# Create stealth effect
	create_stealth_effect()

func perform_poison_strike():
	# Find nearest enemy
	var target_enemy = null
	var min_distance = 50.0  # Melee range
	
	for target in targets_in_range:
		if target.has_method("take_damage"):
			var distance = global_position.distance_to(target.global_position)
			if distance <= min_distance:
				if target_enemy == null or distance < global_position.distance_to(target_enemy.global_position):
					target_enemy = target
	
	if target_enemy:
		# Initial strike damage
		var strike_damage = attack_power
		if is_in_stealth:
			strike_damage += stealth_damage_bonus
			exit_stealth()  # Break stealth on attack
		
		target_enemy.take_damage(strike_damage, player_id)
		
		# Apply poison effect
		apply_poison_to_enemy(target_enemy)
		
		print("Poison Strike hit ", target_enemy.name, " for ", strike_damage, " damage + poison!")
		
		# Visual effect
		create_poison_effect(target_enemy.global_position)
		
		# Play attack audio
		if attack_audio:
			attack_audio.play()
	else:
		print("No enemy in range for Poison Strike!")

func apply_poison_to_enemy(enemy):
	# Apply poison damage over time
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("poison", poison_damage, poison_duration)
	else:
		# Fallback: apply poison directly
		apply_poison_damage(enemy)

func apply_poison_damage(enemy):
	# Create poison damage over time
	var poison_ticks = int(poison_duration)
	for i in range(poison_ticks):
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(poison_damage, player_id)
			create_poison_tick_effect(enemy.global_position)

func create_shadow_clone():
	print("Creating Shadow Clone!")
	
	# Create a duplicate of the player
	var clone = duplicate()
	clone.name = "ShadowClone_" + str(player_id)
	clone.is_local_player = false
	clone.player_name = player_name + " (Clone)"
	
	# Position clone slightly offset
	clone.global_position = global_position + Vector2(32, 0)
	
	# Visual differences for clone
	clone.sprite.modulate = Color(0.5, 0.5, 0.8, 0.7)  # Blue tint, semi-transparent
	clone.health_bar.visible = false
	
	# Clone AI behavior
	setup_clone_ai(clone)
	
	# Add clone to game world
	get_parent().add_child(clone)
	
	# Auto-destroy after duration
	var clone_timer = Timer.new()
	clone_timer.wait_time = shadow_clone_duration
	clone_timer.one_shot = true
	clone_timer.timeout.connect(clone.queue_free)
	clone.add_child(clone_timer)
	clone_timer.start()
	
	# Visual spawn effect
	create_shadow_spawn_effect(clone.global_position)

func setup_clone_ai(clone):
	# Simple AI: attack nearest enemy
	var ai_timer = Timer.new()
	ai_timer.wait_time = 0.5
	ai_timer.timeout.connect(func(): clone_ai_update(clone))
	clone.add_child(ai_timer)
	ai_timer.start()

func clone_ai_update(clone):
	if not is_instance_valid(clone):
		return
	
	# Find nearest enemy
	var nearest_enemy = null
	var min_distance = 200.0
	
	var enemies_node = get_tree().get_first_node_in_group("enemies")
	if enemies_node:
		for enemy in enemies_node.get_children():
			if enemy.has_method("take_damage"):
				var distance = clone.global_position.distance_to(enemy.global_position)
				if distance < min_distance:
					nearest_enemy = enemy
					min_distance = distance
	
	if nearest_enemy:
		# Move towards enemy
		var direction = (nearest_enemy.global_position - clone.global_position).normalized()
		clone.velocity = direction * (clone.move_speed * 0.8)
		clone.move_and_slide()
		
		# Attack if close enough
		if min_distance < 40.0:
			clone_attack(clone, nearest_enemy)

func clone_attack(clone, enemy):
	# Clone performs basic attack
	var damage = attack_power * 0.6  # Clone does less damage
	enemy.take_damage(damage, player_id)
	
	# Visual effect
	create_clone_attack_effect(clone.global_position)
	
	print("Shadow Clone attacked ", enemy.name, " for ", damage, " damage!")

func exit_stealth():
	if is_in_stealth:
		is_in_stealth = false
		stealth_timer.stop()
		
		# Reset visual effects
		sprite.modulate = Color.WHITE
		
		# Reset speed and collision
		load_character_stats()  # Reload original stats
		collision_layer = 1  # Re-enable collision
		
		print("Stealth ended!")

func _on_stealth_timeout():
	exit_stealth()

func create_stealth_effect():
	# Create swirling shadow effect
	var shadows = []
	for i in range(6):
		var shadow = ColorRect.new()
		shadow.size = Vector2(8, 8)
		shadow.color = Color(0.2, 0.2, 0.2, 0.6)
		
		var angle = (2.0 * PI * i) / 6.0
		shadow.position = sprite.position + Vector2(cos(angle), sin(angle)) * 20
		
		add_child(shadow)
		shadows.append(shadow)
		
		# Animate shadows
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(shadow, "position", sprite.position + Vector2(cos(angle + PI), sin(angle + PI)) * 20, 1.0)
		tween.tween_property(shadow, "position", sprite.position + Vector2(cos(angle), sin(angle)) * 20, 1.0)
	
	# Clean up shadows when stealth ends
	stealth_timer.timeout.connect(func(): cleanup_shadows(shadows))

func cleanup_shadows(shadows):
	for shadow in shadows:
		if is_instance_valid(shadow):
			shadow.queue_free()

func create_poison_effect(position: Vector2):
	# Create green poison cloud
	var poison_cloud = ColorRect.new()
	poison_cloud.size = Vector2(24, 24)
	poison_cloud.color = Color(0.2, 0.8, 0.2, 0.6)  # Green poison
	poison_cloud.global_position = position - Vector2(12, 12)
	
	get_parent().add_child(poison_cloud)
	
	# Animate poison cloud
	var tween = create_tween()
	tween.tween_property(poison_cloud, "scale", Vector2(1.5, 1.5), 0.5)
	tween.tween_property(poison_cloud, "modulate", Color.TRANSPARENT, 0.5)
	tween.tween_callback(poison_cloud.queue_free)

func create_poison_tick_effect(position: Vector2):
	# Small poison damage indicator
	var tick = ColorRect.new()
	tick.size = Vector2(8, 8)
	tick.color = Color.GREEN
	tick.global_position = position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	
	get_parent().add_child(tick)
	
	# Animate tick
	var tween = create_tween()
	tween.tween_property(tick, "position", tick.position + Vector2(0, -20), 0.5)
	tween.tween_property(tick, "modulate", Color.TRANSPARENT, 0.5)
	tween.tween_callback(tick.queue_free)

func create_shadow_spawn_effect(position: Vector2):
	# Create shadow spawn effect
	var spawn_effect = ColorRect.new()
	spawn_effect.size = Vector2(32, 32)
	spawn_effect.color = Color(0.2, 0.2, 0.8, 0.8)  # Dark blue
	spawn_effect.global_position = position - Vector2(16, 16)
	
	get_parent().add_child(spawn_effect)
	
	# Animate spawn
	var tween = create_tween()
	tween.tween_property(spawn_effect, "scale", Vector2(0.1, 0.1), 0.0)
	tween.tween_property(spawn_effect, "scale", Vector2(2.0, 2.0), 0.3)
	tween.tween_property(spawn_effect, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(spawn_effect.queue_free)

func create_clone_attack_effect(position: Vector2):
	# Create shadow attack effect
	var attack_effect = ColorRect.new()
	attack_effect.size = Vector2(16, 16)
	attack_effect.color = Color(0.4, 0.4, 0.8, 0.8)  # Blue attack
	attack_effect.global_position = position - Vector2(8, 8)
	
	get_parent().add_child(attack_effect)
	
	# Animate attack
	var tween = create_tween()
	tween.tween_property(attack_effect, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(attack_effect, "modulate", Color.TRANSPARENT, 0.2)
	tween.tween_callback(attack_effect.queue_free)

# Override character-specific stats loading
func load_character_stats():
	super.load_character_stats()
	
	# Apply rogue-specific upgrades
	var char_data = ProgressionManager.get_character_data(character_type)
	var upgrades = char_data.get("upgrades", {})
	
	# Apply poison mastery upgrade
	if "poison_mastery" in upgrades:
		var poison_level = upgrades["poison_mastery"]
		poison_damage = 15 + (poison_level * 5)
		poison_duration = 5.0 + (poison_level * 1.0)
	
	# Apply stealth duration upgrade
	if "stealth_duration" in upgrades:
		var stealth_level = upgrades["stealth_duration"]
		stealth_duration = 3.0 + (stealth_level * 1.0)
		stealth_timer.wait_time = stealth_duration
	
	# Apply critical strikes upgrade
	if "critical_strikes" in upgrades:
		# This would affect critical hit chance in combat
		pass
	
	print("Rogue stats loaded - Poison: ", poison_damage, " Stealth Duration: ", stealth_duration)

# Get ability descriptions for UI
func get_ability_description(ability_index: int) -> String:
	match ability_index:
		1:
			return "Stealth: Become invisible for " + str(stealth_duration) + " seconds, gaining speed and attack bonuses."
		2:
			return "Poison Strike: Melee attack that deals " + str(attack_power) + " damage + " + str(poison_damage) + " poison per second."
		3:
			return "Shadow Clone: Create a clone that fights alongside you for " + str(shadow_clone_duration) + " seconds."
		_:
			return "Unknown ability"

# Override dash for rogue (enhanced stealth dash)
func dash():
	if current_state == PlayerState.DEAD or not dash_ready:
		return
	
	var dash_direction = input_vector
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2(0, -1)
	
	# Enhanced dash for rogue
	current_state = PlayerState.DASHING
	is_dashing = true
	dash_velocity = dash_direction * dash_speed
	dash_ready = false
	dash_timer.start()
	
	# Brief stealth during dash
	var original_modulate = sprite.modulate
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.3)
	
	# Restore visibility after dash
	await get_tree().create_timer(dash_duration).timeout
	if not is_in_stealth:
		sprite.modulate = original_modulate
	
	# Become invincible during dash
	is_invincible = true
	
	# Visual effect
	create_dash_shadow_effect()
	
	print("Rogue shadow dashed!")

func create_dash_shadow_effect():
	# Create shadow trail effect
	var shadow_trail = ColorRect.new()
	shadow_trail.size = Vector2(32, 32)
	shadow_trail.color = Color(0.2, 0.2, 0.2, 0.4)  # Dark shadow
	shadow_trail.global_position = global_position - Vector2(16, 16)
	
	get_parent().add_child(shadow_trail)
	
	# Animate trail
	var tween = create_tween()
	tween.tween_property(shadow_trail, "scale", Vector2(0.5, 0.5), 0.5)
	tween.tween_property(shadow_trail, "modulate", Color.TRANSPARENT, 0.5)
	tween.tween_callback(shadow_trail.queue_free)

# Check if ability can be used
func can_use_ability(ability_index: int) -> bool:
	if not super.is_ability_ready(ability_index):
		return false
	
	# Special case: can't use stealth if already in stealth
	if ability_index == 1 and is_in_stealth:
		return false
	
	return true

# Override process to handle stealth effects
func _process(delta):
	# Update stealth visual effects
	if is_in_stealth:
		# Subtle pulsing effect during stealth
		var pulse_alpha = 0.3 + 0.1 * sin(Time.get_ticks_msec() * 0.005)
		sprite.modulate.a = pulse_alpha

# Break stealth on taking damage
func take_damage(damage: int, attacker_id: int = -1):
	if is_in_stealth:
		exit_stealth()
	super.take_damage(damage, attacker_id)

# Network sync for rogue-specific abilities
@rpc("any_peer", "call_local", "reliable")
func sync_rogue_ability(ability_name: String):
	if not is_local_player:
		match ability_name:
			"stealth":
				activate_stealth()
			"poison_strike":
				perform_poison_strike()
			"shadow_clone":
				create_shadow_clone() 
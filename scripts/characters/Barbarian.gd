extends Player
class_name Barbarian

# Barbarian-specific variables
var heavy_strike_damage: int = 60
var berserker_rage_damage_bonus: int = 25
var earthquake_damage: int = 100
var rage_duration: float = 5.0
var is_in_rage: bool = false
var rage_timer: Timer

# Attack range for melee
var melee_range: float = 40.0

func _ready():
	# Set character type
	character_type = ProgressionManager.CharacterType.BARBARIAN
	
	# Create rage timer
	rage_timer = Timer.new()
	rage_timer.wait_time = rage_duration
	rage_timer.one_shot = true
	rage_timer.timeout.connect(_on_rage_timeout)
	add_child(rage_timer)
	
	# Call parent ready
	super._ready()
	
	print("Barbarian initialized with character type: ", character_type)

# Override ability functions with barbarian-specific implementations
func use_ability_1():
	if current_state == PlayerState.DEAD or not ability1_ready:
		return
	
	print("Barbarian using Heavy Strike!")
	
	# Set state
	current_state = PlayerState.ATTACKING
	ability1_ready = false
	ability1_timer.start()
	
	# Perform heavy strike
	perform_heavy_strike()
	
	# Network sync
	if is_local_player:
		ability_used.emit(player_id, "heavy_strike")
	
	# Return to idle after attack delay
	await get_tree().create_timer(0.6).timeout
	if current_state == PlayerState.ATTACKING:
		current_state = PlayerState.IDLE

func use_ability_2():
	if current_state == PlayerState.DEAD or not ability2_ready:
		return
	
	print("Barbarian activating Berserker Rage!")
	
	# Set state
	ability2_ready = false
	ability2_timer.start()
	
	# Activate berserker rage
	activate_berserker_rage()
	
	# Network sync
	if is_local_player:
		ability_used.emit(player_id, "berserker_rage")

func use_ability_3():
	if current_state == PlayerState.DEAD or not ability3_ready:
		return
	
	# Check if third ability is unlocked
	var char_data = ProgressionManager.get_character_data(character_type)
	if not char_data.get("third_ability_unlocked", false):
		print("Earthquake not unlocked yet!")
		return
	
	print("Barbarian using Earthquake!")
	
	# Set state
	current_state = PlayerState.ATTACKING
	ability3_ready = false
	ability3_timer.start()
	
	# Perform earthquake
	perform_earthquake()
	
	# Network sync
	if is_local_player:
		ability_used.emit(player_id, "earthquake")
	
	# Return to idle after attack delay
	await get_tree().create_timer(1.2).timeout
	if current_state == PlayerState.ATTACKING:
		current_state = PlayerState.IDLE

func perform_heavy_strike():
	# Get current damage (with rage bonus if active)
	var damage = heavy_strike_damage
	if is_in_rage:
		damage += berserker_rage_damage_bonus
	
	# Find enemies in melee range
	var enemies_hit = []
	for target in targets_in_range:
		if target.has_method("take_damage"):
			var distance = global_position.distance_to(target.global_position)
			if distance <= melee_range:
				enemies_hit.append(target)
	
	# Deal damage to enemies
	for enemy in enemies_hit:
		enemy.take_damage(damage, player_id)
		print("Heavy Strike hit ", enemy.name, " for ", damage, " damage!")
	
	# Visual effect
	create_strike_effect()
	
	# Play attack audio
	if attack_audio:
		attack_audio.play()
	
	# Screen shake for heavy impact
	create_screen_shake(0.3, 10.0)

func activate_berserker_rage():
	if is_in_rage:
		print("Already in rage!")
		return
	
	is_in_rage = true
	rage_timer.start()
	
	# Visual effects
	sprite.modulate = Color(1.2, 0.8, 0.8)  # Reddish tint
	
	# Speed boost
	move_speed = int(move_speed * 1.3)
	
	# Damage boost (applied in attacks)
	print("Berserker Rage activated! Damage increased by ", berserker_rage_damage_bonus)
	
	# Create rage aura effect
	create_rage_aura()

func perform_earthquake():
	print("Earthquake - Area of Effect Attack!")
	
	# Get current damage (with rage bonus if active)
	var damage = earthquake_damage
	if is_in_rage:
		damage += berserker_rage_damage_bonus
	
	# Large area attack
	var earthquake_radius = 120.0
	var enemies_hit = []
	
	# Find all enemies within radius
	var enemies_node = get_tree().get_first_node_in_group("enemies")
	if enemies_node:
		for enemy in enemies_node.get_children():
			if enemy.has_method("take_damage"):
				var distance = global_position.distance_to(enemy.global_position)
				if distance <= earthquake_radius:
					enemies_hit.append(enemy)
	
	# Deal damage to all enemies in range
	for enemy in enemies_hit:
		enemy.take_damage(damage, player_id)
		# Stun enemies briefly
		if enemy.has_method("stun"):
			enemy.stun(1.0)
		print("Earthquake hit ", enemy.name, " for ", damage, " damage!")
	
	# Visual effects
	create_earthquake_effect()
	
	# Play attack audio
	if attack_audio:
		attack_audio.play()
	
	# Strong screen shake
	create_screen_shake(1.0, 20.0)

func create_strike_effect():
	# Create weapon slash effect
	var effect = ColorRect.new()
	effect.size = Vector2(64, 16)
	effect.color = Color(1.0, 0.8, 0.2, 0.8)  # Golden slash
	effect.position = sprite.position + Vector2(-32, -8)
	add_child(effect)
	
	# Animate the slash
	var tween = create_tween()
	tween.tween_property(effect, "scale", Vector2(1.5, 3.0), 0.2)
	tween.tween_property(effect, "modulate", Color.TRANSPARENT, 0.2)
	tween.tween_callback(effect.queue_free)

func create_rage_aura():
	# Create pulsing red aura
	var aura = ColorRect.new()
	aura.size = Vector2(48, 48)
	aura.color = Color(1.0, 0.0, 0.0, 0.3)
	aura.position = sprite.position - Vector2(24, 24)
	add_child(aura)
	
	# Pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(aura, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(aura, "scale", Vector2(1.0, 1.0), 0.5)
	
	# Remove aura when rage ends
	rage_timer.timeout.connect(aura.queue_free)

func create_earthquake_effect():
	# Create ground crack effects
	var crack_count = 8
	for i in range(crack_count):
		var crack = ColorRect.new()
		crack.size = Vector2(randf_range(20, 40), randf_range(4, 8))
		crack.color = Color(0.4, 0.2, 0.0)  # Brown cracks
		
		# Random position around player
		var angle = (2.0 * PI * i) / crack_count
		var distance = randf_range(30, 100)
		crack.position = sprite.position + Vector2(cos(angle), sin(angle)) * distance
		
		get_parent().add_child(crack)
		
		# Animate cracks
		var tween = create_tween()
		tween.tween_property(crack, "scale", Vector2(1.0, 0.1), 0.1)
		tween.tween_property(crack, "scale", Vector2(1.0, 1.0), 0.2)
		tween.tween_delay(1.0)
		tween.tween_property(crack, "modulate", Color.TRANSPARENT, 0.5)
		tween.tween_callback(crack.queue_free)

func create_screen_shake(duration: float, intensity: float):
	# Simple screen shake effect
	var camera = get_viewport().get_camera_2d()
	if camera:
		var original_pos = camera.global_position
		var shake_tween = create_tween()
		
		for i in range(int(duration * 20)):  # 20 shakes per second
			var shake_offset = Vector2(
				randf_range(-intensity, intensity),
				randf_range(-intensity, intensity)
			)
			shake_tween.tween_property(camera, "global_position", original_pos + shake_offset, 0.05)
		
		shake_tween.tween_property(camera, "global_position", original_pos, 0.1)

func _on_rage_timeout():
	if is_in_rage:
		is_in_rage = false
		
		# Reset visual effects
		sprite.modulate = Color.WHITE
		
		# Reset speed
		load_character_stats()  # Reload original stats
		
		print("Berserker Rage ended!")

# Network sync for barbarian-specific abilities
@rpc("any_peer", "call_local", "reliable")
func sync_barbarian_ability(ability_name: String):
	if not is_local_player:
		match ability_name:
			"heavy_strike":
				perform_heavy_strike()
			"berserker_rage":
				activate_berserker_rage()
			"earthquake":
				perform_earthquake()

# Override character-specific stats loading
func load_character_stats():
	super.load_character_stats()
	
	# Apply barbarian-specific upgrades
	var char_data = ProgressionManager.get_character_data(character_type)
	var upgrades = char_data.get("upgrades", {})
	
	# Apply strength training upgrade
	if "strength_training" in upgrades:
		var strength_level = upgrades["strength_training"]
		heavy_strike_damage = 60 + (strength_level * 15)
		earthquake_damage = 100 + (strength_level * 20)
	
	# Apply rage duration upgrade
	if "rage_duration" in upgrades:
		var rage_level = upgrades["rage_duration"]
		rage_duration = 5.0 + (rage_level * 2.0)
		rage_timer.wait_time = rage_duration
	
	# Apply intimidation upgrade
	if "intimidation" in upgrades:
		# Enemies move slower near this player
		pass  # This would be implemented in enemy AI
	
	print("Barbarian stats loaded - Heavy Strike: ", heavy_strike_damage, " Earthquake: ", earthquake_damage, " Rage Duration: ", rage_duration)

# Get ability descriptions for UI
func get_ability_description(ability_index: int) -> String:
	match ability_index:
		1:
			return "Heavy Strike: Powerful melee attack that deals " + str(heavy_strike_damage) + " damage to nearby enemies."
		2:
			return "Berserker Rage: Increases damage by " + str(berserker_rage_damage_bonus) + " and speed by 30% for " + str(rage_duration) + " seconds."
		3:
			return "Earthquake: Devastating area attack that deals " + str(earthquake_damage) + " damage and stuns all nearby enemies."
		_:
			return "Unknown ability"

# Override dash for barbarian (more aggressive)
func dash():
	if current_state == PlayerState.DEAD or not dash_ready:
		return
	
	# Barbarian dash is more like a charge
	var dash_direction = input_vector
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2(0, -1)
	
	# Enhanced dash for barbarian
	current_state = PlayerState.DASHING
	is_dashing = true
	dash_velocity = dash_direction * (dash_speed * 1.2)  # Faster dash
	dash_ready = false
	dash_timer.start()
	
	# Deal damage to enemies during dash
	var dash_damage = 20
	if is_in_rage:
		dash_damage += berserker_rage_damage_bonus
	
	# Check for enemies hit during dash
	for target in targets_in_range:
		if target.has_method("take_damage"):
			target.take_damage(dash_damage, player_id)
			print("Dash hit ", target.name, " for ", dash_damage, " damage!")
	
	# Become invincible during dash
	is_invincible = true
	
	# Visual effect
	create_charge_effect()
	
	print("Barbarian charged!")

func create_charge_effect():
	# Create dust cloud effect
	var dust = ColorRect.new()
	dust.size = Vector2(32, 32)
	dust.color = Color(0.8, 0.7, 0.5, 0.6)  # Dusty color
	dust.position = sprite.position - Vector2(16, 16)
	add_child(dust)
	
	# Animate dust
	var tween = create_tween()
	tween.tween_property(dust, "scale", Vector2(2.0, 2.0), 0.3)
	tween.tween_property(dust, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(dust.queue_free)

# Check if ability can be used
func can_use_ability(ability_index: int) -> bool:
	if not super.is_ability_ready(ability_index):
		return false
	
	# All barbarian abilities are always usable when not on cooldown
	return true

# Override process to handle rage effects
func _process(delta):
	# Update rage visual effects
	if is_in_rage:
		# Pulsing effect during rage
		var pulse_intensity = 0.1 + 0.05 * sin(Time.get_ticks_msec() * 0.01)
		sprite.modulate = Color(1.0 + pulse_intensity, 0.8, 0.8) 
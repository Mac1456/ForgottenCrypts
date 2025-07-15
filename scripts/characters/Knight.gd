extends Player
class_name Knight

# Knight-specific variables
var shield_bash_damage: int = 40
var shield_bash_stun_duration: float = 1.5
var protective_aura_radius: float = 80.0
var protective_aura_damage_reduction: float = 0.3
var divine_protection_duration: float = 6.0
var is_aura_active: bool = false
var aura_timer: Timer

# Defense bonuses
var shield_damage_reduction: float = 0.2
var ally_healing_rate: float = 5.0

func _ready():
	# Set character type
	character_type = ProgressionManager.CharacterType.KNIGHT
	
	# Create aura timer
	aura_timer = Timer.new()
	aura_timer.wait_time = 0.5  # Aura update interval
	aura_timer.timeout.connect(_on_aura_update)
	add_child(aura_timer)
	
	# Call parent ready
	super._ready()
	
	print("Knight initialized with character type: ", character_type)

# Override ability functions with knight-specific implementations
func use_ability_1():
	if current_state == PlayerState.DEAD or not ability1_ready:
		return
	
	print("Knight using Shield Bash!")
	
	# Set state
	current_state = PlayerState.ATTACKING
	ability1_ready = false
	ability1_timer.start()
	
	# Perform shield bash
	perform_shield_bash()
	
	# Network sync
	if is_local_player:
		ability_used.emit(player_id, "shield_bash")
	
	# Return to idle after attack delay
	await get_tree().create_timer(0.5).timeout
	if current_state == PlayerState.ATTACKING:
		current_state = PlayerState.IDLE

func use_ability_2():
	if current_state == PlayerState.DEAD or not ability2_ready:
		return
	
	print("Knight activating Protective Aura!")
	
	# Set state
	ability2_ready = false
	ability2_timer.start()
	
	# Toggle protective aura
	toggle_protective_aura()
	
	# Network sync
	if is_local_player:
		ability_used.emit(player_id, "protective_aura")

func use_ability_3():
	if current_state == PlayerState.DEAD or not ability3_ready:
		return
	
	# Check if third ability is unlocked
	var char_data = ProgressionManager.get_character_data(character_type)
	if not char_data.get("third_ability_unlocked", false):
		print("Divine Protection not unlocked yet!")
		return
	
	print("Knight casting Divine Protection!")
	
	# Set state
	ability3_ready = false
	ability3_timer.start()
	
	# Cast divine protection
	cast_divine_protection()
	
	# Network sync
	if is_local_player:
		ability_used.emit(player_id, "divine_protection")

func perform_shield_bash():
	# Find enemies in front of player
	var bash_range = 50.0
	var bash_angle = 90.0  # Degrees
	
	var enemies_hit = []
	var facing_direction = Vector2(0, -1)  # Default facing up
	
	# If moving, use movement direction
	if velocity.length() > 0:
		facing_direction = velocity.normalized()
	
	# Find enemies in cone in front of player
	for target in targets_in_range:
		if target.has_method("take_damage"):
			var distance = global_position.distance_to(target.global_position)
			if distance <= bash_range:
				var direction_to_target = (target.global_position - global_position).normalized()
				var angle = rad_to_deg(facing_direction.angle_to(direction_to_target))
				
				if abs(angle) <= bash_angle / 2.0:
					enemies_hit.append(target)
	
	# Deal damage and stun enemies
	for enemy in enemies_hit:
		enemy.take_damage(shield_bash_damage, player_id)
		
		# Apply stun effect
		if enemy.has_method("stun"):
			enemy.stun(shield_bash_stun_duration)
		
		# Knockback enemy
		var knockback_direction = (enemy.global_position - global_position).normalized()
		apply_knockback(enemy, knockback_direction, 100.0)
		
		print("Shield Bash hit ", enemy.name, " for ", shield_bash_damage, " damage and stun!")
	
	# Visual effect
	create_shield_bash_effect(facing_direction)
	
	# Play attack audio
	if attack_audio:
		attack_audio.play()

func toggle_protective_aura():
	is_aura_active = !is_aura_active
	
	if is_aura_active:
		print("Protective Aura activated!")
		aura_timer.start()
		create_protective_aura_effect()
	else:
		print("Protective Aura deactivated!")
		aura_timer.stop()
		remove_protective_aura_effect()

func cast_divine_protection():
	print("Divine Protection - Team-wide immunity!")
	
	# Find all allied players
	var players_node = get_tree().get_first_node_in_group("players")
	if players_node:
		for player in players_node.get_children():
			if player.has_method("apply_divine_protection"):
				player.apply_divine_protection(divine_protection_duration)
			elif player != self:
				# Fallback: make player invincible
				make_player_invincible(player, divine_protection_duration)
	
	# Apply to self
	apply_divine_protection(divine_protection_duration)
	
	# Visual effect
	create_divine_protection_effect()
	
	# Play cast audio
	if attack_audio:
		attack_audio.play()

func apply_divine_protection(duration: float):
	# Make player invincible
	is_invincible = true
	
	# Visual effect
	sprite.modulate = Color(1.5, 1.5, 0.5, 0.8)  # Golden glow
	
	# Create protection timer
	var protection_timer = Timer.new()
	protection_timer.wait_time = duration
	protection_timer.one_shot = true
	protection_timer.timeout.connect(func(): end_divine_protection())
	add_child(protection_timer)
	protection_timer.start()
	
	print("Divine Protection applied for ", duration, " seconds!")

func end_divine_protection():
	is_invincible = false
	sprite.modulate = Color.WHITE
	print("Divine Protection ended!")

func make_player_invincible(player, duration: float):
	# Helper function to make other players invincible
	if player.has_method("set_invincible"):
		player.set_invincible(true, duration)
	else:
		# Fallback implementation
		player.is_invincible = true
		var timer = Timer.new()
		timer.wait_time = duration
		timer.one_shot = true
		timer.timeout.connect(func(): player.is_invincible = false)
		player.add_child(timer)
		timer.start()

func _on_aura_update():
	if is_aura_active:
		# Find allies within aura range
		var allies_in_range = []
		var players_node = get_tree().get_first_node_in_group("players")
		
		if players_node:
			for player in players_node.get_children():
				if player != self and player.has_method("heal"):
					var distance = global_position.distance_to(player.global_position)
					if distance <= protective_aura_radius:
						allies_in_range.append(player)
		
		# Heal allies in range
		for ally in allies_in_range:
			ally.heal(int(ally_healing_rate * 0.5))  # Heal every 0.5 seconds
		
		# Continue aura updates
		aura_timer.start()

func apply_knockback(target, direction: Vector2, force: float):
	# Apply knockback to target
	if target.has_method("apply_knockback"):
		target.apply_knockback(direction, force)
	elif target.has_method("set_velocity"):
		target.set_velocity(direction * force)
	else:
		# Fallback: move target directly
		var tween = create_tween()
		tween.tween_property(target, "global_position", target.global_position + direction * 50, 0.3)

func create_shield_bash_effect(direction: Vector2):
	# Create shield impact effect
	var shield_effect = ColorRect.new()
	shield_effect.size = Vector2(40, 40)
	shield_effect.color = Color(0.8, 0.8, 1.0, 0.8)  # Light blue shield
	shield_effect.global_position = global_position + direction * 30 - Vector2(20, 20)
	
	get_parent().add_child(shield_effect)
	
	# Animate shield effect
	var tween = create_tween()
	tween.tween_property(shield_effect, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(shield_effect, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(shield_effect.queue_free)

func create_protective_aura_effect():
	# Create aura circle
	var aura_circle = ColorRect.new()
	aura_circle.size = Vector2(protective_aura_radius * 2, protective_aura_radius * 2)
	aura_circle.color = Color(0.2, 0.8, 1.0, 0.2)  # Light blue aura
	aura_circle.global_position = global_position - Vector2(protective_aura_radius, protective_aura_radius)
	aura_circle.name = "ProtectiveAura"
	
	add_child(aura_circle)
	
	# Pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(aura_circle, "scale", Vector2(1.1, 1.1), 1.0)
	tween.tween_property(aura_circle, "scale", Vector2(1.0, 1.0), 1.0)

func remove_protective_aura_effect():
	# Remove aura circle
	var aura = get_node_or_null("ProtectiveAura")
	if aura:
		aura.queue_free()

func create_divine_protection_effect():
	# Create divine light effect
	var divine_light = ColorRect.new()
	divine_light.size = Vector2(100, 100)
	divine_light.color = Color(1.0, 1.0, 0.5, 0.6)  # Golden light
	divine_light.global_position = global_position - Vector2(50, 50)
	
	get_parent().add_child(divine_light)
	
	# Animate divine light
	var tween = create_tween()
	tween.tween_property(divine_light, "scale", Vector2(0.1, 0.1), 0.0)
	tween.tween_property(divine_light, "scale", Vector2(3.0, 3.0), 0.5)
	tween.tween_property(divine_light, "modulate", Color.TRANSPARENT, 0.5)
	tween.tween_callback(divine_light.queue_free)

# Override damage taking to apply shield reduction
func take_damage(damage: int, attacker_id: int = -1):
	# Apply shield damage reduction
	var reduced_damage = int(damage * (1.0 - shield_damage_reduction))
	
	# Apply aura damage reduction if active
	if is_aura_active:
		reduced_damage = int(reduced_damage * (1.0 - protective_aura_damage_reduction))
	
	print("Knight shield reduced damage from ", damage, " to ", reduced_damage)
	
	# Call parent with reduced damage
	super.take_damage(reduced_damage, attacker_id)

# Override character-specific stats loading
func load_character_stats():
	super.load_character_stats()
	
	# Apply knight-specific upgrades
	var char_data = ProgressionManager.get_character_data(character_type)
	var upgrades = char_data.get("upgrades", {})
	
	# Apply shield mastery upgrade
	if "shield_mastery" in upgrades:
		var shield_level = upgrades["shield_mastery"]
		shield_bash_damage = 40 + (shield_level * 15)
		shield_bash_stun_duration = 1.5 + (shield_level * 0.5)
	
	# Apply armor training upgrade
	if "armor_training" in upgrades:
		var armor_level = upgrades["armor_training"]
		shield_damage_reduction = 0.2 + (armor_level * 0.05)
	
	# Apply healing aura upgrade
	if "healing_aura" in upgrades:
		var healing_level = upgrades["healing_aura"]
		ally_healing_rate = 5.0 + (healing_level * 3.0)
	
	print("Knight stats loaded - Shield Bash: ", shield_bash_damage, " Shield Reduction: ", shield_damage_reduction * 100, "%")

# Get ability descriptions for UI
func get_ability_description(ability_index: int) -> String:
	match ability_index:
		1:
			return "Shield Bash: Cone attack that deals " + str(shield_bash_damage) + " damage and stuns enemies for " + str(shield_bash_stun_duration) + "s."
		2:
			return "Protective Aura: Toggle aura that reduces damage by " + str(protective_aura_damage_reduction * 100) + "% and heals allies."
		3:
			return "Divine Protection: Grant all allies invincibility for " + str(divine_protection_duration) + " seconds."
		_:
			return "Unknown ability"

# Override dash for knight (defensive dash)
func dash():
	if current_state == PlayerState.DEAD or not dash_ready:
		return
	
	var dash_direction = input_vector
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2(0, -1)
	
	# Knight dash is more defensive
	current_state = PlayerState.DASHING
	is_dashing = true
	dash_velocity = dash_direction * dash_speed
	dash_ready = false
	dash_timer.start()
	
	# Extended invincibility during dash
	is_invincible = true
	var extended_invincibility = Timer.new()
	extended_invincibility.wait_time = dash_duration + 0.2  # Extra invincibility
	extended_invincibility.one_shot = true
	extended_invincibility.timeout.connect(func(): is_invincible = false)
	add_child(extended_invincibility)
	extended_invincibility.start()
	
	# Heal slightly during dash
	heal(5)
	
	# Visual effect
	create_defensive_dash_effect()
	
	print("Knight performed defensive dash!")

func create_defensive_dash_effect():
	# Create shield barrier effect
	var shield_barrier = ColorRect.new()
	shield_barrier.size = Vector2(48, 48)
	shield_barrier.color = Color(0.8, 0.8, 1.0, 0.6)  # Blue shield
	shield_barrier.global_position = global_position - Vector2(24, 24)
	
	get_parent().add_child(shield_barrier)
	
	# Animate barrier
	var tween = create_tween()
	tween.tween_property(shield_barrier, "scale", Vector2(1.2, 1.2), 0.3)
	tween.tween_property(shield_barrier, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(shield_barrier.queue_free)

# Check if ability can be used
func can_use_ability(ability_index: int) -> bool:
	if not super.is_ability_ready(ability_index):
		return false
	
	# All knight abilities are always usable when not on cooldown
	return true

# Network sync for knight-specific abilities
@rpc("any_peer", "call_local", "reliable")
func sync_knight_ability(ability_name: String):
	if not is_local_player:
		match ability_name:
			"shield_bash":
				perform_shield_bash()
			"protective_aura":
				toggle_protective_aura()
			"divine_protection":
				cast_divine_protection()

# Override process to handle aura positioning
func _process(delta):
	# Update aura position
	if is_aura_active:
		var aura = get_node_or_null("ProtectiveAura")
		if aura:
			aura.global_position = global_position - Vector2(protective_aura_radius, protective_aura_radius)

# Helper function for other players to set invincibility
func set_invincible(invincible: bool, duration: float = 0.0):
	is_invincible = invincible
	
	if invincible and duration > 0:
		var timer = Timer.new()
		timer.wait_time = duration
		timer.one_shot = true
		timer.timeout.connect(func(): is_invincible = false)
		add_child(timer)
		timer.start()

# Check if player is protecting allies
func is_protecting_allies() -> bool:
	return is_aura_active

# Get number of allies in protective range
func get_allies_in_protection() -> int:
	var count = 0
	var players_node = get_tree().get_first_node_in_group("players")
	
	if players_node:
		for player in players_node.get_children():
			if player != self:
				var distance = global_position.distance_to(player.global_position)
				if distance <= protective_aura_radius:
					count += 1
	
	return count 